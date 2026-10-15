# How to update the theme

Steps for releasing a new version of **Venkatasaianand Dark Theme** to the VS Code Marketplace.

## 1. Edit the theme

Make your changes in `themes/venkatasaianand-dark-color-theme.json`:

- `"colors"`: the editor interface (backgrounds, sidebar, tabs, status bar, terminal, ...)
- `"tokenColors"` and `"semanticTokenColors"`: code colors (keywords, strings, functions, ...)

To find which rule colors a piece of code, put the cursor on it and run
**Developer: Inspect Editor Tokens and Scopes** (`Ctrl+Shift+P`). Then search the JSON for that scope name.

## 2. Check it before publishing

1. Open this project folder in VS Code and press **F5**. This uses `.vscode/launch.json`.
2. A second VS Code window opens with the theme loaded. Select it there with **Preferences: Color Theme**.
3. Edit and save the JSON in the first window. The second window updates right away, or after you run
   **Developer: Reload Window** there.

## 3. Bump the version and add a changelog note

In `package.json`, raise `"version"`:

- `1.0.0` → `1.0.1` for small color fixes
- `1.0.0` → `1.1.0` for bigger changes or new colors

Add an entry at the top of `CHANGELOG.md`:

```md
## [1.0.1] - YYYY-MM-DD
- Brightened comment color.
- Fixed low-contrast selection highlight.
```

> The Marketplace rejects an upload that reuses a version number it has already seen, so bump it every time.

## 4. Build and upload

1. In the terminal for this folder, run:

   ```
   npx @vscode/vsce package
   ```

   This creates `venkatasaianand-dark-theme-<version>.vsix`.
2. Go to <https://marketplace.visualstudio.com/manage/publishers/venkatasaianand-dev>.
3. Click **⋯** next to the extension, choose **Update**, and upload the new `.vsix`.
4. Wait for it to finish verifying, which takes a few minutes.
5. Save the changes to GitHub:

   ```
   git add .
   git commit -m "v1.0.1"
   git push
   ```

## 5. On other machines (e.g. the work laptop)

VS Code checks for extension updates on its own, so the new version usually installs within a few hours.
To get it right away, open the Extensions view (`Ctrl+Shift+X`), find the theme, and click **Update**,
or use **Check for Extension Updates**.
