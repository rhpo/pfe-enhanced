// quarto-server.js
// Serves index.pdf in an iframe. On every save, renders then reloads iframe
// with a cache-busting URL so the browser always fetches the fresh PDF.
//
// Usage: node quarto-server.js

const http = require("http");
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const PORT = 5500;
const PROJECT_DIR = process.cwd();
const PDF_FILE = path.join(PROJECT_DIR, "index.pdf");
const POLL_MS = 1000;

// -- SSE ----------------------------------------------------------------------
let clients = [];
function broadcast(msg) {
  clients = clients.filter(c => {
    try { c.write(`data: ${msg}\n\n`); return true; } catch { return false; }
  });
}

// -- Viewer shell (full-page iframe of the PDF) -------------------------------
function viewerPage(ts) {
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Quarto Preview</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { height:100%; background:#404040; font-family:monospace; }
  #bar {
    height:34px; background:#2b2b2b; color:#ccc;
    display:flex; align-items:center; padding:0 14px; gap:10px; font-size:13px;
  }
  #msg { color:#7ec87e; }
  iframe { width:100%; height:calc(100% - 34px); border:none; }
</style>
</head>
<body>
<div id="bar">
  <span>📄 Quarto PDF Preview</span>
  <span id="msg">ready</span>
</div>
<iframe id="f" src="/pdf?t=${ts}"></iframe>
<script>
var es = new EventSource("/__sse");
var msg = document.getElementById("msg");
var iframe = document.getElementById("f");

function getPdfViewer() {
  try { return iframe.contentWindow; } catch(e) { return null; }
}

function getScrollPos() {
  var win = getPdfViewer();
  if (!win) return null;
  // PDF.js stores the viewer in PDFViewerApplication
  try {
    var app = win.PDFViewerApplication;
    if (app && app.pdfViewer) {
      return {
        page:   app.pdfViewer.currentPageNumber,
        top:    app.pdfViewer.currentScaleValue,
        scrollY: win.scrollY || (win.document.documentElement && win.document.documentElement.scrollTop) || 0,
        scrollX: win.scrollX || (win.document.documentElement && win.document.documentElement.scrollLeft) || 0,
      };
    }
  } catch(e) {}
  // Fallback: plain scroll position
  try { return { scrollY: win.scrollY, scrollX: win.scrollX, page: null }; } catch(e) {}
  return null;
}

function restoreScrollPos(pos) {
  if (!pos) return;
  var win = getPdfViewer();
  if (!win) return;
  try {
    var app = win.PDFViewerApplication;
    if (app && app.pdfViewer && pos.page) {
      // Wait for PDF.js to finish loading the doc
      app.initializedPromise.then(function() {
        app.pdfViewer.currentPageNumber = pos.page;
        setTimeout(function() {
          win.scrollTo(pos.scrollX, pos.scrollY);
        }, 100);
      });
      return;
    }
  } catch(e) {}
  // Fallback
  try { win.scrollTo(pos.scrollX || 0, pos.scrollY || 0); } catch(e) {}
}

es.onmessage = function(e) {
  if (e.data === "rendering") {
    msg.style.color = "#f0c040";
    msg.textContent = "rendering...";
  } else if (e.data === "done") {
    msg.style.color = "#7ec87e";
    msg.textContent = "reloading...";
    // Save scroll position BEFORE changing src
    var savedPos = getScrollPos();
    var newSrc = "/pdf?t=" + Date.now();
    iframe.onload = function() {
      iframe.onload = null;
      // Restore scroll position AFTER new PDF loads
      restoreScrollPos(savedPos);
      msg.textContent = "ready";
    };
    iframe.src = newSrc;
  } else if (e.data === "error") {
    msg.style.color = "#e06060";
    msg.textContent = "render error - check terminal";
  }
};

es.onerror = function() {
  msg.style.color = "#888";
  msg.textContent = "reconnecting...";
};
</script>
</body>
</html>`;
}

// -- HTTP server --------------------------------------------------------------
http.createServer((req, res) => {

  // SSE endpoint - keep connection alive with heartbeat
  if (req.url === "/__sse") {
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      "X-Accel-Buffering": "no",
    });
    res.write(": connected\n\n");
    clients.push(res);

    // Heartbeat every 15s so connection doesn't time out during long renders
    const hb = setInterval(() => {
      try { res.write(": heartbeat\n\n"); } catch { clearInterval(hb); }
    }, 15000);

    req.on("close", () => {
      clearInterval(hb);
      clients = clients.filter(c => c !== res);
    });
    return;
  }

  // Serve the PDF with aggressive no-cache headers
  if (req.url.startsWith("/pdf")) {
    fs.readFile(PDF_FILE, (err, data) => {
      if (err) {
        res.writeHead(404, { "Content-Type": "text/plain" });
        res.end("PDF not found - waiting for first render");
        return;
      }
      res.writeHead(200, {
        "Content-Type": "application/pdf",
        "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        "Pragma": "no-cache",
        "Expires": "0",
        "Surrogate-Control": "no-store",
      });
      res.end(data);
    });
    return;
  }

  // Serve viewer at root
  if (req.url === "/" || req.url === "/index.html") {
    res.writeHead(200, { "Content-Type": "text/html", "Cache-Control": "no-store" });
    res.end(viewerPage(Date.now()));
    return;
  }

  res.writeHead(404);
  res.end("not found");

}).listen(PORT, () => {
  console.log(`\n[READY] http://localhost:${PORT}`);
  console.log(`        Open this in your browser.\n`);
});

// -- Render --------------------------------------------------------------------
function render() {
  broadcast("rendering");
  console.log("[INFO] Rendering...");
  const r = spawnSync("quarto", ["render", "--to", "pdf"], {
    cwd: PROJECT_DIR,
    stdio: "inherit",
    shell: true,
  });
  if (r.status === 0) {
    console.log("[OK]   Done - pushing reload to browser");
    broadcast("done");
  } else {
    console.log("[WARN] Render errors");
    broadcast("error");
  }
}

// ── Initial render ────────────────────────────────────────────────────────────
render();

// -- File watcher --------------------------------------------------------------
const SKIP = new Set(["node_modules", ".quarto", "_freeze", "_book"]);

function getFiles() {
  const map = {};
  (function walk(dir) {
    let list; try { list = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of list) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (!SKIP.has(e.name) && !e.name.endsWith("_files")) walk(full);
      } else if (e.name.endsWith(".qmd") || e.name === "_quarto.yml") {
        try { map[full] = fs.statSync(full).mtimeMs; } catch { }
      }
    }
  })(PROJECT_DIR);
  return map;
}

let snap = getFiles();
console.log(`[WATCH] Tracking ${Object.keys(snap).length} source files:`);
Object.keys(snap).forEach(f => console.log("  " + path.relative(PROJECT_DIR, f)));
console.log();

let busy = false;
setInterval(() => {
  if (busy) return;
  const cur = getFiles();
  const changed = Object.keys(cur).find(f => cur[f] !== snap[f]);
  snap = cur;
  if (!changed) return;
  busy = true;
  console.log(`\n[CHANGE] ${path.relative(PROJECT_DIR, changed)}`);
  render();
  busy = false;
}, POLL_MS);
