# Ren'Py Universal Web State Inspector (Multi-Source Edition: Store & Persistent)
# Rename this file as `z_web_state_manager.rpy` and put it in the /game folder.
# Access at http://localhost:9999

init 999 python:
    import http.server
    import socketserver
    import json
    import threading
    import urllib.parse
    import math
    import types

    config.developer = True
    WEB_INSPECTOR_PORT = 9999

    IGNORED_STORE_KEYS = {
        "config", "renpy", "style", "build", "persistent", "_history_list",
        "_rollback_log", "_side_images", "_layer_at_list", "anim", "im",
        "division", "absolute_import", "with_statement", "print_function",
        "unicode_literals", "PY2", "basestring", "ui", "sys", "os", "pygame",
        "zipfile", "io", "json", "shutil", "math", "re", "time", "random",
        "threading", "socketserver", "http", "urllib", "types", "inspect"
    }

    def sanitize_string(s):
        if not isinstance(s, str):
            s = str(s)
        if len(s) > 300:
            s = s[:300] + "... [truncated]"
        return "".join(ch if ord(ch) >= 32 or ch in "\n\r\t" else "?" for ch in s)

    def is_python_module_or_builtin(v):
        if isinstance(v, (types.ModuleType, types.FunctionType, types.BuiltinFunctionType, types.MethodType)):
            return True
        if hasattr(v, "__file__") or hasattr(v, "__loader__") or hasattr(v, "__package__"):
            return True
        return False

    def get_object_members(val):
        if isinstance(val, dict) or "Dict" in type(val).__name__:
            try:
                return list(val.items())
            except Exception:
                pass

        type_name = type(val).__name__
        if type_name == "dict_items":
            try:
                return list(val)
            except Exception:
                pass

        if hasattr(val, "__dict__"):
            try:
                pairs = []
                for k, v in list(vars(val).items()):
                    if not k.startswith("_") and not callable(v):
                        pairs.append((k, v))
                if pairs:
                    return pairs
            except Exception:
                pass

        if hasattr(val, "items"):
            try:
                items_val = getattr(val, "items")
                if callable(items_val):
                    try:
                        items_val = items_val()
                    except Exception:
                        items_val = None
                if items_val is not None:
                    return [("items", items_val)]
            except Exception:
                pass

        return None

    def safe_serialize(val, depth=0, max_depth=5, seen=None):
        if seen is None:
            seen = set()

        if depth > max_depth:
            return "<Nested Object>"

        if val is None or isinstance(val, bool):
            return val

        if isinstance(val, (int, float)):
            if math.isnan(val) or math.isinf(val):
                return str(val)
            return val

        if isinstance(val, str):
            return sanitize_string(val)

        if is_python_module_or_builtin(val):
            return f"<{type(val).__name__}>"

        val_id = id(val)
        if val_id in seen:
            return "<Circular Ref>"
        seen.add(val_id)

        val_type = type(val)
        type_name = val_type.__name__

        module_name = getattr(val_type, "__module__", "")
        if module_name.startswith(("pygame", "sys", "threading", "ctypes", "renpy")) and not ("Revertable" in type_name):
            return f"<{type_name}>"

        pairs = get_object_members(val)
        if pairs is not None:
            res = {}
            for k, v in pairs:
                k_str = sanitize_string(k)
                if not k_str.startswith("_") and not is_python_module_or_builtin(v):
                    res[k_str] = safe_serialize(v, depth + 1, max_depth, seen.copy())
            return res

        is_sequence = (
            isinstance(val, (list, tuple, set)) or
            hasattr(val, "__iter__") or
            (hasattr(val, "__getitem__") and hasattr(val, "__len__"))
        )

        if is_sequence:
            try:
                res_list = []
                for v in list(val):
                    if not is_python_module_or_builtin(v):
                        res_list.append(safe_serialize(v, depth + 1, max_depth, seen.copy()))
                return res_list
            except Exception:
                pass

        return f"<{type_name}>"

    def get_clean_data(source="store"):
        data = {}
        try:
            target_obj = persistent if source == "persistent" else store

            if source == "persistent":
                raw_items = vars(persistent).items() if hasattr(persistent, "__dict__") else []
            else:
                raw_items = store.__dict__.items()

            for k, v in list(raw_items):
                if k.startswith("_") or k in IGNORED_STORE_KEYS or is_python_module_or_builtin(v) or isinstance(v, (type, config.__class__)):
                    continue

                mod = getattr(type(v), "__module__", "")
                if mod.startswith(("pygame", "sys", "renpy")) and not ("Revertable" in type(v).__name__):
                    continue

                data[sanitize_string(k)] = safe_serialize(v)
        except Exception as e:
            data["_error"] = sanitize_string(str(e))
        return data

    def apply_mutation(payload):
        try:
            source = payload.get("source", "store")
            path_list = payload.get("path", [])
            raw_val = payload.get("val")

            if not path_list:
                return

            target = persistent if source == "persistent" else store

            for step in path_list[:-1]:
                if isinstance(target, dict) and step in target:
                    target = target[step]
                elif hasattr(target, step):
                    target = getattr(target, step)
                elif isinstance(target, list) and str(step).isdigit():
                    target = target[int(step)]
                else:
                    return

            last_key = path_list[-1]
            if isinstance(target, dict):
                curr_val = target.get(last_key)
            elif hasattr(target, last_key):
                curr_val = getattr(target, last_key)
            elif isinstance(target, list) and str(last_key).isdigit():
                last_key = int(last_key)
                curr_val = target[last_key]
            else:
                curr_val = None

            if isinstance(curr_val, bool):
                parsed_val = (str(raw_val).lower() in ("true", "1"))
            elif isinstance(curr_val, int):
                parsed_val = int(raw_val)
            elif isinstance(curr_val, float):
                parsed_val = float(raw_val)
            else:
                parsed_val = str(raw_val)

            if isinstance(target, dict):
                target[last_key] = parsed_val
            elif hasattr(target, str(last_key)):
                setattr(target, str(last_key), parsed_val)
            elif isinstance(target, list) and isinstance(last_key, int):
                target[last_key] = parsed_val

            if source == "persistent":
                renpy.save_persistent()
        except Exception:
            pass

    class StateInspectorHandler(http.server.BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            return

        def do_GET(self):
            parsed = urllib.parse.urlparse(self.path)
            if parsed.path == "/api/vars":
                query_params = urllib.parse.parse_qs(parsed.query)
                source = query_params.get("source", ["store"])[0]

                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                data = json.dumps(get_clean_data(source), allow_nan=False, ensure_ascii=False)
                self.wfile.write(data.encode("utf-8"))

            elif parsed.path == "/":
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write(HTML_INTERFACE.encode("utf-8"))
            else:
                self.send_response(404)
                self.end_headers()

        def do_POST(self):
            if self.path == "/api/set":
                length = int(self.headers.get("content-length", 0))
                body = self.rfile.read(length)
                try:
                    payload = json.loads(body)
                    apply_mutation(payload)
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json; charset=utf-8")
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.end_headers()
                    self.wfile.write(json.dumps({"status": "ok"}).encode("utf-8"))
                except Exception as e:
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(str(e).encode("utf-8"))

    class ReusableTCPServer(socketserver.TCPServer):
        allow_reuse_address = True

    def start_web_inspector():
        try:
            httpd = ReusableTCPServer(("127.0.0.1", WEB_INSPECTOR_PORT), StateInspectorHandler)
            httpd.serve_forever()
        except Exception:
            pass

    if not hasattr(store, "_web_inspector_running"):
        store._web_inspector_running = True
        server_thread = threading.Thread(target=start_web_inspector, daemon=True)
        server_thread.start()

    HTML_INTERFACE = r"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Ren'Py State Manager</title>
    <style>
        body {
            background: #1e1e2e; color: #cdd6f4; font-family: monospace;
            margin: 0; padding: 20px; box-sizing: border-box;
        }
        .panel {
            background: #1e1e2e; color: #cdd6f4; border: 1px solid #89b4fa;
            border-radius: 8px; padding: 15px; max-width: 850px; margin: 0 auto;
            box-shadow: 0 10px 30px rgba(0,0,0,0.6);
        }
        .header-sticky {
            position: sticky; top: 0; background: #1e1e2e; z-index: 10;
            border-bottom: 1px solid #45475a; padding-bottom: 10px; margin-bottom: 10px;
        }
        .header { display: flex; justify-content: space-between; align-items: center; font-weight: bold; font-size: 14px; margin-bottom: 8px; }
        .header-controls { display: flex; gap: 5px; }
        .search-bar { display: flex; gap: 5px; width: 100%; margin-bottom: 6px; }
        .search-input {
            flex-grow: 1; background: #313244; color: #cdd6f4;
            border: 1px solid #45475a; border-radius: 4px; padding: 6px 8px; font-family: monospace;
        }
        .search-input:focus { outline: 1px solid #89b4fa; }
        .filter-settings {
            display: flex; gap: 10px; align-items: center; font-size: 12px; color: #f9e2af; margin-top: 4px; flex-wrap: wrap;
        }
        .filter-input, .select-input {
            background: #313244; color: #f38ba8; border: 1px solid #45475a;
            border-radius: 4px; padding: 4px 6px; font-family: monospace;
        }
        .select-input { color: #89b4fa; font-weight: bold; cursor: pointer; }
        .checkbox-label { display: flex; align-items: center; gap: 4px; cursor: pointer; user-select: none; }
        .focus-banner {
            background: #313244; border: 1px solid #a6e3a1; border-radius: 4px;
            padding: 6px 10px; display: flex; justify-content: space-between;
            align-items: center; font-size: 12px; color: #a6e3a1; margin-bottom: 8px;
        }
        .btn {
            background: #89b4fa; color: #11111b; border: none; padding: 6px 12px;
            border-radius: 4px; cursor: pointer; font-weight: bold; font-family: monospace;
        }
        .btn:hover { background: #b4befe; }
        .btn-clear { background: #f38ba8; color: #11111b; font-weight: bold; padding: 6px 10px; }
        .btn-clear:hover { background: #fca311; }
        .btn-small { padding: 4px 8px; font-size: 11px; background: #cba6f7; }
        .btn-small:hover { background: #b4befe; }
        .btn-focus {
            background: #45475a; color: #a6e3a1; border: 1px solid #a6e3a1;
            padding: 2px 6px; border-radius: 3px; cursor: pointer; font-size: 10px;
            font-family: monospace; margin-left: 6px;
        }
        .btn-focus:hover { background: #a6e3a1; color: #11111b; }
        .btn-more {
            background: #313244; color: #f9e2af; border: 1px dashed #f9e2af;
            padding: 4px 10px; border-radius: 4px; cursor: pointer; font-size: 11px;
            font-family: monospace; margin: 6px 0; width: 100%; text-align: left;
        }
        .btn-more:hover { background: #45475a; color: #a6e3a1; border-color: #a6e3a1; }
        .var-row { display: flex; flex-direction: column; margin-bottom: 6px; padding-bottom: 4px; }
        .var-header-container { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
        .var-name { color: #f38ba8; font-weight: bold; }
        .collapsible { cursor: pointer; user-select: none; color: #cba6f7; }
        .collapsible:hover { color: #a6e3a1; }
        .collapsible::before { content: "▼ "; font-size: 10px; }
        .collapsible.collapsed::before { content: "► "; }
        .child-container { margin-left: 14px; border-left: 1px dashed #45475a; padding-left: 10px; }
        .input-group { display: flex; gap: 6px; align-items: center; width: 100%; }
        .var-input {
            background: #313244; color: #cdd6f4; border: 1px solid #45475a;
            padding: 4px 8px; border-radius: 4px; flex-grow: 1; font-family: monospace;
            box-sizing: border-box; height: 26px;
        }
        .var-input:focus { outline: 1px solid #89b4fa; }
        .btn-group { display: flex; gap: 2px; flex-shrink: 0; }
        .quick-btn {
            background: #45475a; color: #cdd6f4; border: none; padding: 4px 6px;
            border-radius: 3px; cursor: pointer; font-size: 10px; font-family: monospace; height: 26px;
        }
        .quick-btn:hover { background: #585b70; color: #f9e2af; }
        .error-banner { background: #f38ba8; color: #11111b; padding: 8px; border-radius: 4px; font-weight: bold; margin-bottom: 10px; display: none; }
    </style>
</head>
<body>
    <div class="panel">
        <div id="errorBanner" class="error-banner"></div>
        <div class="header-sticky">
            <div class="header">
                <span>Ren'Py State Manager</span>
                <div class="header-controls">
                    <button class="btn btn-small" id="expandBtn">Expand All</button>
                    <button class="btn btn-small" id="collapseBtn">Collapse All</button>
                    <button class="btn" id="refreshBtn">Sync State</button>
                </div>
            </div>
            <div class="search-bar">
                <input type="text" class="search-input" id="searchInput" placeholder="Filter by search query...">
                <button class="btn btn-clear" id="clearBtn" title="Clear Filter">✕</button>
            </div>
            <div class="filter-settings">
                <span>Source:</span>
                <select id="sourceSelect" class="select-input">
                    <option value="store">Store (Game State)</option>
                    <option value="persistent">Persistent Data</option>
                </select>
                <span>Ignore:</span>
                <input type="text" class="filter-input" id="ignoreKeysInput" placeholder="icon, sprite" style="width: 100px;">
                <span>Page Limit:</span>
                <input type="number" class="filter-input" id="pageLimitInput" value="50" style="width: 45px;">
                <label class="checkbox-label">
                    <input type="checkbox" id="hideEmptyCheckbox" checked> Hide Empty
                </label>
                <label class="checkbox-label" title="Enable auto-polling every 5s">
                    <input type="checkbox" id="autoSyncCheckbox"> Auto Sync
                </label>
            </div>
        </div>

        <div id="focusBanner" class="focus-banner" style="display: none;">
            <span>Focused Root: <b id="focusPathText"></b></span>
            <button class="btn btn-small" id="clearFocusBtn">Clear Focus</button>
        </div>

        <div id="varContainer"></div>
    </div>

    <script>
        let rawState = {};
        let currentSearchTerm = '';
        let selectedSource = 'store';
        let ignoreKeys = [];
        let hideEmpty = true;
        let autoSync = false;
        let pageLimit = 50;
        let focusPath = [];
        const expandedPaths = new Set();
        const loadedCounts = new Map();
        let pollTimer = null;

        const savedSource = localStorage.getItem('renpy_source');
        if (savedSource !== null) {
            selectedSource = savedSource;
            document.getElementById('sourceSelect').value = selectedSource;
        }
        const savedIgnore = localStorage.getItem('renpy_ignore_keys');
        if (savedIgnore !== null) {
            document.getElementById('ignoreKeysInput').value = savedIgnore;
            ignoreKeys = savedIgnore.split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
        }
        const savedHideEmpty = localStorage.getItem('renpy_hide_empty');
        if (savedHideEmpty !== null) {
            hideEmpty = savedHideEmpty === 'true';
            document.getElementById('hideEmptyCheckbox').checked = hideEmpty;
        }
        const savedPageLimit = localStorage.getItem('renpy_page_limit');
        if (savedPageLimit !== null) {
            pageLimit = parseInt(savedPageLimit, 10) || 50;
            document.getElementById('pageLimitInput').value = pageLimit;
        }

        function showError(msg) {
            const el = document.getElementById('errorBanner');
            el.textContent = msg;
            el.style.display = 'block';
        }

        function clearError() {
            document.getElementById('errorBanner').style.display = 'none';
        }

        function debounce(func, wait) {
            let timeout;
            return function(...args) {
                clearTimeout(timeout);
                timeout = setTimeout(() => func.apply(this, args), wait);
            };
        }

        async function fetchState() {
            try {
                const res = await fetch(`/api/vars?source=${selectedSource}`);
                if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
                rawState = await res.json();
                clearError();
                renderVars();
            } catch (e) {
                showError("Error fetching or parsing state: " + e.message);
            }
        }

        async function updateValue(pathArray, newVal) {
            await fetch('/api/set', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ source: selectedSource, path: pathArray, val: newVal })
            });
            fetchState();
        }

        function isIgnoredKey(key) {
            if (!ignoreKeys.length) return false;
            const lowerKey = String(key).toLowerCase();
            return ignoreKeys.some(k => lowerKey.includes(k));
        }

        function hasMatch(key, value, term) {
            if (!term) return true;
            if (String(key).toLowerCase().includes(term)) return true;
            if (value === null || value === undefined) return String(value).toLowerCase().includes(term);

            if (typeof value === 'object') {
                for (const [cKey, cVal] of Object.entries(value)) {
                    if (isIgnoredKey(cKey)) continue;
                    if (hasMatch(cKey, cVal, term)) return true;
                }
                return false;
            }
            return String(value).toLowerCase().includes(term);
        }

        function toggleAll(expand) {
            if (expand) {
                const markExpanded = (obj, pathArray, currentDepth) => {
                    if (typeof obj !== 'object' || obj === null || currentDepth > 2) return;
                    expandedPaths.add(pathArray.join(' > '));
                    for (const [k, v] of Object.entries(obj)) {
                        if (!isIgnoredKey(k)) markExpanded(v, [...pathArray, k], currentDepth + 1);
                    }
                };

                let rootObj = rawState;
                if (focusPath.length) {
                    for (const step of focusPath) {
                        if (rootObj && typeof rootObj === 'object' && step in rootObj) rootObj = rootObj[step];
                    }
                }
                for (const [k, v] of Object.entries(rootObj)) {
                    markExpanded(v, [...focusPath, k], 1);
                }
            } else {
                expandedPaths.clear();
            }
            renderVars();
        }

        function renderVars() {
            try {
                const container = document.getElementById('varContainer');
                container.innerHTML = '';

                let rootObj = rawState;
                if (focusPath.length) {
                    for (const step of focusPath) {
                        if (rootObj && typeof rootObj === 'object' && step in rootObj) {
                            rootObj = rootObj[step];
                        } else {
                            focusPath = [];
                            rootObj = rawState;
                            break;
                        }
                    }
                }

                const banner = document.getElementById('focusBanner');
                if (focusPath.length) {
                    banner.style.display = 'flex';
                    document.getElementById('focusPathText').textContent = focusPath.join(' > ');
                } else {
                    banner.style.display = 'none';
                }

                for (const [key, value] of Object.entries(rootObj)) {
                    renderField(container, key, value, [...focusPath, key], currentSearchTerm);
                }
            } catch (e) {
                showError("Render Error: " + e.message);
            }
        }

        function renderField(container, key, value, pathArray, term) {
            if (isIgnoredKey(key)) return;

            const activeTerm = focusPath.length ? '' : term;
            if (activeTerm && !hasMatch(key, value, activeTerm)) return;

            const pathString = pathArray.join(' > ');

            if (typeof value === 'object' && value !== null) {
                const entries = Object.entries(value).filter(([k]) => !isIgnoredKey(k));
                if (hideEmpty && entries.length === 0) return;

                const row = document.createElement('div');
                row.className = 'var-row';

                const headerRow = document.createElement('div');
                headerRow.className = 'var-header-container';

                const isArray = Array.isArray(value);
                const isExpanded = activeTerm ? true : expandedPaths.has(pathString);

                const label = document.createElement('span');
                label.className = `var-name collapsible ${isExpanded ? '' : 'collapsed'}`;
                label.textContent = (isNaN(key) ? key : `[${key}]`) + (isArray ? ` [List:${entries.length}]` : ' {Object}');

                const focusBtn = document.createElement('button');
                focusBtn.className = 'btn-focus';
                focusBtn.textContent = 'Focus ➔';
                focusBtn.title = 'Isolate and view this object fully without filters';
                focusBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    focusPath = [...pathArray];
                    currentSearchTerm = '';
                    document.getElementById('searchInput').value = '';
                    renderVars();
                });

                headerRow.appendChild(label);
                headerRow.appendChild(focusBtn);
                row.appendChild(headerRow);

                const childContainer = document.createElement('div');
                childContainer.className = 'child-container';
                childContainer.style.display = isExpanded ? 'block' : 'none';

                let childrenRendered = false;
                const renderChildren = () => {
                    if (childrenRendered) return;
                    childrenRendered = true;
                    childContainer.innerHTML = '';

                    const keyMatchedDirectly = activeTerm && String(key).toLowerCase().includes(activeTerm);
                    const childTerm = keyMatchedDirectly ? '' : activeTerm;

                    const limit = pageLimit > 0 ? (loadedCounts.get(pathString) || pageLimit) : entries.length;
                    const visibleEntries = entries.slice(0, limit);

                    for (const [childKey, childValue] of visibleEntries) {
                        renderField(childContainer, childKey, childValue, [...pathArray, childKey], childTerm);
                    }

                    if (limit < entries.length) {
                        const moreBtn = document.createElement('button');
                        moreBtn.className = 'btn-more';
                        moreBtn.textContent = `... Load Next ${Math.min(pageLimit, entries.length - limit)} Items (${entries.length - limit} remaining)`;
                        moreBtn.addEventListener('click', (e) => {
                            e.stopPropagation();
                            loadedCounts.set(pathString, limit + pageLimit);
                            childrenRendered = false;
                            renderChildren();
                        });
                        childContainer.appendChild(moreBtn);
                    }
                };

                if (isExpanded) renderChildren();

                label.addEventListener('click', () => {
                    renderChildren();
                    const willExpand = childContainer.style.display === 'none';
                    childContainer.style.display = willExpand ? 'block' : 'none';
                    label.classList.toggle('collapsed', !willExpand);

                    if (willExpand) {
                        expandedPaths.add(pathString);
                    } else {
                        expandedPaths.delete(pathString);
                    }
                });

                row.appendChild(childContainer);
                container.appendChild(row);
            } else {
                const row = document.createElement('div');
                row.className = 'var-row';

                const headerRow = document.createElement('div');
                headerRow.className = 'var-header-container';

                const label = document.createElement('span');
                label.className = 'var-name';
                label.textContent = isNaN(key) ? key : `[${key}]`;

                headerRow.appendChild(label);
                row.appendChild(headerRow);

                const inputGroup = document.createElement('div');
                inputGroup.className = 'input-group';

                const input = document.createElement('input');
                input.className = 'var-input';
                input.type = 'text';
                input.value = (value !== undefined && value !== null) ? value : String(value);

                const originalType = typeof value;

                const commitChange = (newVal) => {
                    updateValue(pathArray, newVal);
                    input.style.borderColor = '#a6e3a1';
                };

                input.addEventListener('change', (e) => commitChange(e.target.value));
                inputGroup.appendChild(input);

                const btnGroup = document.createElement('div');
                btnGroup.className = 'btn-group';

                const createQuickBtn = (text, targetVal) => {
                    const qBtn = document.createElement('button');
                    qBtn.className = 'quick-btn';
                    qBtn.textContent = text;
                    qBtn.addEventListener('click', () => commitChange(targetVal));
                    return qBtn;
                };

                if (originalType === 'boolean') {
                    btnGroup.appendChild(createQuickBtn('True', true));
                    btnGroup.appendChild(createQuickBtn('False', false));
                } else if (originalType === 'number') {
                    btnGroup.appendChild(createQuickBtn('0', 0));
                    btnGroup.appendChild(createQuickBtn('1k', 1000));
                    btnGroup.appendChild(createQuickBtn('1m', 1000000));
                }

                if (originalType !== 'string' || btnGroup.hasChildNodes()) {
                    inputGroup.appendChild(btnGroup);
                }

                row.appendChild(inputGroup);
                container.appendChild(row);
            }
        }

        const triggerSearch = debounce((term) => {
            currentSearchTerm = term;
            renderVars();
        }, 250);

        document.getElementById('searchInput').addEventListener('input', (e) => {
            const safeText = e.target.value ? e.target.value.trim().toLowerCase() : '';
            triggerSearch(safeText);
        });

        document.getElementById('sourceSelect').addEventListener('change', (e) => {
            selectedSource = e.target.value;
            localStorage.setItem('renpy_source', selectedSource);
            focusPath = [];
            expandedPaths.clear();
            fetchState();
        });

        document.getElementById('clearBtn').addEventListener('click', () => {
            document.getElementById('searchInput').value = '';
            currentSearchTerm = '';
            renderVars();
            document.getElementById('searchInput').focus();
        });

        document.getElementById('ignoreKeysInput').addEventListener('input', (e) => {
            const val = e.target.value;
            localStorage.setItem('renpy_ignore_keys', val);
            ignoreKeys = val.split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
            renderVars();
        });

        document.getElementById('pageLimitInput').addEventListener('change', (e) => {
            const val = parseInt(e.target.value, 10) || 0;
            pageLimit = val;
            localStorage.setItem('renpy_page_limit', val);
            renderVars();
        });

        document.getElementById('hideEmptyCheckbox').addEventListener('change', (e) => {
            hideEmpty = e.target.checked;
            localStorage.setItem('renpy_hide_empty', hideEmpty);
            renderVars();
        });

        document.getElementById('autoSyncCheckbox').addEventListener('change', (e) => {
            autoSync = e.target.checked;
            if (pollTimer) clearInterval(pollTimer);
            if (autoSync) {
                pollTimer = setInterval(fetchState, 5000);
            }
        });

        document.getElementById('clearFocusBtn').addEventListener('click', () => {
            focusPath = [];
            renderVars();
        });

        document.getElementById('refreshBtn').addEventListener('click', fetchState);
        document.getElementById('expandBtn').addEventListener('click', () => toggleAll(true));
        document.getElementById('collapseBtn').addEventListener('click', () => toggleAll(false));

        fetchState();
    </script>
</body>
</html>
"""