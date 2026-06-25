import Foundation

enum HTMLDocumentBuilder {
    static func emptyDocument() -> String {
        document(
            title: "PrintMD Preview",
            body: emptyBody(),
            themeCSS: DocumentTheme.clean.css,
            userCSS: "",
            fontSize: 10,
            pageSize: .a4,
            printMode: .standard
        )
    }

    static func emptyBody() -> String {
        """
        <section class="empty-state">
          <h1>未选择 Markdown 文件</h1>
          <p>打开 .md 或 .markdown 文件后，会在这里显示分页打印预览。</p>
        </section>
        """
    }

    static func document(
        title: String,
        body: String,
        themeCSS: String,
        userCSS: String,
        fontSize: Double,
        pageSize: PageSize,
        printMode: PrintMode
    ) -> String {
        let physicalPageWidth = printMode == .eco ? pageSize.cssHeight : pageSize.cssWidth
        let physicalPageHeight = printMode == .eco ? pageSize.cssWidth : pageSize.cssHeight
        let pageCSSSize = "\(physicalPageWidth) \(physicalPageHeight)"
        let ecoScaledPageWidth = "\(pageSize.paperSize.width * pageSize.ecoScale)pt"
        let ecoScaledPageHeight = "\(pageSize.paperSize.height * pageSize.ecoScale)pt"

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(title.escapedHTML)</title>
          <style>
          \(defaultCSS)
          </style>
          <style id="builtin-theme-css">
          \(themeCSS)
          </style>
          <style id="user-theme-css">
          \(userCSS)
          </style>
          <style id="runtime-css">
          :root {
            --markdown-font-size: \(fontSize)pt;
            --logical-page-width: \(pageSize.cssWidth);
            --logical-page-height: \(pageSize.cssHeight);
            --print-page-width: \(physicalPageWidth);
            --print-page-height: \(physicalPageHeight);
            --eco-scale: \(String(format: "%.5f", pageSize.ecoScale));
            --eco-scaled-page-width: \(ecoScaledPageWidth);
            --eco-scaled-page-height: \(ecoScaledPageHeight);
          }

          @page {
            size: \(pageCSSSize);
            margin: 0;
          }
          </style>
        </head>
        <body>
          <main id="paged-preview" class="paged-preview" aria-label="打印预览页面"></main>
          <main id="pagination-workspace" class="pagination-workspace" aria-hidden="true"></main>
          <main id="source-document" class="source-document" aria-hidden="true">
            <article class="markdown-body">
        \(body)
            </article>
          </main>
          <script>
          \(MermaidSupport.inlineScript)
          </script>
          <script>
          window.__printMDPrintMode = "\(printMode.rawValue)";
          </script>
          <script>
          \(paginationScript)
          </script>
        </body>
        </html>
        """
    }

    private static let defaultCSS = """
    :root {
      color-scheme: light;
      --preview-background: #d9dde3;
      --sheet-background: #ffffff;
      --body-text: #17202a;
      --muted-text: #5c6673;
      --rule-color: #d7dde5;
      --strong-rule-color: #aeb9c7;
      --inline-code-background: #f3f5f8;
      --table-header-background: #eef3f8;
      --table-row-alt-background: #fafbfc;
      --link-color: #1b5f97;
      --heading-color: #123c5d;
      --blockquote-background: #f7f9fb;
      --body-line-height: 1.58;
      --block-spacing: 0.62em;
      --sheet-padding-horizontal: 16mm;
      --sheet-padding-vertical: 15mm;
      --body-font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans CJK SC", "Helvetica Neue", Arial, sans-serif;
      --mono-font: "SF Mono", Menlo, Monaco, Consolas, monospace;
      --logical-content-width: calc(var(--logical-page-width) - var(--sheet-padding-horizontal) - var(--sheet-padding-horizontal));
      --logical-content-height: calc(var(--logical-page-height) - var(--sheet-padding-vertical) - var(--sheet-padding-vertical));
      --print-content-width: calc(var(--print-page-width) - var(--sheet-padding-horizontal) - var(--sheet-padding-horizontal));
      --print-content-height: calc(var(--print-page-height) - var(--sheet-padding-vertical) - var(--sheet-padding-vertical));
      --preview-page-gap: 24px;
    }

    * {
      box-sizing: border-box;
    }

    html {
      min-height: 100%;
      background: var(--preview-background);
    }

    body {
      min-height: 100%;
      margin: 0;
      background: var(--preview-background);
      color: var(--body-text);
      font-family: var(--body-font);
      -webkit-font-smoothing: antialiased;
      text-rendering: optimizeLegibility;
    }

    .paged-preview {
      counter-reset: page;
      padding: 28px 0;
    }

    .print-page {
      position: relative;
      width: var(--print-page-width);
      height: var(--print-page-height);
      margin: 0 auto var(--preview-page-gap);
      background: var(--sheet-background);
      color: var(--body-text);
      box-shadow: 0 16px 42px rgb(21 31 45 / 20%);
      counter-increment: page;
      overflow: hidden;
    }

    .standard-page,
    .logical-page {
      padding: var(--sheet-padding-vertical) var(--sheet-padding-horizontal);
    }

    .print-page::after {
      content: counter(page);
      position: absolute;
      right: 9mm;
      bottom: 6mm;
      color: var(--muted-text);
      font-size: 8pt;
      line-height: 1;
    }

    .standard-page > .markdown-body,
    .logical-page > .markdown-body {
      width: 100%;
      height: 100%;
      overflow: hidden;
    }

    .eco-page {
      display: grid;
      grid-template-columns: 1fr 1fr;
      padding: 0;
    }

    .eco-slot {
      display: grid;
      place-items: center;
      min-width: 0;
      height: 100%;
      overflow: hidden;
    }

    .eco-slot + .eco-slot {
      border-left: 0.3pt solid var(--rule-color);
    }

    .eco-slot-content {
      width: var(--eco-scaled-page-width);
      height: var(--eco-scaled-page-height);
      overflow: hidden;
    }

    .eco-slot-content > .logical-page {
      transform: scale(var(--eco-scale));
      transform-origin: top left;
    }

    .logical-page {
      position: relative;
      width: var(--logical-page-width);
      height: var(--logical-page-height);
      background: var(--sheet-background);
      color: var(--body-text);
      overflow: hidden;
    }

    .pagination-workspace {
      position: absolute;
      top: 0;
      left: -100000px;
      width: var(--logical-page-width);
      visibility: hidden;
      pointer-events: none;
    }

    .source-document {
      position: absolute;
      top: 0;
      left: -100000px;
      width: var(--logical-content-width);
      visibility: hidden;
      pointer-events: none;
    }

    .source-document > .markdown-body {
      width: var(--logical-content-width);
    }

    .markdown-body {
      font-size: var(--markdown-font-size);
      line-height: var(--body-line-height);
      overflow-wrap: anywhere;
    }

    .markdown-body > :first-child {
      margin-top: 0;
    }

    .markdown-body > :last-child {
      margin-bottom: 0;
    }

    h1, h2, h3, h4, h5, h6 {
      color: var(--heading-color);
      margin: 1.15em 0 0.45em;
      font-weight: 700;
      line-height: 1.18;
      letter-spacing: 0;
    }

    h1 {
      font-size: 1.85em;
      padding-bottom: 0.26em;
      border-bottom: 1.5px solid var(--strong-rule-color);
    }

    h2 {
      font-size: 1.42em;
      padding-bottom: 0.22em;
      border-bottom: 1px solid var(--rule-color);
    }

    h3 {
      font-size: 1.16em;
      color: var(--body-text);
    }

    h4, h5, h6 {
      font-size: 1em;
      color: var(--body-text);
    }

    p, ul, ol, blockquote, pre, table, .mermaid-diagram {
      margin: var(--block-spacing) 0;
    }

    ul, ol {
      padding-left: 1.25em;
    }

    li + li {
      margin-top: 0.18em;
    }

    blockquote {
      padding: 0.35em 0.75em;
      border-left: 3px solid var(--strong-rule-color);
      background: var(--blockquote-background);
      color: var(--muted-text);
    }

    a {
      color: var(--link-color);
      text-decoration-thickness: 0.08em;
      text-underline-offset: 0.16em;
    }

    code {
      padding: 0.08em 0.28em;
      border-radius: 4px;
      background: var(--inline-code-background);
      font-family: var(--mono-font);
      font-size: 0.88em;
    }

    pre {
      padding: 0.72em 0.82em;
      overflow-x: auto;
      border-radius: 6px;
      background: var(--inline-code-background);
      border: 1px solid var(--rule-color);
      white-space: pre-wrap;
    }

    pre code {
      padding: 0;
      background: transparent;
      border-radius: 0;
      font-size: 0.88em;
    }

    img {
      max-width: 100%;
      height: auto;
    }

    hr {
      height: 1px;
      margin: 1.5em 0;
      border: 0;
      background: var(--rule-color);
    }

    table {
      width: 100%;
      border-collapse: collapse;
    }

    th, td {
      padding: 0.36em 0.5em;
      border: 1px solid var(--rule-color);
      text-align: left;
      vertical-align: top;
    }

    th {
      background: var(--table-header-background);
      color: var(--heading-color);
      font-weight: 700;
    }

    tbody tr:nth-child(even) {
      background: var(--table-row-alt-background);
    }

    .task-list-item {
      list-style: none;
      margin-left: -1.35em;
    }

    .task-list-item input[type="checkbox"] {
      width: 0.95em;
      height: 0.95em;
      margin: 0 0.45em 0 0;
      vertical-align: -0.1em;
    }

    .footnotes {
      margin-top: 2em;
      padding-top: 0.8em;
      border-top: 1px solid var(--rule-color);
      color: var(--muted-text);
      font-size: 0.88em;
    }

    .footnotes li p {
      margin: 0.28em 0;
    }

    .mermaid-diagram {
      break-inside: avoid;
      page-break-inside: avoid;
      text-align: center;
    }

    .mermaid-diagram svg {
      display: block;
      max-width: 100%;
      height: auto;
      margin: 0 auto;
    }

    .mermaid-error {
      border: 1px solid color-mix(in srgb, #d93025, Canvas 45%);
      background: color-mix(in srgb, #d93025, Canvas 92%);
    }

    .mermaid-error::before {
      display: block;
      margin-bottom: 0.6em;
      color: #a50e0e;
      content: "Mermaid render failed: " attr(data-mermaid-error);
      font-family: var(--body-font);
      font-size: 0.86em;
      font-weight: 700;
      white-space: normal;
    }

    .empty-state {
      display: grid;
      min-height: var(--logical-content-height);
      place-content: center;
      color: var(--muted-text);
      text-align: center;
    }

    .empty-state h1 {
      margin: 0;
      border: 0;
      font-size: 1.3em;
    }

    .empty-state p {
      margin: 0.6em 0 0;
    }

    @media print {
      html,
      body {
        background: transparent;
      }

      .source-document {
        display: none;
      }

      .pagination-workspace {
        display: none;
      }

      .paged-preview {
        padding: 0;
      }

      .print-page {
        width: var(--print-page-width);
        height: var(--print-page-height);
        margin: 0;
        box-shadow: none;
        break-inside: avoid;
        page-break-inside: avoid;
        break-after: auto;
        page-break-after: auto;
      }

      .print-page::after {
        display: none;
      }

      .standard-page > .markdown-body {
        height: 100%;
      }

      a {
        color: inherit;
      }
    }
    """

    private static let paginationScript = """
    (() => {
      const preview = document.getElementById("paged-preview");
      const workspace = document.getElementById("pagination-workspace");
      const sourceArticle = document.querySelector("#source-document > .markdown-body");
      const isEcoMode = window.__printMDPrintMode === "eco";
      let paginationToken = 0;

      async function renderMermaidDiagrams() {
        if (!sourceArticle) {
          return;
        }

        const codeBlocks = Array.from(sourceArticle.querySelectorAll(
          "pre > code.language-mermaid, pre[lang='mermaid'] > code"
        ));

        if (codeBlocks.length === 0) {
          return;
        }

        if (!window.mermaid || window.__printMDMermaidLoadError) {
          for (const code of codeBlocks) {
            markMermaidError(code, "Mermaid library was not loaded.");
          }
          return;
        }

        window.mermaid.initialize({
          startOnLoad: false,
          securityLevel: "strict",
          theme: "default",
          flowchart: {
            htmlLabels: false
          },
          sequence: {
            useMaxWidth: true
          },
          gantt: {
            useMaxWidth: true
          }
        });

        for (const [index, code] of codeBlocks.entries()) {
          const pre = code.closest("pre");
          const diagramSource = code.textContent.trim();

          if (!pre || diagramSource.length === 0) {
            continue;
          }

          const container = document.createElement("figure");
          container.className = "mermaid-diagram";

          try {
            const renderID = `printmd-mermaid-${Date.now()}-${index}`;
            const result = await window.mermaid.render(renderID, diagramSource);
            container.innerHTML = result.svg;

            if (typeof result.bindFunctions === "function") {
              result.bindFunctions(container);
            }

            pre.replaceWith(container);
          } catch (error) {
            markMermaidError(code, error && error.message ? error.message : "Unknown Mermaid error.");
          }
        }
      }

      function markMermaidError(code, message) {
        const pre = code.closest("pre");
        if (!pre) {
          return;
        }

        pre.classList.add("mermaid-error");
        pre.setAttribute("data-mermaid-error", message);
      }

      function createLogicalPage() {
        const page = document.createElement("section");
        page.className = "logical-page";

        const article = document.createElement("article");
        article.className = "markdown-body";
        page.appendChild(article);
        workspace.appendChild(page);
        return article;
      }

      function cloneArticleFrom(logicalPage) {
        const source = logicalPage.querySelector(":scope > .markdown-body");
        const article = document.createElement("article");
        article.className = "markdown-body";

        if (source) {
          for (const child of Array.from(source.childNodes)) {
            article.appendChild(child.cloneNode(true));
          }
        }

        return article;
      }

      function renderStandardPage(logicalPage) {
        const page = document.createElement("section");
        page.className = "print-page standard-page";
        page.appendChild(cloneArticleFrom(logicalPage));
        return page;
      }

      function renderEcoSlot(logicalPage) {
        const slot = document.createElement("div");
        slot.className = "eco-slot";

        if (!logicalPage) {
          return slot;
        }

        const content = document.createElement("div");
        content.className = "eco-slot-content";

        const sheet = document.createElement("section");
        sheet.className = "logical-page";
        sheet.appendChild(cloneArticleFrom(logicalPage));

        content.appendChild(sheet);
        slot.appendChild(content);
        return slot;
      }

      function renderPrintPages() {
        const logicalPages = Array.from(workspace.querySelectorAll(":scope > .logical-page"));
        preview.replaceChildren();

        if (!isEcoMode) {
          for (const logicalPage of logicalPages) {
            preview.appendChild(renderStandardPage(logicalPage));
          }
          return;
        }

        for (let index = 0; index < logicalPages.length; index += 2) {
          const page = document.createElement("section");
          page.className = "print-page eco-page";
          page.appendChild(renderEcoSlot(logicalPages[index]));
          page.appendChild(renderEcoSlot(logicalPages[index + 1]));
          preview.appendChild(page);
        }
      }

      function overflows(article) {
        return article.scrollHeight > article.clientHeight + 1;
      }

      function pageHasContent(article) {
        return article.children.length > 0 || article.textContent.trim().length > 0;
      }

      function newListLike(original) {
        const clone = original.cloneNode(false);
        clone.removeAttribute("id");
        return clone;
      }

      function newTableLike(original) {
        const clone = original.cloneNode(false);
        clone.removeAttribute("id");

        const caption = original.querySelector(":scope > caption");
        if (caption) {
          clone.appendChild(caption.cloneNode(true));
        }

        const thead = original.tHead;
        if (thead) {
          clone.appendChild(thead.cloneNode(true));
        }

        const tbody = document.createElement("tbody");
        clone.appendChild(tbody);
        return { table: clone, body: tbody };
      }

      function appendNodeToPage(node, state) {
        const clone = node.cloneNode(true);
        state.article.appendChild(clone);

        if (!overflows(state.article)) {
          return state;
        }

        state.article.removeChild(clone);

        if (!pageHasContent(state.article)) {
          state.article.appendChild(clone);
          return state;
        }

        state.article = createLogicalPage();
        state.article.appendChild(clone);
        return state;
      }

      function appendListToPages(list, state) {
        const items = Array.from(list.children);
        let currentList = newListLike(list);
        state.article.appendChild(currentList);

        if (overflows(state.article) && !pageHasContentWithout(state.article, currentList)) {
          return state;
        }

        if (overflows(state.article)) {
          state.article.removeChild(currentList);
          state.article = createLogicalPage();
          currentList = newListLike(list);
          state.article.appendChild(currentList);
        }

        for (const item of items) {
          const clone = item.cloneNode(true);
          currentList.appendChild(clone);

          if (!overflows(state.article)) {
            continue;
          }

          currentList.removeChild(clone);

          if (currentList.children.length === 0) {
            currentList.appendChild(clone);
            continue;
          }

          state.article = createLogicalPage();
          currentList = newListLike(list);
          state.article.appendChild(currentList);
          currentList.appendChild(clone);
        }

        return state;
      }

      function appendTableToPages(table, state) {
        const rows = Array.from(table.querySelectorAll(":scope > tbody > tr"));
        if (rows.length === 0) {
          return appendNodeToPage(table, state);
        }

        let tableParts = newTableLike(table);
        state.article.appendChild(tableParts.table);

        if (overflows(state.article)) {
          state.article.removeChild(tableParts.table);
          if (!pageHasContent(state.article)) {
            state.article.appendChild(table.cloneNode(true));
            return state;
          }

          state.article = createLogicalPage();
          tableParts = newTableLike(table);
          state.article.appendChild(tableParts.table);
        }

        for (const row of rows) {
          const clone = row.cloneNode(true);
          tableParts.body.appendChild(clone);

          if (!overflows(state.article)) {
            continue;
          }

          tableParts.body.removeChild(clone);

          if (tableParts.body.children.length === 0) {
            tableParts.body.appendChild(clone);
            continue;
          }

          state.article = createLogicalPage();
          tableParts = newTableLike(table);
          state.article.appendChild(tableParts.table);
          tableParts.body.appendChild(clone);
        }

        return state;
      }

      function pageHasContentWithout(article, node) {
        return Array.from(article.childNodes).some((child) => child !== node && child.textContent.trim().length > 0);
      }

      function paginate() {
        const token = ++paginationToken;
        window.__printMDPaginated = false;
        preview.replaceChildren();
        workspace.replaceChildren();

        if (!sourceArticle) {
          window.__printMDPaginated = true;
          return;
        }

        let state = { article: createLogicalPage() };
        const children = Array.from(sourceArticle.children);

        for (const child of children) {
          if (token !== paginationToken) {
            return;
          }

          const tagName = child.tagName.toLowerCase();
          if (tagName === "table") {
            state = appendTableToPages(child, state);
          } else if (tagName === "ul" || tagName === "ol") {
            state = appendListToPages(child, state);
          } else {
            state = appendNodeToPage(child, state);
          }
        }

        renderPrintPages();
        window.__printMDPaginated = true;
      }

      function schedulePaginate() {
        window.__printMDPaginated = false;
        requestAnimationFrame(() => requestAnimationFrame(paginate));
      }

      async function preparePreview() {
        window.__printMDPaginated = false;
        await renderMermaidDiagrams();

        if (document.fonts && document.fonts.ready) {
          await document.fonts.ready;
        }

        schedulePaginate();
      }

      preparePreview();

      window.addEventListener("resize", schedulePaginate);
    })();
    """
}
