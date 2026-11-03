// Pure helpers for tabbed-changes: parsing and argv builders. No Herdr imports, so `node` can test them.

// Reads write nothing under .git (no index refresh or lock, no fsmonitor cookie): the folder
// watch would see it, and every refresh would start the next one.
export const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false", "-c", "core.quotepath=false", "--literal-pathspecs"];
export const WRITE = ["--literal-pathspecs"];
export const CHUNK = 200;
export const LIMIT = 1000;
export const CONFLICTS = new Set(["DD", "AU", "UD", "UA", "DU", "AA", "UU"]);
export const SECTIONS = [
  { id: "conflicts", title: "Merge Changes" },
  { id: "staged", title: "Staged Changes" },
  { id: "changes", title: "Changes" },
];

export const countLines = (text) => text ? text.split("\n").length - Number(text.endsWith("\n")) : 0;
export const tidy = (text) => String(text ?? "").trim().split("\n").slice(-8).join("\n").slice(-500);
export const basename = (p) => p.split(/[\\/]/).pop() ?? p;

// `## main...origin/main [ahead 1, behind 2]`, `## No commits yet on main`, `## HEAD (no branch)`
export function parseBranch(line) {
  const text = line.slice(3);
  for (const prefix of ["No commits yet on ", "Initial commit on "]) {
    if (text.startsWith(prefix)) return { name: text.slice(prefix.length), upstream: null, ahead: 0, behind: 0 };
  }
  if (text.startsWith("HEAD (no branch)")) return { name: "HEAD (detached)", detached: true, upstream: null, ahead: 0, behind: 0 };
  const m = /^(.+?)(?:\.\.\.(\S+?))?(?: \[(.+)\])?$/.exec(text);
  if (!m) return { name: text, upstream: null, ahead: 0, behind: 0 };
  const counts = m[3] ?? "";
  return {
    name: m[1],
    upstream: m[2] && !/gone/.test(counts) ? m[2] : null,
    ahead: Number(/ahead (\d+)/.exec(counts)?.[1] ?? 0),
    behind: Number(/behind (\d+)/.exec(counts)?.[1] ?? 0),
  };
}

// `git diff --numstat -z --no-renames` -> { path: { add, del, binary } }
export function parseNumstat(stdout) {
  const stats = {};
  for (const entry of stdout.split("\0")) {
    const [a, d, ...parts] = entry.split("\t");
    if (!parts.length) continue;
    stats[parts.join("\t")] = { add: Number(a) || 0, del: Number(d) || 0, binary: a === "-" };
  }
  return stats;
}

// `git status --porcelain=v1 -z -b --no-renames --untracked-files=all` -> sections.
export function parseStatus(stdout, cached = {}, worktree = {}) {
  const staged = [], changes = [], conflicts = [];
  let branch = null;
  const entries = stdout.split("\0").filter(Boolean);
  if (entries[0]?.startsWith("## ")) branch = parseBranch(entries.shift());
  const letter = (c) => c === "T" ? "M" : c === "C" ? "A" : c;
  for (const entry of entries.slice(0, LIMIT)) {
    const x = entry[0], y = entry[1], xy = entry.slice(0, 2), path = entry.slice(3);
    if (xy === "??") { changes.push({ path, group: "changes", status: "U", fresh: true, add: 0, del: 0 }); continue; }
    if (CONFLICTS.has(xy)) { conflicts.push({ path, group: "conflicts", status: "!", add: 0, del: 0 }); continue; }
    if (x !== " ") staged.push({ path, group: "staged", status: letter(x), add: 0, del: 0, ...cached[path] });
    if (y !== " ") changes.push({ path, group: "changes", status: letter(y), add: 0, del: 0, ...worktree[path] });
  }
  return { branch, staged, changes, conflicts, limited: entries.length > LIMIT };
}

