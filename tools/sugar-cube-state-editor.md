// ==UserScript==
// @name         SugarCube State Manager (Ultimate - Multi-Source & Focus)
// @namespace    http://tampermonkey.net/
// @version      8.0
// @description  SugarCube manager with Custom Object Path, Ignore Rules, and Focused Object Views.
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const initInterval = setInterval(() => {
        if (window.SugarCube && window.SugarCube.State) {
            clearInterval(initInterval);
            initUI();
        } else if (window.State && window.State.variables) {
            window.SugarCube = { State: window.State, Engine: window.Engine };
            clearInterval(initInterval);
            initUI();
        }
    }, 1000);

    function debounce(func, wait) {
        let timeout;
        return function(...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        };
    }

    function initUI() {
        const host = document.createElement('div');
        host.id = 'sc-manager-host';
        host.style.cssText = 'position: fixed; top: 15px; right: 15px; z-index: 2147483647;';
        document.body.appendChild(host);

        const shadow = host.attachShadow({ mode: 'open' });

        const style = document.createElement('style');
        style.textContent = `
            .wrapper { display: flex; flex-direction: column; align-items: flex-end; gap: 10px; }
            .panel {
                background: #1e1e2e; color: #cdd6f4; font-family: monospace;
                border: 1px solid #89b4fa; border-radius: 8px; padding: 15px;
                width: 480px; height: 620px; max-height: 85vh; overflow: auto;
                resize: both; box-shadow: 0 10px 30px rgba(0,0,0,0.6);
                display: none; min-width: 320px; min-height: 200px;
                direction: rtl; /* Resize handle bottom-left */
            }
            .panel-inner { direction: ltr; }
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
            .filter-input {
                background: #313244; color: #f38ba8; border: 1px solid #45475a;
                border-radius: 4px; padding: 4px 6px; font-family: monospace;
            }
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
        `;
        shadow.appendChild(style);

        const wrapper = document.createElement('div');
        wrapper.className = 'wrapper';

        const toggleBtn = document.createElement('button');
        toggleBtn.className = 'btn';
        toggleBtn.textContent = '{ } SugarCube Editor';
        wrapper.appendChild(toggleBtn);

        const panel = document.createElement('div');
        panel.className = 'panel';

        const panelInner = document.createElement('div');
        panelInner.className = 'panel-inner';

        // Sticky Header
        const headerSticky = document.createElement('div');
        headerSticky.className = 'header-sticky';

        const header = document.createElement('div');
        header.className = 'header';
        const title = document.createElement('span');
        title.textContent = 'Variables Tree';

        const headerControls = document.createElement('div');
        headerControls.className = 'header-controls';

        const expandBtn = document.createElement('button');
        expandBtn.className = 'btn btn-small'; expandBtn.textContent = 'Expand All';
        const collapseBtn = document.createElement('button');
        collapseBtn.className = 'btn btn-small'; collapseBtn.textContent = 'Collapse All';
        const refreshBtn = document.createElement('button');
        refreshBtn.className = 'btn'; refreshBtn.textContent = 'Sync UI';

        headerControls.appendChild(expandBtn);
        headerControls.appendChild(collapseBtn);
        headerControls.appendChild(refreshBtn);
        header.appendChild(title);
        header.appendChild(headerControls);
        headerSticky.appendChild(header);

        // Filter Bar
        const searchBar = document.createElement('div');
        searchBar.className = 'search-bar';

        const searchInput = document.createElement('input');
        searchInput.className = 'search-input';
        searchInput.type = 'text';
        searchInput.placeholder = 'Filter by any deep key or value...';

        const clearBtn = document.createElement('button');
        clearBtn.className = 'btn btn-clear';
        clearBtn.textContent = '✕';
        clearBtn.title = 'Clear Filter';

        searchBar.appendChild(searchInput);
        searchBar.appendChild(clearBtn);
        headerSticky.appendChild(searchBar);

        // Feature 1 & 2: Custom Source Path & Ignore Rules Header Controls
        const filterSettings = document.createElement('div');
        filterSettings.className = 'filter-settings';

        filterSettings.innerHTML = `
            <span>Source Path:</span>
            <input type="text" class="filter-input" id="sourcePathInput" value="SugarCube.State.variables" style="width: 170px;" placeholder="window path">
            <span>Ignore:</span>
            <input type="text" class="filter-input" id="ignoreKeysInput" placeholder="icon, sprite" style="width: 100px;">
        `;
        headerSticky.appendChild(filterSettings);

        // Feature 3: Targeted Focus Banner
        const focusBanner = document.createElement('div');
        focusBanner.className = 'focus-banner';
        focusBanner.style.display = 'none';
        focusBanner.innerHTML = `
            <span>Focused Root: <b id="focusPathText"></b></span>
            <button class="btn btn-small" id="clearFocusBtn">Clear Focus</button>
        `;

        const varContainer = document.createElement('div');

        panelInner.appendChild(headerSticky);
        panelInner.appendChild(focusBanner);
        panelInner.appendChild(varContainer);
        panel.appendChild(panelInner);
        wrapper.appendChild(panel);
        shadow.appendChild(wrapper);

        // --- State Variables ---
        let currentSearchTerm = '';
        let sourcePath = localStorage.getItem('sc_source_path') || 'SugarCube.State.variables';
        let ignoreKeys = [];
        let focusPath = [];

        const sourcePathInput = shadow.querySelector('#sourcePathInput');
        const ignoreKeysInput = shadow.querySelector('#ignoreKeysInput');
        const focusPathText = shadow.querySelector('#focusPathText');
        const clearFocusBtn = shadow.querySelector('#clearFocusBtn');

        sourcePathInput.value = sourcePath;

        const savedIgnore = localStorage.getItem('sc_ignore_keys');
        if (savedIgnore !== null) {
            ignoreKeysInput.value = savedIgnore;
            ignoreKeys = savedIgnore.split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
        }

        // --- Helpers ---
        function resolveObjectPath(pathStr) {
            try {
                const steps = pathStr.replace(/^window\./, '').split('.').filter(Boolean);
                let current = window;
                for (const step of steps) {
                    if (current && typeof current === 'object' && step in current) {
                        current = current[step];
                    } else {
                        return null;
                    }
                }
                return current;
            } catch (e) {
                return null;
            }
        }

        function isIgnoredKey(key) {
            if (!ignoreKeys.length) return false;
            const lowerKey = String(key).toLowerCase();
            return ignoreKeys.some(k => lowerKey.includes(k));
        }

        // --- Handlers ---
        toggleBtn.addEventListener('click', () => {
            const isHidden = panel.style.display === 'none';
            panel.style.display = isHidden ? 'block' : 'none';
            if (isHidden) renderVars();
        });

        refreshBtn.addEventListener('click', () => {
            if (window.SugarCube && window.SugarCube.Engine) window.SugarCube.Engine.show();
            renderVars();
        });

        expandBtn.addEventListener('click', () => toggleAll(true));
        collapseBtn.addEventListener('click', () => toggleAll(false));

        function toggleAll(expand) {
            const collapsibles = varContainer.querySelectorAll('.collapsible');
            const containers = varContainer.querySelectorAll('.child-container');
            collapsibles.forEach(el => expand ? el.classList.remove('collapsed') : el.classList.add('collapsed'));
            containers.forEach(el => el.style.display = expand ? 'block' : 'none');
        }

        const triggerSearch = debounce((term) => {
            currentSearchTerm = term;
            renderVars();
        }, 250);

        searchInput.addEventListener('input', (e) => {
            const safeText = e.target.value ? e.target.value.trim().toLowerCase() : '';
            triggerSearch(safeText);
        });

        clearBtn.addEventListener('click', () => {
            searchInput.value = '';
            currentSearchTerm = '';
            renderVars();
            searchInput.focus();
        });

        sourcePathInput.addEventListener('input', debounce((e) => {
            sourcePath = e.target.value.trim();
            localStorage.setItem('sc_source_path', sourcePath);
            focusPath = [];
            renderVars();
        }, 400));

        ignoreKeysInput.addEventListener('input', (e) => {
            const val = e.target.value;
            localStorage.setItem('sc_ignore_keys', val);
            ignoreKeys = val.split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
            renderVars();
        });

        clearFocusBtn.addEventListener('click', () => {
            focusPath = [];
            renderVars();
        });

        // --- Filtering Engine ---
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

        function renderVars() {
            varContainer.innerHTML = '';
            let rootObj = resolveObjectPath(sourcePath);

            if (!rootObj || typeof rootObj !== 'object') {
                varContainer.innerHTML = `<div style="color:#f38ba8; padding:10px;">Invalid or unfound object path: <b>${sourcePath}</b></div>`;
                focusBanner.style.display = 'none';
                return;
            }

            if (focusPath.length) {
                for (const step of focusPath) {
                    if (rootObj && typeof rootObj === 'object' && step in rootObj) {
                        rootObj = rootObj[step];
                    } else {
                        focusPath = [];
                        rootObj = resolveObjectPath(sourcePath);
                        break;
                    }
                }
            }

            if (focusPath.length) {
                focusBanner.style.display = 'flex';
                focusPathText.textContent = focusPath.join(' > ');
            } else {
                focusBanner.style.display = 'none';
            }

            for (const [key, value] of Object.entries(rootObj)) {
                renderField(varContainer, key, value, rootObj, currentSearchTerm, [...focusPath, key]);
            }
        }

        function renderField(container, key, value, parentObj, term, pathArray) {
            if (isIgnoredKey(key)) return;

            const activeTerm = focusPath.length ? '' : term;
            if (activeTerm && !hasMatch(key, value, activeTerm)) return;

            const row = document.createElement('div');
            row.className = 'var-row';

            const headerRow = document.createElement('div');
            headerRow.className = 'var-header-container';

            const label = document.createElement('span');
            label.className = 'var-name';
            label.textContent = isNaN(key) ? key : `[${key}]`;

            headerRow.appendChild(label);
            row.appendChild(headerRow);

            if (typeof value === 'object' && value !== null) {
                label.classList.add('collapsible');
                const entries = Object.entries(value).filter(([k]) => !isIgnoredKey(k));
                label.textContent += Array.isArray(value) ? ` [Array:${entries.length}]` : ' {Object}';

                const focusBtn = document.createElement('button');
                focusBtn.className = 'btn-focus';
                focusBtn.textContent = 'Focus ➔';
                focusBtn.title = 'Isolate and view this object fully without filters';
                focusBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    focusPath = [...pathArray];
                    currentSearchTerm = '';
                    searchInput.value = '';
                    renderVars();
                });
                headerRow.appendChild(focusBtn);

                const childContainer = document.createElement('div');
                childContainer.className = 'child-container';

                const keyMatchedDirectly = activeTerm && String(key).toLowerCase().includes(activeTerm);
                const childTerm = keyMatchedDirectly ? '' : activeTerm;

                for (const [childKey, childValue] of entries) {
                    renderField(childContainer, childKey, childValue, value, childTerm, [...pathArray, childKey]);
                }

                if (activeTerm) {
                    childContainer.style.display = 'block';
                    label.classList.remove('collapsed');
                } else {
                    childContainer.style.display = 'block';
                }

                row.appendChild(childContainer);

                label.addEventListener('click', () => {
                    const isCollapsed = childContainer.style.display === 'none';
                    childContainer.style.display = isCollapsed ? 'block' : 'none';
                    label.classList.toggle('collapsed', !isCollapsed);
                });
            } else {
                const inputGroup = document.createElement('div');
                inputGroup.className = 'input-group';

                const input = document.createElement('input');
                input.className = 'var-input';
                input.type = 'text';
                input.value = (value !== undefined && value !== null) ? value : String(value);

                const originalType = typeof value;

                const updateValue = (newVal) => {
                    let parsedVal = newVal;
                    if (originalType === 'boolean') {
                        parsedVal = (newVal === 'true' || newVal === true);
                    } else if (originalType === 'number') {
                        parsedVal = Number(newVal);
                    }

                    parentObj[key] = parsedVal;
                    input.value = parsedVal;
                    input.style.borderColor = '#a6e3a1';
                };

                input.addEventListener('change', (e) => updateValue(e.target.value));
                inputGroup.appendChild(input);

                const btnGroup = document.createElement('div');
                btnGroup.className = 'btn-group';

                const createQuickBtn = (text, targetVal) => {
                    const qBtn = document.createElement('button');
                    qBtn.className = 'quick-btn';
                    qBtn.textContent = text;
                    qBtn.addEventListener('click', () => updateValue(targetVal));
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
            }
            container.appendChild(row);
        }
    }
})();