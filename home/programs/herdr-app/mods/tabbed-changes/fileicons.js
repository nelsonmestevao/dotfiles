// File-type icons: a small subset of Material Icon Theme (MIT, see icons/files/LICENSE.txt).
// No Herdr imports, so `node` can test it.
const NAMES = {
  "package.json": "npm", "package-lock.json": "npm", "yarn.lock": "yarn", "pnpm-lock.yaml": "lock", "pnpm-workspace.yaml": "settings",
  ".gitignore": "git", ".gitattributes": "git", ".gitmodules": "git", ".gitlab-ci.yml": "gitlab",
  "dockerfile": "docker", "docker-compose.yml": "docker", "build.gradle": "gradle", "build.gradle.kts": "gradle", "settings.gradle.kts": "gradle",
  ".npmrc": "npm", ".nvmrc": "nodejs", ".editorconfig": "settings", ".prettierrc": "settings", ".eslintrc.js": "settings", ".eslintrc.base.js": "settings",
};
const SUFFIXES = [ // longest first
  ["test.tsx", "test-jsx"], ["spec.tsx", "test-jsx"], ["test.jsx", "test-jsx"], ["spec.jsx", "test-jsx"],
  ["test.ts", "test-ts"], ["spec.ts", "test-ts"], ["test.js", "test-js"], ["spec.js", "test-js"], ["d.ts", "typescript-def"],
];
const EXT = {
  ts: "typescript", mts: "typescript", cts: "typescript", tsx: "react_ts", js: "javascript", mjs: "javascript", cjs: "javascript", jsx: "react",
  json: "json", jsonc: "json", md: "markdown", mdx: "markdown", css: "css", scss: "sass", sass: "sass", html: "html", htm: "html",
  py: "python", kt: "kotlin", kts: "kotlin", java: "java", go: "go", rs: "rust", yml: "yaml", yaml: "yaml",
  sh: "console", bash: "console", zsh: "console", svg: "svg", png: "image", jpg: "image", jpeg: "image", gif: "image", webp: "image", ico: "image",
  lock: "lock", xml: "xml", sql: "database", toml: "toml", gradle: "gradle", properties: "settings", ini: "settings", conf: "settings", env: "settings",
};

// -> the icon's file name (no extension) in icons/files/
export function iconFor(path) {
  const name = path.split("/").pop().toLowerCase();
  if (NAMES[name]) return NAMES[name];
  for (const [suffix, id] of SUFFIXES) if (name.endsWith(`.${suffix}`)) return id;
  if (name.startsWith(".env")) return "settings";
  const dot = name.lastIndexOf(".");
  return (dot > 0 && EXT[name.slice(dot + 1)]) || "file";
}
