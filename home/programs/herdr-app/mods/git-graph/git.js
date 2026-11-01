// Git for the graph, with no herdr imports so node can test it: reading the
// history, the labels on each row and where they sit, and the actions behind
// the menus. Commands are argv arrays, never a shell line.

// Reads write nothing under .git (no index refresh or lock, no fsmonitor
// cookie), so the folder watch never wakes for the panel's own reads.
export const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
export const STATUS = ["status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all"];
export const UNCOMMITTED = "*";
const FORMAT = "%x1e%H%x1f%P%x1f%an%x1f%ae%x1f%at%x1f%D%x1f%s";

export function logArgs({ all, remotes, limit }) {
  const scope = all ? [...(remotes ? [] : ["--exclude=refs/remotes/*"]), "--exclude=refs/stash", "--all"] : ["HEAD"];
  return ["log", ...scope, "--date-order", "--decorate=full", `-n${limit}`, `--format=${FORMAT}`];
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
    const [hash, parents, author, email, time, refs, subject] = record.replace(/\n$/, "").split("\x1f");
    const parsed = parseRefs(refs);
    return { hash, parents: parents ? parents.split(" ") : [], author, email, time: Number(time), refs: parsed, subject,
      head: parsed.some((r) => r.head || r.kind === "detached") };
  });
}

// `git status --porcelain=v1 -z --no-renames`: one NUL-terminated "XY path" per file.
export function parseStatus(text) {
  return text.split("\0").filter(Boolean).map((entry) => {
    const xy = entry.slice(0, 2), path = entry.slice(3);
    const status = xy === "??" ? "A" : xy.includes("U") || xy === "AA" || xy === "DD" ? "U" : xy.includes("D") ? "D" : xy.includes("A") ? "A" : "M";
    return { path, status, untracked: xy === "??" };
  });
}

// The working tree's changes as the newest row, drawn dashed to HEAD.
export function withUncommitted(commits, changes, head) {
  if (!changes) return commits;
  return [{ hash: UNCOMMITTED, parents: head ? [head] : [], uncommitted: true, dashed: true, refs: [], head: false,
    subject: `Uncommitted changes (${changes})`, author: "", email: "", time: null }, ...commits];
}

// Labels are drawn at these exact widths (monospace text, fixed padding and
// icon), so a press can be matched to the label under it: a virtual list's
// rows can't hold their own handlers.
export const LABEL = { CHAR: 6.6, PAD: 5, ICON: 13, GAP: 6, MAX: 22, FONT: 11 };
const fit = (s, n) => (s.length > n ? s.slice(0, n - 1) + "…" : s);
const partWidth = (part) => Math.ceil(LABEL.PAD * 2 + (part.icon ? LABEL.ICON : 0) + part.text.length * LABEL.CHAR) + 1;

export function labelsOf(commit, remotesShown = true) {
  const labels = [], remotes = remotesShown ? commit.refs.filter((r) => r.kind === "remote") : [], paired = new Set();
  for (const ref of commit.refs) {
    if (ref.kind === "detached") labels.push({ kind: "head", head: true, parts: [{ kind: "head", name: "HEAD", text: "HEAD" }] });
    if (ref.kind !== "branch") continue;
    // A remote branch with the same name rides on its local branch's label, as in Git Graph.
    const parts = [{ kind: "branch", name: ref.name, text: fit(ref.name, LABEL.MAX), icon: true, head: ref.head }];
    for (const remote of remotes) {
      const slash = remote.name.indexOf("/");
      if (remote.name.slice(slash + 1) !== ref.name || paired.has(remote.name)) continue;
      paired.add(remote.name);
      parts.push({ kind: "remote", name: remote.name, text: fit(remote.name.slice(0, slash), 12) });
    }
    labels.push({ kind: "branch", head: ref.head, parts });
  }
  for (const remote of remotes) if (!paired.has(remote.name)) labels.push({ kind: "remote", parts: [{ kind: "remote", name: remote.name, text: fit(remote.name, LABEL.MAX), icon: true }] });
  for (const ref of commit.refs) if (ref.kind === "tag") labels.push({ kind: "tag", parts: [{ kind: "tag", name: ref.name, text: fit(ref.name, LABEL.MAX), icon: true }] });
  // What's checked out comes first.
  labels.sort((a, b) => Number(Boolean(b.head)) - Number(Boolean(a.head)));
  for (const label of labels) {
    for (const part of label.parts) part.width = partWidth(part);
    label.width = label.parts.reduce((n, p) => n + p.width, 2); // + a 1 px border each side
  }
  return labels;
}

