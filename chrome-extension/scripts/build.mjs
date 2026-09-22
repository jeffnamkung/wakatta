// Bundles src/ into dist/ (the unpacked extension) and optionally zips it for the Chrome Web Store.
import * as esbuild from "esbuild";
import { cp, mkdir, rm, readFile } from "node:fs/promises";
import { execFileSync } from "node:child_process";

const watch = process.argv.includes("--watch");
const zip = process.argv.includes("--zip");
const out = "dist";

await rm(out, { recursive: true, force: true });
await mkdir(`${out}/pages`, { recursive: true });

const common = {
  bundle: true,
  target: "chrome116",
  loader: { ".css": "text" },
  legalComments: "none",
  minify: !watch,
  sourcemap: watch ? "inline" : false,
  logLevel: "info",
};

const builds = [
  { entryPoints: ["src/background.js"], outfile: `${out}/background.js`, format: "esm" },
  { entryPoints: ["src/content.js"], outfile: `${out}/content.js`, format: "iife" },
  ...["popup", "options", "review", "panel"].map((p) => ({
    entryPoints: [`src/pages/${p}.src.js`],
    outfile: `${out}/pages/${p}.js`,
    format: "iife",
  })),
];

async function copyStatic() {
  await cp("src/manifest.json", `${out}/manifest.json`);
  await cp("src/icons", `${out}/icons`, { recursive: true });
  for (const f of ["popup.html", "options.html", "review.html", "panel.html", "pages.css"]) {
    await cp(`src/pages/${f}`, `${out}/pages/${f}`);
  }
}

if (watch) {
  await copyStatic();
  for (const b of builds) (await esbuild.context({ ...common, ...b })).watch();
  console.log("Watching… reload the extension in chrome://extensions after changes.");
} else {
  await Promise.all(builds.map((b) => esbuild.build({ ...common, ...b })));
  await copyStatic();
  if (zip) {
    const { version } = JSON.parse(await readFile("src/manifest.json", "utf8"));
    const name = `kotolens-${version}.zip`;
    await rm(name, { force: true });
    execFileSync("zip", ["-r", "-X", `../${name}`, "."], { cwd: out, stdio: "inherit" });
    console.log(`\nCreated ${name}. Upload it at https://chrome.google.com/webstore/devconsole`);
  }
}
