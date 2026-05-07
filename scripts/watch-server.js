// quarto-html-server.js
// Fast HTML preview - renders only the changed file, reloads browser via SSE.
//
// Usage: node quarto-html-server.js

const http = require("http");
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const PORT = 5501;
const PROJECT_DIR = process.cwd();
const POLL_MS = 800;

// -- SSE ----------------------------------------------------------------------
let clients = [];
function broadcast(msg) {
    clients = clients.filter(c => {
        try { c.write(`data: ${msg}\n\n`); return true; } catch { return false; }
    });
}

// -- Reload snippet injected into every HTML page ------------------------------
const INJECT = `
<script>
(function() {
  var msg = document.createElement("div");
  msg.id = "__qmsg";
  msg.style = "position:fixed;bottom:12px;right:12px;padding:6px 12px;border-radius:4px;" +
    "background:#2b2b2b;color:#7ec87e;font:12px monospace;z-index:99999;display:none";
  document.body.appendChild(msg);

  function show(text, color) {
    msg.textContent = text;
    msg.style.color = color || "#7ec87e";
    msg.style.display = "block";
  }
  function hide() { msg.style.display = "none"; }

  function connect() {
    var es = new EventSource("/__sse");
    es.onmessage = function(e) {
      if (e.data === "rendering") { show("rendering...", "#f0c040"); }
      else if (e.data === "done")  {
        show("reloading...", "#7ec87e");
        location.reload();
      } else if (e.data === "error") {
        show("render error", "#e06060");
      }
    };
    es.onerror = function() {
      show("reconnecting...", "#888");
      es.close();
      setTimeout(connect, 2000);
    };
  }
  connect();
})();
</script>`;

// -- MIME ----------------------------------------------------------------------
const MIME = {
    ".html": "text/html", ".css": "text/css", ".js": "application/javascript",
    ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
    ".svg": "image/svg+xml", ".ico": "image/x-icon",
    ".woff": "font/woff", ".woff2": "font/woff2", ".ttf": "font/ttf",
    ".gif": "image/gif", ".webp": "image/webp",
};

// -- HTTP server ---------------------------------------------------------------
http.createServer((req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");

    if (req.url === "/__sse") {
        res.writeHead(200, {
            "Content-Type": "text/event-stream",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        });
        res.write(": connected\n\n");
        clients.push(res);

        const hb = setInterval(() => {
            try { res.write(": heartbeat\n\n"); } catch { clearInterval(hb); }
        }, 15000);

        req.on("close", () => {
            clearInterval(hb);
            clients = clients.filter(c => c !== res);
        });
        return;
    }

    const urlPath = req.url.split("?")[0];
    const filePath = path.join(PROJECT_DIR, urlPath === "/" ? "index.html" : urlPath);

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { "Content-Type": "text/plain" });
            res.end("Not found: " + urlPath);
            return;
        }
        const ext = path.extname(filePath);
        const mime = MIME[ext] || "application/octet-stream";
        res.writeHead(200, { "Content-Type": mime, "Cache-Control": "no-store" });

        if (ext === ".html") {
            const html = data.toString();
            res.end(html.includes("</body>") ? html.replace("</body>", INJECT + "</body>") : html + INJECT);
        } else {
            res.end(data);
        }
    });

}).listen(PORT, () => {
    console.log(`\n[READY] http://localhost:${PORT}`);
    console.log(`        HTML preview - renders only changed file (fast)\n`);
});

// -- Render --------------------------------------------------------------------
function render(changedFile) {
    broadcast("rendering");

    // Always full render - single-file only updates that file's .html,
    // but index.html (what the browser shows) only updates on full render.
    const args = ["render", "--to", "html"];
    const label = path.relative(PROJECT_DIR, changedFile);
    console.log(`[INFO] Full render (triggered by ${label})...`);

    const r = spawnSync("quarto", args, {
        cwd: PROJECT_DIR,
        stdio: "inherit",
        shell: true,
    });

    if (r.status === 0) {
        console.log("[OK]   Done - reloading browser");
        broadcast("done");
    } else {
        console.log("[WARN] Render errors");
        broadcast("error");
    }
}

// -- File watcher --------------------------------------------------------------
const SKIP = new Set(["node_modules", ".quarto", "_freeze", "_book", "_site"]);

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

// Initial full render
console.log("[INFO] Initial render...");
spawnSync("quarto", ["render", "--to", "html"], { cwd: PROJECT_DIR, stdio: "inherit", shell: true });
console.log("[OK]   Initial render done.\n");

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
    render(changed);
    busy = false;
}, POLL_MS);