// The label part at `x` in a row whose labels start after a `start`-wide graph
// and are cut off at `limit` (the description column's right edge).
export function hitLabel(labels, x, start, limit = Infinity) {
  if (x >= limit) return null;
  let left = start;
  for (const label of labels ?? []) {
    left += LABEL.GAP;
    if (x >= left && x < left + label.width) {
      let at = left + 1;
      for (const part of label.parts) {
        if (x < at + part.width) return { label, part };
        at += part.width;
      }
      return { label, part: label.parts[label.parts.length - 1] };
    }
    left += label.width;
  }
  return null;
}

const shortHash = (hash) => hash.slice(0, 8);
const currentName = (ctx) => ctx.current ?? "HEAD";
const section = (...items) => items.filter(Boolean);
const item = (label, icon, action) => ({ label, icon, action });

// The right-click menu for a commit, a label part or the uncommitted row:
// Git Graph's menus, minus what needs VS Code. Sections are separated.
export function menuFor(target, ctx) {
  const cur = currentName(ctx), c = target.commit;
  let sections;
  if (target.kind === "uncommitted") {
    sections = [
      section(item("Stash uncommitted changes…", "stash", { type: "stash" })),
      section(item("Reset uncommitted changes…", "reset", { type: "resetUncommitted" })),
      section(item("Show in Changes panel", "mods/changes/changes.svg", { type: "showChanges" })),
    ];
  } else if (target.kind === "branch") {
    const name = target.name, current = name === ctx.current;
    sections = [
      section(!current && item("Checkout branch", "branch", { type: "checkout", name }),
        item("Rename branch…", "rename", { type: "renameBranch", name }),
        !current && item("Delete branch…", "trash", { type: "deleteBranch", name })),
      section(!current && item(`Merge into ${cur}…`, "merge", { type: "merge", ref: name, what: `branch ${name}` }),
        !current && item(`Rebase ${cur} on this branch…`, "rebase", { type: "rebase", ref: name, what: `branch ${name}` })),
      section(ctx.remotes.length > 0 && item("Push branch…", "push", { type: "push", name })),
      section(item("Copy branch name", "copy", { type: "copy", text: name })),
    ];
  } else if (target.kind === "remote") {
    const name = target.name, slash = name.indexOf("/"), remote = name.slice(0, slash), branch = name.slice(slash + 1);
    const local = ctx.branches.includes(branch);
    sections = [
      section(branch !== ctx.current && (local
        ? item(`Checkout ${branch}`, "branch", { type: "checkout", name: branch })
        : item("Checkout branch…", "branch", { type: "checkoutRemote", name, remote, branch }))),
      section(item(`Merge into ${cur}…`, "merge", { type: "merge", ref: name, what: `remote branch ${name}` })),
      section(item("Delete remote branch…", "trash", { type: "deleteRemoteBranch", name, remote, branch })),
      section(item("Copy branch name", "copy", { type: "copy", text: name })),
    ];
  } else if (target.kind === "tag") {
    const name = target.name;
    sections = [
      section(item("Delete tag…", "trash", { type: "deleteTag", name })),
      section(ctx.remotes.length > 0 && item("Push tag…", "push", { type: "pushTag", name })),
      section(item("Copy tag name", "copy", { type: "copy", text: name })),
    ];
  } else {
    const hash = c.hash, short = shortHash(hash), here = hash === ctx.head, merge = c.parents.length > 1;
    sections = [
      section(item("Add tag…", "tag", { type: "addTag", hash, short }),
        item("Create branch…", "plus", { type: "createBranch", hash, short })),
      section(!here && item("Checkout…", "commit", { type: "checkoutCommit", hash, short }),
        !here && item("Cherry pick…", "cherry", { type: "cherryPick", hash, short, merge }),
        item("Revert…", "revert", { type: "revert", hash, short, merge })),
      section(!here && item(`Merge into ${cur}…`, "merge", { type: "merge", ref: hash, what: `commit ${short}` }),
        !here && item(`Rebase ${cur} on this commit…`, "rebase", { type: "rebase", ref: hash, what: `commit ${short}` }),
        item(`Reset ${cur} to this commit…`, "reset", { type: "reset", hash, short })),
      section(item("Copy commit hash", "copy", { type: "copy", text: hash }),
        item("Copy commit subject", "copy", { type: "copy", text: c.subject })),
    ];
  }
  const out = [];
  for (const s of sections.filter((s) => s.length)) { if (out.length) out.push({ separator: true }); out.push(...s); }
  return out;
}

