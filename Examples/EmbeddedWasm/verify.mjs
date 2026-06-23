import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const repositoryRoot = fileURLToPath(new URL("../../", import.meta.url));
const port = Number(process.env.PORT || 51740);

const contentTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".json", "application/json; charset=utf-8"],
]);

const server = createServer(async (request, response) => {
  const url = new URL(request.url || "/", `http://127.0.0.1:${port}`);
  const relativePath = decodeURIComponent(url.pathname === "/" ? "/index.html" : url.pathname);
  const filePath = normalize(join(repositoryRoot, relativePath));

  if (!filePath.startsWith(repositoryRoot)) {
    response.writeHead(403);
    response.end("Forbidden");
    return;
  }

  try {
    const body = await readFile(filePath);
    response.writeHead(200, {
      "Content-Type": contentTypes.get(extname(filePath)) || "application/octet-stream",
    });
    response.end(body);
  } catch {
    response.writeHead(404);
    response.end(`Not found: ${relativePath}`);
  }
});

await new Promise((resolve) => server.listen(port, "127.0.0.1", resolve));

const browser = await chromium.launch({
  channel: process.env.PLAYWRIGHT_CHROMIUM_CHANNEL || "chrome",
});

try {
  const page = await browser.newPage();
  const pageErrors = [];
  page.on("pageerror", (error) => {
    pageErrors.push(error);
  });

  await page.goto(`http://127.0.0.1:${port}/Examples/EmbeddedWasm/index.html`);
  await page.getByText("Embedded SwiftHTML").waitFor();
  await page.getByText("Count 0").waitFor();
  await page.getByRole("button", { name: "Increment" }).click();
  await page.getByText("Count 1").waitFor();
  await page.getByPlaceholder("Enter a name").fill("SwiftHTML");
  await page.getByText("Hello, SwiftHTML").waitFor();
  if (pageErrors.length > 0) {
    throw pageErrors[0];
  }

  console.log("Embedded SwiftHTML browser smoke test passed");
} finally {
  await browser.close();
  await new Promise((resolve) => server.close(resolve));
}
