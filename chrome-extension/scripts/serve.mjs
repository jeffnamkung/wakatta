// Tiny static server for test/harness.html (dev only).
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(fileURLToPath(import.meta.url), "..", "..");
const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".css": "text/css", ".png": "image/png", ".json": "application/json" };
createServer(async (req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, "http://x").pathname)).replace(/^(\.\.[/\\])+/, "");
  try {
    let body = await readFile(join(root, path === "/" ? "test/harness.html" : path));
    // Preview extension pages in a normal tab by injecting the chrome.* stub.
    if (path.startsWith("/dist/pages/") && path.endsWith(".html")) {
      body = body.toString().replace("<script", '<script src="/test/chrome-stub.js"></script><script');
    }
    res.writeHead(200, { "content-type": types[extname(path)] || "application/octet-stream" }).end(body);
  } catch {
    res.writeHead(404).end("not found");
  }
}).listen(Number(process.env.PORT) || 8765);