export const menuHeight = (items) => 10 + items.reduce((n, i) => n + (i.separator ? 9 : 30), 0);

const remoteChoice = (ctx) => ({ id: "remote", label: "Remote", value: ctx.remotes.includes("origin") ? "origin" : ctx.remotes[0],
  options: ctx.remotes.map((r) => ({ value: r, label: r })) });
const mergeNote = (a) => (a.merge ? " It's a merge commit: its changes against its first parent are used." : "");

// The dialog an action asks first, or null when it runs at once.
export function dialogFor(action, ctx) {
  const cur = currentName(ctx), a = action;
  switch (a.type) {
    case "checkoutRemote": return { title: "Checkout remote branch", detail: `Create a local branch that tracks ${a.name}, and check it out.`,
      inputs: [{ id: "name", label: "Local branch name", value: a.branch }], confirm: "Checkout" };
    case "checkoutCommit": return { title: "Checkout commit", detail: `Check out commit ${a.short}? You'll be on a detached HEAD: new commits belong to no branch until you create one.`, confirm: "Checkout" };
    case "createBranch": return { title: "Create branch", detail: `At commit ${a.short}.`,
      inputs: [{ id: "name", label: "Branch name", value: "" }], checks: [{ id: "checkout", label: "Check out the new branch", value: false }], confirm: "Create" };
    case "addTag": return { title: "Add tag", detail: `At commit ${a.short}.`,
      inputs: [{ id: "name", label: "Tag name", value: "" }, { id: "message", label: "Message (makes an annotated tag)", value: "", optional: true }], confirm: "Add tag" };
    case "renameBranch": return { title: "Rename branch", detail: `Rename ${a.name}.`, inputs: [{ id: "name", label: "New name", value: a.name }], confirm: "Rename" };
    case "deleteBranch": return { title: "Delete branch", detail: `Delete the local branch ${a.name}?`,
      checks: [{ id: "force", label: "Force delete, even if it isn't merged", value: false }], confirm: "Delete", danger: true };
    case "deleteRemoteBranch": return { title: "Delete remote branch", detail: `Delete ${a.branch} on ${a.remote}? This changes the remote for everyone who uses it.`, confirm: "Delete", danger: true };
    case "deleteTag": return { title: "Delete tag", detail: `Delete the local tag ${a.name}?`, confirm: "Delete", danger: true };
    case "merge": return { title: "Merge", detail: `Merge ${a.what} into ${cur}?`,
      checks: [{ id: "noff", label: "Create a merge commit even if it could fast-forward", value: false }], confirm: "Merge" };
    case "rebase": return { title: "Rebase", detail: `Rebase ${cur} on ${a.what}?`, confirm: "Rebase" };
    case "cherryPick": return { title: "Cherry pick", detail: `Apply commit ${a.short} on top of ${cur}?${mergeNote(a)}`, confirm: "Cherry pick" };
    case "revert": return { title: "Revert", detail: `Add a commit to ${cur} that undoes ${a.short}?${mergeNote(a)}`, confirm: "Revert" };
    case "reset": return { title: "Reset", detail: `Move ${cur} to commit ${a.short}.`, confirm: "Reset",
      choice: { id: "mode", label: "Mode", value: "mixed", options: [
        { value: "soft", label: "Soft", detail: "Keep every change, staged" },
        { value: "mixed", label: "Mixed", detail: "Keep every change, unstaged" },
        { value: "hard", label: "Hard", detail: "Discard every change", danger: true }] } };
    case "push": return { title: "Push branch", detail: `Push ${a.name}.`, choice: remoteChoice(ctx),
      checks: [{ id: "upstream", label: "Set as upstream", value: true }], confirm: "Push" };
    case "pushTag": return { title: "Push tag", detail: `Push the tag ${a.name}.`, choice: remoteChoice(ctx), confirm: "Push" };
    case "stash": return { title: "Stash uncommitted changes", inputs: [{ id: "message", label: "Message", value: "", optional: true }],
      checks: [{ id: "untracked", label: "Include untracked files", value: true }], confirm: "Stash" };
    case "resetUncommitted": return { title: "Reset uncommitted changes", detail: "Reset the working tree to HEAD.", confirm: "Reset",
      choice: { id: "mode", label: "Mode", value: "mixed", options: [
        { value: "mixed", label: "Mixed", detail: "Unstage everything, keep the changes" },
        { value: "hard", label: "Hard", detail: "Discard every change to tracked files", danger: true }] } };
    default: return null;
  }
}

