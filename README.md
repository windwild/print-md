# PrintMD

PrintMD 是一个原生 macOS Markdown 打印预览工具。它专注于把 Markdown 文档变成更接近真实纸张的预览，并通过主题、字号、分页和打印模式控制最终输出。

PrintMD is a native macOS Markdown print preview app. It focuses on turning Markdown documents into paper-like previews with theme, font size, pagination, and print-mode controls.

## 中文

### 功能

- 打开 `.md` 和 `.markdown` 文件。
- 使用 `cmark-gfm` 渲染 GitHub Flavored Markdown，支持表格、任务列表、删除线、自动链接、脚注、代码块和 HTML 过滤。
- 支持 Mermaid 图表预览。
- 提供多个内置打印主题，并支持导入自定义 CSS。
- 默认正文字号为 10pt，可通过工具栏加减号调整。
- 预览区按纸张分页，打印时尽量保持预览效果一致。
- 使用 macOS 原生打印面板。
- 支持单面、双面长边、双面短边打印。
- 支持环保模式：横向纸张、短边装订、每一面排 2 页逻辑内容，提高纸张利用率。

### 运行

需要 macOS 14 或更新版本，以及 Xcode Command Line Tools。

```bash
./script/build_and_run.sh
```

只验证能否构建并启动：

```bash
./script/build_and_run.sh --verify
```

单独构建 SwiftPM 目标：

```bash
swift build
```

### 自定义主题

可以在工具栏中点击“导入 CSS”，选择自己的 CSS 文件覆盖内置主题。`Themes/sample-theme.css` 可以作为起点。

主题 CSS 主要作用在生成的打印 HTML 上，常见选择器包括：

```css
body {}
h1, h2, h3 {}
p, li {}
table, th, td {}
pre, code {}
blockquote {}
```

### 发布 Release

公开发布建议使用 Developer ID 签名和 Apple notarization。没有签名的压缩包也能用于个人测试，但其他用户下载后可能需要右键打开，或被 Gatekeeper 拦截。

1. 设置版本并构建 app：

```bash
APP_VERSION=0.1.0 ./script/build_and_run.sh --verify
```

2. 可选：用 Developer ID 签名：

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  dist/PrintMD.app
```

3. 可选：提交 notarization 并 stapling：

```bash
xcrun notarytool submit dist/PrintMD.app \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

xcrun stapler staple dist/PrintMD.app
```

4. 打包 app：

```bash
ditto -c -k --keepParent dist/PrintMD.app dist/PrintMD-v0.1.0-macos.zip
```

5. 打标签并推送：

```bash
git tag v0.1.0
git push origin main --tags
```

6. 创建 GitHub Release：

```bash
gh release create v0.1.0 dist/PrintMD-v0.1.0-macos.zip \
  --title "PrintMD v0.1.0" \
  --notes "Initial public release."
```

## English

### Features

- Opens `.md` and `.markdown` files.
- Renders GitHub Flavored Markdown through `cmark-gfm`, including tables, task lists, strikethrough, autolinks, footnotes, fenced code blocks, and filtered HTML.
- Supports Mermaid diagrams.
- Includes multiple built-in print themes and custom CSS import.
- Uses a 10pt default body font size with toolbar controls for increasing or decreasing it.
- Previews documents in paginated paper layout.
- Prints through the native macOS print panel.
- Supports single-sided, double-sided long-edge, and double-sided short-edge printing.
- Includes Eco mode: landscape paper, short-edge duplex, and two logical pages per printed side for better paper usage.

### Run

Requires macOS 14 or newer and Xcode Command Line Tools.

```bash
./script/build_and_run.sh
```

Verify build and launch:

```bash
./script/build_and_run.sh --verify
```

Build the SwiftPM target only:

```bash
swift build
```

### Custom Themes

Use the toolbar CSS import button to load a custom CSS file over the current theme. `Themes/sample-theme.css` is a useful starting point.

The CSS applies to the generated print HTML. Common selectors include:

```css
body {}
h1, h2, h3 {}
p, li {}
table, th, td {}
pre, code {}
blockquote {}
```

### Release

For public distribution, use Developer ID signing and Apple notarization. An unsigned zip can work for personal testing, but other users may need to right-click open it or may be blocked by Gatekeeper.

1. Set the version and build the app:

```bash
APP_VERSION=0.1.0 ./script/build_and_run.sh --verify
```

2. Optional: sign with Developer ID:

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  dist/PrintMD.app
```

3. Optional: notarize and staple:

```bash
xcrun notarytool submit dist/PrintMD.app \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

xcrun stapler staple dist/PrintMD.app
```

4. Package the app:

```bash
ditto -c -k --keepParent dist/PrintMD.app dist/PrintMD-v0.1.0-macos.zip
```

5. Tag and push:

```bash
git tag v0.1.0
git push origin main --tags
```

6. Create the GitHub Release:

```bash
gh release create v0.1.0 dist/PrintMD-v0.1.0-macos.zip \
  --title "PrintMD v0.1.0" \
  --notes "Initial public release."
```

## Open Source Components

- [`swift-cmark`](https://github.com/swiftlang/swift-cmark) / `cmark-gfm` for GitHub Flavored Markdown rendering.
- [`Mermaid`](https://github.com/mermaid-js/mermaid) for diagram rendering.
