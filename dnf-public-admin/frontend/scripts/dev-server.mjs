import http from 'node:http';
import { readFileSync, existsSync } from 'node:fs';
import { join, extname } from 'node:path';

const root = new URL('..', import.meta.url).pathname;
const port = Number(process.env.PORT || 5173);

const contentType = (file) => ({
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8'
}[extname(file)] || 'text/plain; charset=utf-8');

const server = http.createServer((req, res) => {
  const file = req.url === '/' ? 'index.html' : req.url.slice(1);
  const full = join(root, file);
  if (!existsSync(full)) {
    res.statusCode = 404;
    res.end('not found');
    return;
  }
  res.setHeader('Content-Type', contentType(full));
  res.end(readFileSync(full));
});

server.listen(port, () => {
  console.log(`frontend preview on http://127.0.0.1:${port}`);
});