export function dialogHeight(spec) {
  const detail = spec.detail ? Math.ceil(spec.detail.length / 52) * 19 + 8 : 0;
  return Math.ceil(36 + 26 + detail + (spec.inputs ?? []).length * 66 + (spec.checks ?? []).length * 30
    + (spec.choice ? 24 + spec.choice.options.length * 42 : 0) + 30 + 52);
}

const values = (spec) => {
  const v = {};
  for (const i of spec?.inputs ?? []) v[i.id] = i.value ?? "";
  for (const c of spec?.checks ?? []) v[c.id] = c.value;
  if (spec?.choice) v[spec.choice.id] = spec.choice.value;
  return v;
};
export const initialValues = (action, ctx) => values(dialogFor(action, ctx));

// What's wrong with the typed values, or null. A name never reaches git as an option.
export function validate(action, v, ctx) {
  const spec = dialogFor(action, ctx);
  for (const input of spec?.inputs ?? []) {
    const text = String(v[input.id] ?? "").trim();
    if (input.optional) continue;
    if (!text) return `${input.label} is empty.`;
    if (text.startsWith("-") || /\s/.test(text)) return `${input.label} can't start with "-" or contain spaces.`;
  }
  if (spec?.choice && !spec.choice.options.some((o) => o.value === v[spec.choice.id])) return `Pick a ${spec.choice.label.toLowerCase()}.`;
  return null;
}

// The git commands an action runs, in order.
export function commandsFor(a, v = {}, ctx = {}) {
  const name = String(v.name ?? "").trim(), message = String(v.message ?? "").trim();
  switch (a.type) {
    case "checkout": return [["checkout", a.name]];
    case "checkoutRemote": return [["checkout", "-b", name, "--track", a.name]];
    case "checkoutCommit": return [["checkout", "--detach", a.hash]];
    case "createBranch": return [v.checkout ? ["checkout", "-b", name, a.hash] : ["branch", name, a.hash]];
    case "addTag": return [message ? ["tag", "-a", name, "-m", message, a.hash] : ["tag", name, a.hash]];
    case "renameBranch": return [["branch", "-m", a.name, name]];
    case "deleteBranch": return [["branch", v.force ? "-D" : "-d", a.name]];
    case "deleteRemoteBranch": return [["push", a.remote, "--delete", a.branch]];
    case "deleteTag": return [["tag", "-d", a.name]];
    case "merge": return [["merge", "--no-edit", ...(v.noff ? ["--no-ff"] : []), a.ref]];
    case "rebase": return [["rebase", a.ref]];
    case "cherryPick": return [["cherry-pick", ...(a.merge ? ["-m", "1"] : []), a.hash]];
    case "revert": return [["revert", "--no-edit", ...(a.merge ? ["-m", "1"] : []), a.hash]];
    case "reset": return [["reset", `--${v.mode}`, a.hash]];
    case "push": return [["push", ...(v.upstream ? ["--set-upstream"] : []), v.remote, a.name]];
    case "pushTag": return [["push", v.remote, `refs/tags/${a.name}`]];
    case "stash": return [["stash", "push", ...(v.untracked ? ["--include-untracked"] : []), ...(message ? ["-m", message] : [])]];
    case "resetUncommitted": return [["reset", `--${v.mode}`, "HEAD"]];
    case "fetch": return [["fetch", "--all"]];
    default: return [];
  }
}

