import { createServer } from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { renderStaffConsole } from "./render.ts";

const port = Number(process.env.PORT ?? 3010);
const server = createServer((request, response) => {
  const url = request.url ?? "/";
  if (url === "/" || url.startsWith("/?")) {
    response.writeHead(200, { "content-type": "text/html; charset=utf-8" });
    response.end(renderStaffConsole());
    return;
  }
  response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
  response.end("Not found");
});

const invokedDirectly = process.argv[1]
  ? path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
  : false;

if (invokedDirectly) {
  server.listen(port, "127.0.0.1");
}
