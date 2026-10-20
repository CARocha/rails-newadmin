import { build } from "esbuild";
import { resolve } from "node:path";
const host = process.argv[2];
await build({ entryPoints: [resolve(host, "app/javascript/application.js")], bundle: true, minify: true,
  outfile: resolve(host, "app/assets/builds/host_bundle.js"), nodePaths: [resolve("node_modules")] });