export function doneText(a, v = {}) {
  const name = String(v.name ?? "").trim();
  switch (a.type) {
    case "checkout": return `Checked out ${a.name}`;
    case "checkoutRemote": return `Checked out ${name}, tracking ${a.name}`;
    case "checkoutCommit": return `Checked out ${a.short}`;
    case "createBranch": return `Created branch ${name}`;
    case "addTag": return `Tagged ${a.short} as ${name}`;
    case "renameBranch": return `Renamed ${a.name} to ${name}`;
    case "deleteBranch": return `Deleted branch ${a.name}`;
    case "deleteRemoteBranch": return `Deleted ${a.name}`;
    case "deleteTag": return `Deleted tag ${a.name}`;
    case "merge": return `Merged ${a.what}`;
    case "rebase": return `Rebased on ${a.what}`;
    case "cherryPick": return `Cherry-picked ${a.short}`;
    case "revert": return `Reverted ${a.short}`;
    case "reset": return `Reset to ${a.short} (${v.mode})`;
    case "push": return `Pushed ${a.name} to ${v.remote}`;
    case "pushTag": return `Pushed tag ${a.name} to ${v.remote}`;
    case "stash": return "Stashed uncommitted changes";
    case "resetUncommitted": return `Reset uncommitted changes (${v.mode})`;
    case "fetch": return "Fetched";
    default: return "Done";
  }
}

// Git's own words, without its hints.
export function gitError(result) {
  const lines = (result.stderr || result.stdout || "").split("\n").map((l) => l.trimEnd()).filter((l) => l && !l.startsWith("hint:"));
  return lines.slice(-6).join("\n") || `git exited with ${result.code}`;
}

// The files a commit changed against its first parent, joined from
// --name-status and --numstat (renames off, so the paths match).
export function fileArgs(commit) {
  const range = commit.parents.length ? [commit.parents[0], commit.hash] : null;
  const base = range ? ["diff", "--no-renames", "--no-ext-diff", ...range] : ["diff-tree", "--root", "--no-commit-id", "-r", "--no-renames", commit.hash];
  return { status: [...base, "--name-status"], numstat: [...base, "--numstat"] };
}

export function joinFiles(statusText, numstatText) {
  const stats = new Map();
  for (const line of numstatText.split("\n").filter(Boolean)) {
    const [a, d, ...path] = line.split("\t");
    stats.set(path.join("\t"), { add: Number(a) || 0, del: Number(d) || 0, binary: a === "-" });
  }
  return statusText.split("\n").filter(Boolean).map((line) => {
    const [s, ...path] = line.split("\t"), p = path.join("\t");
    return { path: p, status: s[0], ...(stats.get(p) ?? { add: 0, del: 0 }) };
  });
}

export function diffArgs(commit, path) {
  const opts = ["--no-color", "--no-ext-diff", "--no-textconv"];
  if (commit.uncommitted) return ["diff", ...opts, "HEAD", "--", path];
  if (!commit.parents.length) return ["show", ...opts, "--format=", commit.hash, "--", path];
  return ["diff", ...opts, commit.parents[0], commit.hash, "--", path];
}

// Numbers each diff line once, so a frame only draws the rows on screen.
export function diffRows(text) {
  const all = text.replace(/\n$/, "").split("\n"), first = all.findIndex((l) => l.startsWith("@@"));
  if (first < 0) return null;
  let old = 0, next = 0;
  return all.slice(first, first + 3000).map((raw) => {
    const line = raw.length > 2000 ? raw.slice(0, 2000) + "…" : raw;
    const m = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (m) { old = +m[1]; next = +m[2]; return { kind: "@", text: line }; }
    const kind = line[0];
    if (kind === "-") return { kind, number: old++, text: line.slice(1) || " " };
    if (kind === "+") return { kind, number: next++, text: line.slice(1) || " " };
    if (kind === " ") { old++; return { kind, number: next++, text: line.slice(1) || " " }; }
    return { kind: "", text: line };
  });
}
