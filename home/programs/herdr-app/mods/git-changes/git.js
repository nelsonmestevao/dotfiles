// Git for the Changes panel, with no herdr imports so node can test it:
// parsing status, numstat, stashes, history and diffs, and the argv behind
// every button and menu item. Commands are argv arrays, never a shell line.
//
// Borrowed: READ (from Herdr's shipped `changes` mod, Apache-2.0); parseRefs(),
// historyArgs()'s scope, withUncommitted(), gitError() and the remote pairing in
// labelsOf() follow herdr-git-graph's mods/git-graph/git.js
// (https://github.com/rabeeh-ta/herdr-git-graph, MIT, Copyright (c) 2026 Rabeeh T A).

// Reads write nothing under .git (no index refresh or lock, no fsmonitor
// cookie): the folder watch would see it, and every refresh would start the next one.
export const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
export const STATUS = ["status", "--porcelain=v2", "--branch", "-z", "--no-renames", "--untracked-files=all"];
export const NUMSTAT = ["--numstat", "-z", "--no-renames"];
export const STASHES = ["stash", "list", "--format=%gd%x1f%s%x1f%cr"];
// History for the graph: every branch (stashes left out) or HEAD only, newest first with
// every child before its parents, as lanes.js needs; refs in full so their kind is known.
// Without remotes, the branch's upstream still shows: what a pull would bring in.
export function historyArgs({ all, remotes = true, upstream, limit }) {
  const scope = !all ? ["HEAD"] : remotes ? ["--exclude=refs/stash", "--all"]
    : ["--exclude=refs/remotes/*", "--exclude=refs/stash", "--all", ...(upstream ? [`refs/remotes/${upstream}`] : [])];
  return ["log", ...scope, "--date-order", "--decorate=full", `-n${limit}`,
    "--format=%x1e%H%x1f%h%x1f%P%x1f%s%x1f%an%x1f%at%x1f%D"];
}
const DIFF = ["--no-ext-diff", "--no-textconv", "--no-color"];
export const LIMIT = 1000;

const letter = (c) => (c === "T" ? "M" : c === "C" || c === "R" ? "A" : c);

// `git status --porcelain=v2 --branch -z`: the branch, then one entry per path.
// `staged` is how much of it is in the index: "all", "some" or "none", as Zed's checkbox shows it.
export function parseStatus(text) {
  const branch = { head: null, oid: null, upstream: null, ahead: 0, behind: 0, detached: false };
  const entries = [];
  const tokens = text.split("\0");
  for (let i = 0; i < tokens.length; i++) {
    const entry = tokens[i];
    if (!entry) continue;
    if (entry.startsWith("# ")) {
      const [, field, ...rest] = entry.split(" "), value = rest.join(" ");
      if (field === "branch.oid") branch.oid = value === "(initial)" ? null : value;
      else if (field === "branch.head") { branch.detached = value === "(detached)"; branch.head = branch.detached ? null : value; }
      else if (field === "branch.upstream") branch.upstream = value;
      else if (field === "branch.ab") { const m = /^\+(\d+) -(\d+)$/.exec(value); if (m) { branch.ahead = +m[1]; branch.behind = +m[2]; } }
      continue;
    }
    const kind = entry[0], parts = entry.split(" ");
    if (kind === "?") { entries.push({ path: entry.slice(2), status: "A", staged: "none", untracked: true }); continue; }
    if (kind === "u") { entries.push({ path: parts.slice(10).join(" "), status: "U", staged: "none", conflict: true }); continue; }
    if (kind !== "1" && kind !== "2") continue;
    const path = parts.slice(kind === "1" ? 8 : 9).join(" ");
    if (kind === "2") i++; // a rename's original path (only without --no-renames)
    const [x, y] = parts[1];
    // A submodule's state is "S<commit><modified><untracked>", e.g. "S..U".
    const sub = parts[2][0] === "S" ? [parts[2][1] === "C" && "new commits", parts[2][2] === "M" && "modified content", parts[2][3] === "U" && "untracked content"].filter(Boolean) : null;
    entries.push({
      path, status: letter(x === "A" || y === "." ? x : y),
      staged: x === "." ? "none" : y === "." ? "all" : "some",
      ...(sub ? { submodule: sub.join(", ") || "changed" } : {}),
    });
  }
  return { branch, entries };
}

// `git diff --numstat -z --no-renames`: "add\tdel\tpath\0" per file. Several outputs add up.
export function parseNumstat(...texts) {
  const stats = {};
  for (const text of texts) for (const entry of text.split("\0")) {
    const [a, d, ...parts] = entry.split("\t");
    if (!parts.length) continue;
    const path = parts.join("\t"), old = stats[path] ?? { add: 0, del: 0 };
    stats[path] = { add: old.add + (Number(a) || 0), del: old.del + (Number(d) || 0), binary: a === "-" };
  }
  return stats;
}