// Numbers each diff line once, so a frame only draws the rows on screen.
// Rows: { kind: "@" | "+" | "-" | " " | "\\" | "", old?, next?, text }
export function diffRows(lines) {
  let old = 0, next = 0;
  return lines.map((line) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; return { kind: "@", text: line }; }
    if (line.startsWith("@@")) return { kind: "@", text: line };
    const kind = line[0], text = line.slice(1) || " ";
    if (kind === "-") return { kind, old: old++, text };
    if (kind === "+") return { kind, next: next++, text };
    if (kind === " ") return { kind, old: old++, next: next++, text };
    if (kind === "\\") return { kind, text: line };
    return { kind: "", text: line };
  });
}

// Side by side: a block of removed lines followed by added lines is paired by position.
// Rows: { kind: "@", text } | { kind: "c", l: {n, text, kind} | null, r: {...} | null }
export function pairRows(rows) {
  const out = [];
  for (let i = 0; i < rows.length;) {
    const row = rows[i];
    if (row.kind === " ") { out.push({ kind: "c", l: { n: row.old, text: row.text }, r: { n: row.next, text: row.text }, line: row.next }); i++; continue; }
    if (row.kind === "-" || row.kind === "+") {
      const del = [], add = [];
      while (rows[i]?.kind === "-") del.push(rows[i++]);
      while (rows[i]?.kind === "+") add.push(rows[i++]);
      for (let k = 0; k < Math.max(del.length, add.length); k++) {
        const d = del[k], a = add[k];
        out.push({ kind: "c", l: d ? { n: d.old, text: d.text, change: "-" } : null, r: a ? { n: a.next, text: a.text, change: "+" } : null, line: a ? a.next : d.old });
      }
      continue;
    }
    out.push(row); i++;
  }
  return out;
}

// One `git diff` over many files -> [{ path, lines, add, del, binary }]. Renames are off, so a == b.
export function splitPatch(text) {
  const files = [];
  const blocks = text.split(/^diff --git /m).slice(1);
  for (const block of blocks) {
    const lines = block.replace(/\n$/, "").split("\n");
    const head = lines[0], n = (head.length - 5) / 2;
    const path = Number.isInteger(n) && n > 0 ? head.slice(2, 2 + n) : head.replace(/^a\//, "").split(" b/")[0];
    const first = lines.findIndex((l) => l.startsWith("@@"));
    const body = first < 0 ? [] : lines.slice(first);
    const binary = first < 0 && lines.some((l) => l.startsWith("Binary files") || l.startsWith("GIT binary patch"));
    files.push({ path, lines: body, binary, add: body.filter((l) => l[0] === "+").length, del: body.filter((l) => l[0] === "-").length });
  }
  return files;
}

// A new file as an all-added diff.
export function freshLines(text, limit = 1500) {
  const all = text.replace(/\n$/, "").split("\n");
  return [`@@ -0,0 +1,${all.length} @@`, ...all.slice(0, limit).map((l) => `+${l}`)];
}

// The argv that opens `file` at `line` in a terminal editor.
export function editorArgv(editor, file, line) {
  const name = basename(editor);
  if (line && /^(n?vim?|vi|nano|micro|hx|helix|kak)$/.test(name)) {
    if (name === "hx" || name === "helix") return [editor, `${file}:${line}`];
    if (name === "kak") return [editor, `+${line}`, file];
    return [editor, `+${line}`, file];
  }
  return [editor, file];
}

// `git diff -U0` of one file -> { marks: { [line]: "add" | "mod" }, deletedBefore: Set<line> } on the new file's lines.
export function lineMarks(patch) {
  const marks = {}, deletedBefore = new Set();
  for (const line of patch.split("\n")) {
    const m = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/.exec(line);
    if (!m) continue;
    const oldCount = m[2] === undefined ? 1 : +m[2], start = +m[3], count = m[4] === undefined ? 1 : +m[4];
    if (count === 0) { deletedBefore.add(start + 1); continue; }
    for (let i = 0; i < count; i++) marks[start + i] = oldCount === 0 ? "add" : "mod";
  }
  return { marks, deletedBefore };
}
