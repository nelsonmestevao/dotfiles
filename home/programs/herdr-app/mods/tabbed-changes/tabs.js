// Opening things in tabs: the reusable "preview" diff tab (VS Code's single-click behaviour),
// pinned diff tabs (double-click), read-only file tabs, and terminal-editor (Neovim) tabs.
import { run, spaces, shared, setShared } from "herdr";
import { basename, editorArgv } from "./git.js";

export const MOD = "tabbed-changes";
export const VIEW_KEY = "tabbed-changes.view";   // { [spaceId]: { view, tab, at } } -> what the preview diff tab shows
export const EDITOR_KEY = "tabbed-changes.editor"; // shared override, e.g. "nvim", "/opt/homebrew/bin/hx"

export const activeSpace = () => spaces().find((s) => s.active);
const tabIds = (spaceId) => new Set(spaces().find((s) => s.id === spaceId)?.tabs.map((t) => t.id) ?? []);

// `run` returns nothing, so find the tab it made by what appeared in the space.
function newTab(spaceId, args) {
  const before = tabIds(spaceId);
  run("tab.new", { space: spaceId, ...args });
  return [...tabIds(spaceId)].find((id) => !before.has(id)) ?? null;
}

// A view is { source: { root, on }, mode: "file" | "all", file?: { group, path, status, fresh } }.
export function previewView(spaceId) { return shared(VIEW_KEY)?.[spaceId]?.view ?? null; }

// Single click: show `view` in the space's one reusable diff tab, making it if it is gone.
// `pinned`: a tab of its own that nothing else reuses.
export function showDiff(view, { pinned = false, select = true } = {}) {
  const space = activeSpace();
  if (!space) return;
  const name = pinned && view.mode === "file" && view.file?.path
    ? `Changes · ${basename(view.file.path)}` : "Changes";
  if (pinned) {
    newTab(space.id, { name, mod: MOD, props: { role: "diff", pinned: true, view } });
    return;
  }
  const all = { ...(shared(VIEW_KEY) ?? {}) };
  const entry = all[space.id];
  const live = entry?.tab && space.tabs.find((t) => t.id === entry.tab);
  all[space.id] = { view, tab: live ? live.id : null, at: Date.now() };
  setShared(VIEW_KEY, all);
  if (live) {
    run("tab.rename", { id: live.id, name });
    if (select) run("tab.select", { id: live.id });
    return;
  }
  const id = newTab(space.id, { name, mod: MOD, props: { role: "diff", space: space.id } });
  if (id) setShared(VIEW_KEY, { ...(shared(VIEW_KEY) ?? {}), [space.id]: { view, tab: id, at: all[space.id].at } });
}

// Keeps the preview tab's view current without stealing focus (staging moved the file, say).
export function updatePreview(view) {
  const space = activeSpace(), entry = space && shared(VIEW_KEY)?.[space.id];
  if (!entry) return;
  setShared(VIEW_KEY, { ...shared(VIEW_KEY), [space.id]: { ...entry, view } });
}

// A read-only tab on one file.
export function openFileTab(source, path, line) {
  const space = activeSpace();
  if (!space) return;
  run("tab.new", { name: basename(path), space: space.id, mod: MOD, props: { role: "file", file: path, root: source.root, on: source.on ?? null, line: line ?? null } });
}

// The terminal editor: the shared override, else Neovim (it brings its own LSP).
const editorName = () => {
  const forced = shared(EDITOR_KEY);
  return typeof forced === "string" && forced.trim() ? forced.trim() : "nvim";
};

// Opens `path` (absolute) at `line` in a new tab running the editor. No install check up front:
// if the editor is missing the tab prints why and exits non-zero, which Herdr shows as an error toast.
export function openInEditor(_cx, source, path, line) {
  const space = activeSpace();
  if (!space) return;
  const editor = editorName(), argv = editorArgv(editor, path, line);
  const script = `command -v "$1" >/dev/null 2>&1 || { printf '%s\\n' "$1 is not installed (or not on PATH). Install it, or set shared key tabbed-changes.editor to another editor."; exit 127; }; exec "$@"`;
  run("tab.new", { name: basename(path), space: space.id, folder: source.root, argv: ["sh", "-c", script, "sh", ...argv] });
}