export function parseStashes(text) {
  return text.split("\n").filter(Boolean).map((line) => {
    const [ref, subject, when] = line.split("\x1f");
    return { ref, subject: (subject ?? "").replace(/^On [^:]+: /, ""), when: when ?? "" };
  });
}

export function parseRefs(text) {
  const refs = [];
  for (let name of text ? text.split(", ") : []) {
    const head = name.startsWith("HEAD -> ");
    if (head) name = name.slice(8);
    if (name === "HEAD") refs.push({ kind: "detached", name: "HEAD" });
    else if (name.startsWith("refs/heads/")) refs.push({ kind: "branch", name: name.slice(11), head });
    else if (name.startsWith("tag: refs/tags/")) refs.push({ kind: "tag", name: name.slice(15) });
    else if (name.startsWith("refs/remotes/") && !name.endsWith("/HEAD")) refs.push({ kind: "remote", name: name.slice(13) });
  }
  return refs;
}

export function parseLog(text) {
  return text.split("\x1e").filter((r) => r.trim()).map((record) => {
    const [hash, short, parents, subject, author, time, refs] = record.replace(/\n$/, "").split("\x1f");
    const parsed = parseRefs(refs);
    return { hash, short, parents: parents ? parents.split(" ") : [], subject, author, time: Number(time), when: ago(Number(time)),
      refs: parsed, head: parsed.some((r) => r.head || r.kind === "detached") };
  });
}

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
export function ago(seconds) {
  const s = Date.now() / 1000 - seconds;
  if (s < 60) return "now";
  if (s < 3600) return `${Math.round(s / 60)}m`;
  if (s < 86400) return `${Math.round(s / 3600)}h`;
  if (s < 86400 * 30) return `${Math.round(s / 86400)}d`;
  const d = new Date(seconds * 1000);
  return d.getFullYear() === new Date().getFullYear() ? `${MONTHS[d.getMonth()]} ${d.getDate()}` : `${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

// The labels a row shows: what's checked out first; a remote branch with the same
// name rides on its local one (a cloud mark), as in Git Graph.
// `remoteShown(name)` says which remote branches get labels of their own.
export function labelsOf(commit, remoteShown = () => true) {
  const out = [], remotes = commit.refs.filter((r) => r.kind === "remote"), paired = new Set();
  for (const r of commit.refs) {
    if (r.kind === "detached") out.push({ kind: "head", text: "HEAD", head: true });
    if (r.kind !== "branch") continue;
    const twin = remotes.find((x) => x.name.slice(x.name.indexOf("/") + 1) === r.name);
    if (twin) paired.add(twin.name);
    out.push({ kind: "branch", text: r.name, name: r.name, head: r.head, synced: Boolean(twin) });
  }
  for (const r of remotes) if (!paired.has(r.name) && remoteShown(r.name)) out.push({ kind: "remote", text: r.name, name: r.name });
  for (const r of commit.refs) if (r.kind === "tag") out.push({ kind: "tag", text: r.name, name: r.name });
  return out.sort((a, b) => Number(Boolean(b.head)) - Number(Boolean(a.head)));
}

// The working tree as the newest row, drawn dashed to HEAD, as the graph does.
export const UNCOMMITTED = "*";
export function withUncommitted(commits, changes, head) {
  if (!changes) return commits;
  return [{ hash: UNCOMMITTED, uncommitted: true, dashed: true, parents: head ? [head] : [], refs: [], head: false,
    subject: `Uncommitted changes (${changes})`, author: "", time: null, when: "" }, ...commits];
}

export const countLines = (text) => (text ? text.split("\n").length - Number(text.endsWith("\n")) : 0);

// One row per diff line, numbered once, so a frame draws only what's on screen.
// File headers become one "f" row each (dropped when there's a single file, unless `headers`).
export function diffRows(lines, { headers = false } = {}) {
  const rows = [];
  let old = 0, next = 0, header = false, files = 0;
  for (const line of lines) {
    if (line.startsWith("diff --git ") || line.startsWith("diff --cc ") || line.startsWith("diff --combined ")) {
      const m = / b\/(.*)$/.exec(line) ?? /^diff --(?:cc|combined) (.*)$/.exec(line);
      rows.push({ kind: "f", text: m ? m[1] : line });
      header = true; files++;
      continue;
    }
    const hunk = /^@@+ -(\d+)(?:,\d+)?(?: -\d+(?:,\d+)?)* \+(\d+)/.exec(line);
    if (hunk) { old = +hunk[1]; next = +hunk[2]; header = false; rows.push({ kind: "@", text: line }); continue; }
    if (header) {
      if (line.startsWith("Binary files")) rows.push({ kind: "", text: "Binary file changed" });
      else if (line.startsWith("Subproject commit") || line.startsWith("-Subproject") || line.startsWith("+Subproject")) rows.push({ kind: line[0] === "-" ? "-" : line[0] === "+" ? "+" : "", text: line.replace(/^[-+]/, "") });
      continue;
    }
    const kind = line[0];
    if (kind === "-") rows.push({ kind, number: old++, text: line.slice(1) || " " });
    else if (kind === "+") rows.push({ kind, number: next++, text: line.slice(1) || " " });
    else if (kind === " ") rows.push({ kind, old: old++, number: next++, text: line.slice(1) || " " });
    else if (line) rows.push({ kind: "", text: line });
  }
  return files > 1 || headers ? rows : rows.filter((r) => r.kind !== "f");
}

// What a selection shows: a file against HEAD, a stash, a commit, or everything.
export function diffArgs(item, hasHead) {
  if (item.area === "stash") return [["stash", "show", "-p", "--include-untracked", ...DIFF, item.ref]];
  if (item.area === "commit") return [["show", "--format=", "-p", "--diff-merges=first-parent", ...DIFF, item.hash]];
  const path = item.area === "all" ? [] : ["--", item.path];
  return hasHead ? [["diff", "HEAD", ...DIFF, ...path]] : [["diff", "--cached", ...DIFF, ...path], ["diff", ...DIFF, ...path]];
}

// Zed's placeholder: one changed file names the commit for you.
export function suggestMessage(entries) {
  if (entries.length !== 1) return "";
  const e = entries[0], name = e.path.split("/").pop();
  return `${e.status === "A" ? "Create" : e.status === "D" ? "Delete" : "Update"} ${name}`;
}

// --- what the buttons run ---------------------------------------------------

const unstage = (paths, hasHead) => (hasHead ? ["restore", "--staged", "--", ...paths] : ["rm", "--cached", "-q", "-r", "--", ...paths]);

// The checkbox: fully staged unstages, anything else stages the whole file.
export const toggleArgs = (e, hasHead) => [e.staged === "all" ? unstage([e.path], hasHead) : ["add", "-A", "--", e.path]];
export const stageAllArgs = () => [["add", "-A"]];
export const unstageAllArgs = (hasHead) => [hasHead ? ["reset", "-q"] : ["rm", "-r", "--cached", "-q", "."]];
// Back to HEAD, index and worktree; a file HEAD never had is removed.
export function discardArgs(e, hasHead) {
  if (e.untracked) return [["clean", "-f", "-q", "--", e.path]];
  if (!hasHead || (e.status === "A" && e.staged !== "none")) return [["rm", "-f", "-q", "-r", "--", e.path]];
  return [["restore", "--source=HEAD", "--staged", "--worktree", "--", e.path]];
}
export const discardTrackedArgs = (hasHead) => (hasHead ? [["reset", "-q", "--hard", "HEAD"]] : [["rm", "-r", "-f", "-q", "--cached", "."]]);
export const trashUntrackedArgs = () => [["clean", "-f", "-d", "-q"]];

// Zed's "Commit" when something is staged, "Commit Tracked" (git commit -a) when not.
// With nothing staged or tracked, only an amend can go ahead.
export function commitMode(entries) {
  if (entries.some((e) => e.conflict)) return "conflict";
  if (entries.some((e) => e.staged !== "none")) return "staged";
  if (entries.some((e) => !e.untracked)) return "tracked";
  return "none";
}

export function commitArgs({ message, amend, signoff, mode }) {
  const text = message.trim();
  if (mode === "conflict") return { error: "Resolve the merge conflicts first (stage each file when it's fixed)" };
  if (!text && !amend) return { error: "Write a commit message" };
  if (!amend && mode === "none") return { error: "Nothing staged or tracked to commit: stage the files first" };
  return { cmds: [["commit", ...(mode === "tracked" ? ["-a"] : []), ...(amend ? ["--amend"] : []), ...(signoff ? ["--signoff"] : []), ...(text ? ["-m", text] : ["--no-edit"])]] };
}

// Pushes to the upstream; a branch without one is published to origin (or the only remote).
export function pushArgs(branch, remotes, { force } = {}) {
  if (branch.detached || !branch.head) return { error: "Check out a branch to push" };
  const lease = force ? ["--force-with-lease"] : [];
  if (branch.upstream) return { cmds: [["push", ...lease]] };
  const remote = remotes.includes("origin") ? "origin" : remotes[0];
  if (!remote) return { error: "This repository has no remote" };
  return { cmds: [["push", ...lease, "--set-upstream", remote, branch.head]], remote };
}

export function pullArgs(branch, { rebase } = {}) {
  if (!branch.upstream) return { error: "This branch has no upstream to pull from" };
  return { cmds: [["pull", rebase ? "--rebase" : "--ff-only"]] };
}

// The main remote button, as Zed picks it: pull when behind, push when ahead, publish a new branch, else fetch.
export function remoteAction(branch, remotes, hasHead) {
  if (!branch || !remotes.length) return null;
  if (branch.upstream && branch.behind > 0) return { type: "pull", label: "Pull", count: `↓${branch.behind}` };
  if (branch.upstream && branch.ahead > 0) return { type: "push", label: "Push", count: `↑${branch.ahead}` };
  if (!branch.upstream && !branch.detached && hasHead) return { type: "push", label: "Publish" };
  return { type: "fetch", label: "Fetch" };
}

export const fetchArgs = () => [["fetch", "--prune"]];
export const stashPushArgs = (message, { staged } = {}) => [["stash", "push", ...(staged ? ["--staged"] : ["--include-untracked"]), ...(message.trim() ? ["-m", message.trim()] : [])]];
export const stashArgs = (op, ref) => [["stash", op, ref]];
// Undoes the last commit and keeps its changes staged; the root commit leaves an unborn branch.
export const uncommitArgs = (hasParent) => [hasParent ? ["reset", "-q", "--soft", "HEAD~1"] : ["update-ref", "-d", "HEAD"]];
export const checkoutArgs = (name) => [["switch", name]];
export const checkoutRemoteArgs = (remote) => [["switch", "--track", remote]];
export const detachArgs = (hash) => [["switch", "--detach", hash]];
export const revertArgs = (hash) => [["revert", "--no-edit", hash]];
export const BRANCHES = ["for-each-ref", "--sort=-committerdate", "--count=30", "--format=%(refname:short)", "refs/heads"];

// Git's own words, without its hints.
export function gitError(result) {
  const lines = (result.stderr || result.stdout || "").split("\n").map((l) => l.trimEnd()).filter((l) => l && !l.startsWith("hint:"));
  return lines.slice(-6).join("\n") || `git exited with ${result.code}`;
}

// --- list and diff shapes -----------------------------------------------------

// The changed files as a tree: folders first, sorted; a folder holding a single
// folder and nothing else is merged into it ("src/ui"), as Zed and VS Code do.
// `closed` holds folder paths whose children are hidden. Rows are
// { kind: "folder", name, path, depth, files } or { kind: "file", entry, depth }.
export function fileTree(entries, closed = new Set()) {
  const root = { dirs: new Map(), files: [] };
  for (const entry of entries) {
    const parts = entry.path.split("/");
    parts.pop();
    let node = root, path = "";
    for (const part of parts) {
      path = path ? `${path}/${part}` : part;
      if (!node.dirs.has(part)) node.dirs.set(part, { name: part, path, dirs: new Map(), files: [] });
      node = node.dirs.get(part);
    }
    node.files.push(entry);
  }
  const count = (node) => node.files.length + [...node.dirs.values()].reduce((n, d) => n + count(d), 0);
  const rows = [];
  const walk = (node, depth) => {
    for (const dir of [...node.dirs.values()].sort((a, b) => a.name.localeCompare(b.name))) {
      let d = dir, name = dir.name;
      while (d.files.length === 0 && d.dirs.size === 1) { d = [...d.dirs.values()][0]; name = `${name}/${d.name}`; }
      rows.push({ kind: "folder", name, path: d.path, depth, files: count(d) });
      if (!closed.has(d.path)) walk(d, depth + 1);
    }
    for (const entry of [...node.files].sort((a, b) => a.path.localeCompare(b.path))) rows.push({ kind: "file", entry, depth });
  };
  walk(root, 0);
  return rows;
}

// Unified rows as two columns. Removed and added lines next to each other are
// paired by position, never across a hunk or a context line; a side with
// nothing opposite gets an empty cell. Headers span both columns.
export function splitRows(rows) {
  const out = [], removed = [], added = [];
  const flush = () => {
    for (let i = 0; i < Math.max(removed.length, added.length); i++) out.push({ kind: "pair", left: removed[i] ?? null, right: added[i] ?? null });
    removed.length = 0; added.length = 0;
  };
  for (const row of rows) {
    if (row.kind === "-") removed.push(row);
    else if (row.kind === "+") added.push(row);
    else { flush(); out.push(row.kind === " " ? { kind: "pair", left: row, right: row } : row); }
  }
  flush();
  return out;
}
