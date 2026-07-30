# Linux Transparency

- Open `about:config`
- Search for `zen.widget.linux.transparency`, set to `true`
- Open Desktop Effects, find `Better Blur DX`
- Add window class `app.zen_browser.zen`
- Restart Zen browser

It should has a transparent background, but the page content is not transparent.


# Linew Wrapping Off

I open file contents in my Zen browser over S3. The defaul page behaviour is wraps lines, and it makes things hard to read.

So i created a bookmarklet that opens the page in a new tab with the following code:

- Open bookmarks panel via `Ctrl+B`
- Right click an empty space and select `Add bookmark`
- Enter a name for the bookmark and paste the following code:
- Name: Line Wrapping Off
- URL: `javascript:(function(){document.querySelector('pre').style.whiteSpace='pre';})();`
- Keyword: `lw`
- Click `Save`

I personally don't use bookmarks, so with the Keyword set, i can just type `lw` to address bar of the current tab `(CTRL+L)`, and it disables the line wrapping immediately.