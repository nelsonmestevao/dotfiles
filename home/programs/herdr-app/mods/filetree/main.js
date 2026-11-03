// filetree: an IDE-style file tree for any Herdr layout. A port of claude-code-filetree
// (MIT, Kurt Buhler): git status with line and file counts, a branch row, search across
// unopened folders, date or size column, keyboard navigation, previews, and Claude's reads,
// writes and git actions shimmering in the tree (fed by mods/filetree/bridge.ts).
// Layout-neutral: colors come from theme(), corners and header height from the shown
// layout's pane frame, fonts from settings().
import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState, InputState, Input, Scrollbar, v_virtual_list, VirtualListScrollHandle, TextView } from "gpui-base";
import ICONS from "./icons.js"; // copied from the file-icons mod (mods cannot import across folders)
import { spaces, panes, agents, focused, exec, readTextFile, watchFolder, theme, settings, window, layout, home, appHome, props, run, notify, openOverlay, closeOverlay, shared, setShared } from "herdr";

const NAME = "filetree";
const ICON = (name) => `mods/${NAME}/${name}.svg`;
const ROW = 26;
const PER_FOLDER = 2000;
const FIND_LIMIT = 200;
const FLASH_MS = 2700, TINT_MS = 45000, RUNNING_MS = 600000, CHIP_MS = 45000;
const READ_REVEAL = 12, SEARCH_REVEAL = 60;
const PRUNE = [".git", "node_modules", "target", ".venv", "__pycache__", "dist", ".next"];
const HOME_PRUNE = ["Library", "AppData", ".Trash"];
const DEFAULTS = { activity: "reads and writes", follow: true, column: "date", open: "preview" };
// Reads write nothing under .git (no index refresh or lock, no fsmonitor cookie): the folder
// watch would see it, and every refresh would start the next one.
const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
const LANG = { ts: "js", tsx: "js", mts: "js", cts: "js", jsx: "js", mjs: "js", cjs: "js", toml: "yaml", yml: "yaml", jsonc: "json", svelte: "html", vue: "html", htm: "html", sh: "bash", zsh: "bash" };
const RANK = { "?": 1, A: 2, C: 2, R: 3, T: 3, M: 3, D: 4, U: 5 };
// Natural order, case-insensitive ("file2" before "file10"); this runtime has no Intl.
const collator = {
  compare(a, b) {
    const x = a.toLowerCase().match(/\d+|\D+/g) ?? [], y = b.toLowerCase().match(/\d+|\D+/g) ?? [];
    for (let i = 0; i < Math.min(x.length, y.length); i++) {
      if (x[i] === y[i]) continue;
      const nx = /^\d/.test(x[i]), ny = /^\d/.test(y[i]);
      if (nx && ny) return Number(x[i]) - Number(y[i]) || x[i].length - y[i].length;
      return x[i] < y[i] ? -1 : 1;
    }
    return x.length - y.length || (a < b ? -1 : a > b ? 1 : 0);
  },
};
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

// ── paths ──────────────────────────────────────────────────────────────────────────────
const dirOf = (rel) => (rel.includes("/") ? rel.slice(0, rel.lastIndexOf("/")) : "");
const baseOf = (path) => path.replace(/[\\/]+$/, "").split(/[\\/]/).pop() || path;
const join = (root, rel) => (rel ? (/[\\/]$/.test(root) ? root + rel : `${root}/${rel}`) : root);
function ancestors(rel) {
  const out = [];
  for (let d = dirOf(rel); d; d = dirOf(d)) out.push(d);
  return out;
}
function relTo(root, abs) {
  if (!root || !abs) return null;
  const a = abs.replace(/\\/g, "/"), r = root.replace(/\\/g, "/").replace(/\/+$/, "");
  if (a === r) return "";
  return a.startsWith(r + "/") ? a.slice(r.length + 1) : null;
}
const stronger = (a, b) => (!a ? b : (RANK[b] ?? 0) > (RANK[a] ?? 0) ? b : a);

// ── formatting ─────────────────────────────────────────────────────────────────────────
function formatSize(bytes) {
  if (bytes == null || bytes < 0) return "";
  if (bytes < 1024) return `${bytes} B`;
  const units = ["K", "M", "G", "T"];
  let v = bytes / 1024, i = 0;
  while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
  return `${v < 100 ? v.toFixed(1) : Math.round(v)} ${units[i]}`;
}
function stamp(ms) {
  if (!ms) return "";
  const d = new Date(ms), now = new Date(), p = (v) => String(v).padStart(2, "0");
  if (d.toDateString() === now.toDateString()) return `${p(d.getHours())}:${p(d.getMinutes())}`;
  const month = MONTHS[d.getMonth()];
  return d.getFullYear() === now.getFullYear() ? `${month} ${d.getDate()}` : `${month} ${d.getFullYear()}`;
}
function words(command) {
  const out = [];
  let word = null, quote = "";
  for (const ch of command) {
    if (quote) { if (ch === quote) quote = ""; else word = (word ?? "") + ch; }
    else if (ch === '"' || ch === "'") { quote = ch; word ??= ""; }
    else if (/\s/.test(ch)) { if (word !== null) out.push(word); word = null; }
    else word = (word ?? "") + ch;
  }
  if (word !== null) out.push(word);
  return out;
}

// ── the active setup's look ────────────────────────────────────────────────────────────
// Corners and header height follow the shown layout's pane frame, so the tree sits in
// whatever layout it is put in: square in a flush layout, rounded in a card layout.
function frameLook() {
  let pane = null;
  const walk = (n) => {
    if (!n || pane) return;
    if (n.content?.tab && n.content.pane) pane = n.content.pane;
    for (const c of n.children ?? []) walk(c);
  };
  try { walk(layout()); } catch {}
  const radius = Number(pane?.radius ?? 6);
  return { radius: Math.max(0, Math.min(6, Number.isFinite(radius) ? radius : 6)), header: Math.max(26, Math.min(40, Number(pane?.header?.height) || 30)) };
}
// A theme color at some opacity, for tinted backgrounds. Themes may give #rgb, #rrggbb or
// #rrggbbaa; anything else is returned as is.
function alpha(color, a) {
  const hex = /^#([0-9a-f]{3})$/i.test(color ?? "") ? "#" + [...color.slice(1)].map((c) => c + c).join("") : color;
  if (!/^#[0-9a-f]{6}([0-9a-f]{2})?$/i.test(hex ?? "")) return color;
  return hex.slice(0, 7) + Math.round(a * 255).toString(16).padStart(2, "0");
}
// Writes are orange (ansi 3), modified is yellow (ansi 11), so the two never read alike.
const tones = (t) => ({ purple: t.ansi5, orange: t.ansi3, green: t.ansi2, teal: t.ansi6, blue: t.ansi4, red: t.ansi1, cyan: t.ansi14 ?? t.ansi6, yellow: t.ansi11 ?? t.ansi3 });
const gitColor = (t, s) => (!s ? null : s === "D" || s === "U" ? t.ansi1 : s === "?" || s === "A" || s === "C" ? t.ansi2 : s === "R" ? t.ansi4 : t.ansi11 ?? t.ansi3);
const KIND = { purple: "read", orange: "write", green: "commit" };
const VIEWS = [["tree", "Tree", "folder"], ["recent", "Recent", "clock"]];
function ago(ms) {
  const s = Math.max(0, Math.round((Date.now() - ms) / 1000));
  return s < 10 ? "now" : s < 60 ? `${s}s` : s < 3600 ? `${Math.floor(s / 60)}m` : s < 86400 ? `${Math.floor(s / 3600)}h` : `${Math.floor(s / 86400)}d`;
}
// File and folder icons: Material Icon Theme, from the file-icons mod (icons.js copied here,
// the SVGs read from its icons/ folder), matched the way VS Code does. Names are compared in lower case; a
// path rule (".github/workflows") beats a name, a name beats an extension, the longest
// extension wins ("spec.ts" over "ts"). Light themes check the light table first.
const ICON_DIR = "mods/file-icons/icons";
const bare = (name) => name.replace(/^__(.+)__$/, "$1").replace(/^[._-]/, "");
const opened = (id) => (id.endsWith("_light") ? `${id.slice(0, -6)}-open_light` : `${id}-open`);
const lookup = (table, key, dark) => (dark ? undefined : ICONS.light[table][key]) ?? ICONS[table][key];
function fileIcon(path, dir, open, dark) {
  const parts = path.toLowerCase().split("/"), name = parts[parts.length - 1];
  const table = dir ? "folderNames" : "fileNames", find = (key) => lookup(table, key, dark) ?? (dir ? lookup(table, bare(key), dark) : undefined);
  let id;
  for (let i = 0; !id && i < parts.length - 1; i++) id = find(parts.slice(i).join("/"));
  if (dir) {
    id ??= find(name) ?? ICONS.folder;
    return `${ICON_DIR}/${open ? opened(id) : id}.svg`;
  }
  id ??= lookup(table, name, dark);
  for (let dot = name.indexOf("."); !id && dot !== -1; dot = name.indexOf(".", dot + 1)) id = lookup("fileExtensions", name.slice(dot + 1), dark);
  return `${ICON_DIR}/${id ?? ICONS.file}.svg`;
}

// ── where to look ──────────────────────────────────────────────────────────────────────
// The focused pane's folder; when the focused pane is a mod (this tree opened as a pane,
// say), the first terminal beside it.
//
// Local change (dotfiles): a mod pane with no terminal beside it (a file tab opened from this
// tree) keeps the folder shown before, in the same space, instead of falling back to the
// space's folder. The space comes from focused(): a space's `active` flag can name another one.
let lastLocation = null;
function location() {
  const f = focused(), space = spaces().find((s) => s.id === f?.space) ?? spaces().find((s) => s.active);
  let pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  if (pane && !pane.terminal) {
    const beside = panes().find((p) => p.tab === pane.tab && p.terminal && p.cwd);
    if (!beside && lastLocation && lastLocation.space === space?.id) return lastLocation;
    pane = beside ?? null;
  }
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return (lastLocation = { cwd: pane?.cwd || f?.cwd || space?.folder || null, on, space: space?.id });
}
const windows = (on) => !on && window()?.platform === "windows";
const psQuote = (s) => "'" + s.replaceAll("'", "''") + "'";

async function listDir(path, on) {
  if (windows(on)) {
    const r = await exec("powershell", ["-NoProfile", "-Command", `& { param($p) @(Get-ChildItem -LiteralPath $p -Force -ErrorAction Stop | Where-Object Name -ne '.git' | Select-Object -First ${PER_FOLDER + 1} | ForEach-Object { $rp = [bool]($_.Attributes -band [IO.FileAttributes]::ReparsePoint); @{ name=$_.Name; dir=($_.PSIsContainer -and -not $rp); link=$rp; size=$(if ($_.PSIsContainer) {0} else {$_.Length}); mtime=[DateTimeOffset]::new($_.LastWriteTimeUtc).ToUnixTimeMilliseconds() } }) | ConvertTo-Json -Compress } ${psQuote(path)}`]);
    if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
    const raw = JSON.parse(r.stdout || "[]"), list = Array.isArray(raw) ? raw : [raw];
    return { entries: sortEntries(list.slice(0, PER_FOLDER)), more: list.length > PER_FOLDER };
  }
  // One stat call for the folder: GNU's -c, else BSD's -f. "/" can't be in a name, so it splits.
  const script = `cd "$1" 2>/dev/null || exit 3; set --; for p in * .[!.]* ..?*; do [ -e "$p" ] || [ -L "$p" ] || continue; [ "$p" = .git ] && continue; set -- "$@" "$p"; [ $# -gt ${PER_FOLDER} ] && break; done; [ $# -eq 0 ] && exit 0; if stat -c %s . >/dev/null 2>&1; then stat -c '%F/%s/%Y/%n' -- "$@"; else stat -f '%HT/%z/%m/%N' -- "$@"; fi; exit 0`;
  const r = await exec("sh", ["-c", script, NAME, path], { on });
  if (r.code === 3) throw new Error("Cannot open this folder");
  const list = [];
  for (const line of r.stdout.split("\n")) {
    const m = /^([^/]*)\/(\d+)\/(\d+)\/(.+)$/.exec(line);
    if (!m) continue;
    const kind = m[1].toLowerCase();
    list.push({ name: m[4], dir: kind === "directory", link: kind.includes("link"), size: Number(m[2]), mtime: Number(m[3]) * 1000 });
  }
  return { entries: sortEntries(list.slice(0, PER_FOLDER)), more: list.length > PER_FOLDER };
}
const sortEntries = (list) => list.sort((a, b) => Number(b.dir) - Number(a.dir) || collator.compare(a.name, b.name));

async function buildIndex(root, on) {
  const atHome = root === home() || root === "/";
  const depth = atHome ? 5 : 12;
  if (windows(on)) {
    const r = await exec("powershell", ["-NoProfile", "-Command", `& { param($p) $b = (Resolve-Path -LiteralPath $p).Path.TrimEnd('\\'); Get-ChildItem -LiteralPath $b -Recurse -Force -Depth ${depth} -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '[\\\\/](\\.git|node_modules|target|\\.venv|__pycache__|dist|\\.next)([\\\\/]|$)' } | Select-Object -First 40000 | ForEach-Object { $(if ($_.PSIsContainer) {'d'} else {'f'}) + ($_.FullName.Substring($b.Length + 1) -replace '\\\\', '/') } } ${psQuote(root)}`]);
    const dirs = new Set(), all = [];
    for (const line of r.stdout.split(/\r?\n/)) if (line.length > 1) { const rel = line.slice(1); all.push(rel); if (line[0] === "d") dirs.add(rel); }
    return { dirs, all };
  }
  const names = [...PRUNE, ...(atHome ? HOME_PRUNE : [])].map((n) => `-name '${n}'`).join(" -o ");
  const script = `cd "$1" || exit 3; find . -maxdepth ${depth} \\( ${names} \\) -prune -o -type d -print 2>/dev/null | head -n 20000; echo //; find . -maxdepth ${depth} \\( ${names} \\) -prune -o ! -type d -print 2>/dev/null | head -n 40000`;
  const r = await exec("sh", ["-c", script, NAME, root], { on });
  const dirs = new Set(), all = [];
  let inDirs = true;
  for (const line of r.stdout.split("\n")) {
    if (line === "//") { inDirs = false; continue; }
    if (!line.startsWith("./")) continue;
    const rel = line.slice(2);
    all.push(rel);
    if (inDirs) dirs.add(rel);
  }
  return { dirs, all };
}

// ── git ────────────────────────────────────────────────────────────────────────────────
const emptyGit = () => ({ top: "", prefix: "", branch: null, status: new Map(), files: new Map(), ignored: new Set(), untracked: new Set(), diff: new Map(), counts: new Map() });

function parseBranch(record) {
  const body = record.replace(/^## /, "");
  if (body.startsWith("HEAD (no branch)")) return { head: "detached", upstream: "", ahead: 0, behind: 0 };
  return {
    head: body.match(/^(?:No commits yet on |Initial commit on )?(.+?)(?:\.\.\.|\s|$)/)?.[1] ?? body,
    upstream: body.match(/\.\.\.(\S+)/)?.[1] ?? "",
    ahead: Number(body.match(/ahead (\d+)/)?.[1] ?? 0),
    behind: Number(body.match(/behind (\d+)/)?.[1] ?? 0),
  };
}

function parseStatus(stdout, git) {
  const map = (p) => (p.startsWith(git.prefix) ? p.slice(git.prefix.length).replace(/\/$/, "") : null);
  const up = (rel, fn) => { for (const d of [...ancestors(rel), ""]) fn(d); };
  for (const rec of stdout.split("\0")) {
    if (rec.startsWith("## ")) { git.branch = parseBranch(rec); continue; }
    if (rec.length < 4) continue;
    const xy = rec.slice(0, 2), raw = rec.slice(3), rel = map(raw);
    if (!rel) continue;
    if (xy === "!!") { if (git.ignored.size < 5000) git.ignored.add(rel); continue; }
    const change = xy === "??" || (xy.includes("A") && !xy.includes("D")) ? 0 : xy.includes("D") && !xy.includes("U") ? 2 : 1;
    if (xy === "??" && raw.endsWith("/")) git.untracked.add(rel);
    else git.files.set(rel, change);
    up(rel, (d) => { const c = git.counts.get(d) ?? [0, 0, 0]; c[change]++; git.counts.set(d, c); });
    const letter = xy === "??" ? "?" : /U/.test(xy) || xy === "AA" || xy === "DD" ? "U" : ["D", "M", "R", "C", "A", "T"].find((c) => xy.includes(c)) ?? "";
    if (!letter) continue;
    git.status.set(rel, stronger(git.status.get(rel), letter));
    up(rel, (d) => git.status.set(d, stronger(git.status.get(d), letter)));
  }
}

function parseNumstat(stdout, git) {
  for (const rec of stdout.split("\0")) {
    const m = /^(-|\d+)\t(-|\d+)\t(.+)$/s.exec(rec);
    if (!m || !m[3].startsWith(git.prefix)) continue;
    const rel = m[3].slice(git.prefix.length), add = Number(m[1]) || 0, del = Number(m[2]) || 0;
    for (const d of [rel, ...ancestors(rel), ""]) { const v = git.diff.get(d) ?? [0, 0]; git.diff.set(d, [v[0] + add, v[1] + del]); }
  }
}

// ── opening files ──────────────────────────────────────────────────────────────────────
async function openExternal(abs) {
  const platform = window()?.platform;
  const r = platform === "macos" ? await exec("open", ["--", abs])
    : platform === "windows" ? await exec("powershell", ["-NoProfile", "-Command", `Invoke-Item -LiteralPath ${psQuote(abs)}`])
    : await exec("xdg-open", [abs]);
  if (r.code !== 0) throw new Error(r.stderr.trim() || "No app opens this file");
}
async function revealExternal(abs) {
  const platform = window()?.platform;
  if (platform === "macos") await exec("open", ["-R", "--", abs]);
  else if (platform === "windows") await exec("explorer.exe", [`/select,${abs.replace(/\//g, "\\")}`]);
  else await exec("xdg-open", [abs.replace(/\/[^/]*$/, "") || "/"]);
}
function copy(cx, text) {
  cx.write_to_clipboard(text);
  notify({ title: "Copied", body: text, level: "info", timeout: 2000 });
}
// Types "@path " into the agent of the shown tab, through the clipboard, then puts the
// clipboard back. The agent's pane takes the keyboard so the question can follow.
function sendToAgent(cx, abs) {
  const f = focused(), fp = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const inTab = agents().filter((a) => a.tab === f?.tab);
  const address = (fp?.status && fp.terminal) || (inTab.find((a) => a.focused) ?? inTab[0])?.address || agents().find((a) => a.focused)?.address;
  if (!address) { notify({ title: "No agent in this tab", body: "Start one, then send the path again", level: "warning", timeout: 3000 }); return; }
  const cwd = panes().find((p) => p.terminal === address)?.cwd;
  const rel = relTo(cwd, abs), path = rel || abs;
  const text = `@${/\s/.test(path) ? `"${path}"` : path} `;
  const before = cx.read_from_clipboard();
  cx.write_to_clipboard(text);
  run("pane.focus", { terminal: address });
  run("terminal.paste");
  cx.timer.after(600, (cx) => { if (before !== undefined) cx.write_to_clipboard(before); });
}

export default class FileTree extends View {
  init(_props, cx) {
    this.menu = props()?.menu ?? null;
    if (this.menu) return;
    this.handle = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.config = { ...DEFAULTS };
    let prefs = {};
    try { prefs = JSON.parse(localStorage.getItem("prefs") ?? "{}"); } catch {}
    this.showHidden = prefs.showHidden ?? true;
    this.showSize = prefs.showSize ?? null;
    this.follow = true; this.pinned = null;
    this.view = VIEWS.some(([v]) => v === prefs.view) ? prefs.view : "tree";
    try { this.history = JSON.parse(localStorage.getItem("history") ?? "[]"); } catch { this.history = []; }
    this.agoAt = 0;
    this.saved = new Map(); this.flashes = new Map(); this.bashStarts = new Map(); this.recent = [];
    this.sizes = new Map(); this.sizing = new Set(); this.visible = [];
    this.chip = null; this.branchFlash = null; this.width = 320; this.query = ""; this.hits = null; this.searchSeq = 0;
    this.seenAt = Date.now() - 2000; this.seenPreview = shared(`${NAME}.preview`)?.n ?? 0; this.seenView = shared(`${NAME}.view`)?.n ?? 0;
    this.focusSeen = 0; this.letGo = false;
    this.input = InputState.new({ placeholder: "Filter files" });
    this.input.on("change", (_e, cx) => this.search(this.input.value(), cx));
    this.input.on("submit", (_e, cx) => this.jump(cx));
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    this.reset(null, null);
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(`${appHome()}/mods/${NAME}/config.json`);
        if (text) this.config = { ...DEFAULTS, ...JSON.parse(text) };
      } catch (e) { notify({ title: "filetree: config.json is invalid", body: String(e), level: "warning", timeout: 4000 }); }
      this.showSize ??= this.config.column === "size";
      cx.notify();
    });
    this.watchActivity(cx);
    cx.timer.every(10000, (cx) => this.refresh(cx));
    cx.timer.every(1000, (cx) => this.tick(cx));
  }

  savePrefs() {
    try { localStorage.setItem("prefs", JSON.stringify({ showHidden: this.showHidden, showSize: this.showSize, view: this.view })); } catch {}
  }

  setView(view, cx) {
    if (view === this.view) return;
    this.view = view;
    this.savePrefs();
    this.hits = null; this.searchSeq++;
    if (view === "tree" && this.query.trim()) this.search(this.query, cx);
    this.scrollTo = this.cursor || null;
    cx.notify();
  }

  // ── the folder shown ─────────────────────────────────────────────────────────────────
  wanted() {
    const loc = location();
    if (!this.follow && this.pinned) return { root: this.pinned, on: this.pinnedOn };
    return { root: loc.cwd, on: loc.on };
  }

  reset(root, on) {
    if (this.ctx?.root) this.saved.set(this.ctx.key, { folders: this.folders, cursor: this.cursor });
    const key = JSON.stringify([root, on]), s = this.saved.get(key);
    this.ctx = { key, root, on }; this.root = root; this.on = on;
    this.entries = new Map(); this.folders = new Set(s?.folders); this.pending = new Set();
    this.cursor = s?.cursor ?? ""; this.git = emptyGit(); this.index = null; this.hits = null;
    this.sizes = new Map(); this.sizing = new Set(); this.error = null; this.limited = false;
    this.loading = false; this.again = false; this.watched = null; this.scrollTo = this.cursor || null;
    if (this.query) { this.query = ""; this.input?.set_value(""); }
    this.closePreview();
  }

  current(ctx) { return this.ctx === ctx; }

  sync(cx) {
    const { root, on } = this.wanted();
    if (root === this.root && on === this.on) return;
    this.reset(root, on);
    this.refresh(cx);
  }

  refresh(cx) {
    if (!this.root) return;
    if (this.loading) { this.again = true; return; }
    const ctx = this.ctx;
    this.loading = true; this.limited = false;
    cx.spawn(async (cx) => {
      try {
        for (const path of ["", ...this.folders]) {
          if (!this.current(ctx)) return;
          try { await this.loadFolder(path, ctx); }
          catch (e) { if (!path) throw e; this.folders.delete(path); this.entries.delete(path); }
        }
        await this.readGit(ctx);
        if (!this.current(ctx)) return;
        this.error = null;
        this.watch(cx);
      } catch (e) { if (this.current(ctx)) this.error = String(e?.message ?? e); }
      finally {
        if (this.current(ctx)) {
          this.loading = false;
          if (this.again) { this.again = false; this.refresh(cx); }
        }
        cx.notify();
      }
    });
  }

  async loadFolder(path, ctx) {
    const { entries, more } = await listDir(join(ctx.root, path), ctx.on);
    if (!this.current(ctx) || (path && !this.folders.has(path))) return;
    this.entries.set(path, entries);
    if (more) this.limited = true;
  }

  async readGit(ctx) {
    const g = (args) => exec("git", [...READ, ...args], { cwd: ctx.root, on: ctx.on });
    const git = emptyGit();
    const top = await g(["rev-parse", "--show-toplevel", "--show-prefix"]).catch(() => null);
    if (top?.code === 0) {
      const [dir, prefix = ""] = top.stdout.split("\n");
      git.top = dir.trim(); git.prefix = prefix.trim();
      const status = await g(["status", "--porcelain=v1", "-z", "-b", "--no-renames", "--untracked-files=normal", "--ignored=traditional", "--", "."]);
      if (status.code === 0) parseStatus(status.stdout, git);
      const head = await g(["rev-parse", "--verify", "-q", "HEAD"]);
      if (head.code === 0) {
        const numstat = await g(["diff", "HEAD", "--numstat", "-z", "--no-renames", "--", "."]);
        if (numstat.code === 0) parseNumstat(numstat.stdout, git);
      }
    }
    if (this.current(ctx)) this.git = git;
  }

  watch(cx) {
    if (this.on || this.watched === this.root) return;
    const ctx = this.ctx, root = this.root;
    this.watched = root;
    cx.spawn(async (cx) => {
      try {
        while (this.current(ctx)) {
          const paths = await watchFolder(root);
          if (!this.current(ctx)) return;
          this.changed(paths, cx);
        }
      } catch { if (this.current(ctx)) this.watched = null; }
    });
  }

  changed(paths, cx) {
    const now = Date.now();
    this.recent = this.recent.filter((r) => now - r.at < 15000);
    this.recent.push({ at: now, paths });
    let structural = false;
    for (const abs of paths) {
      const rel = relTo(this.root, abs);
      if (rel === null || rel === ".git" || rel.startsWith(".git/")) continue;
      structural = true;
      for (const d of [...ancestors(rel), ""]) this.sizes.delete(d);
    }
    if (structural && !this.query) this.index = null;
    this.refresh(cx);
  }

  toggle(path, cx) {
    if (this.folders.has(path)) {
      for (const folder of [...this.folders]) if (folder === path || folder.startsWith(path + "/")) { this.folders.delete(folder); this.entries.delete(folder); }
    } else this.open([path], cx);
    cx.notify();
  }

  // Opens folders (and their parents) and loads what they hold.
  open(paths, cx, then) {
    const ctx = this.ctx, todo = [];
    for (const p of paths) for (const d of [...ancestors(p).reverse(), p]) if (d && !this.folders.has(d)) { this.folders.add(d); todo.push(d); }
    cx.spawn(async (cx) => {
      for (const d of todo) {
        if (!this.current(ctx)) return;
        if (this.entries.has(d) || this.pending.has(d)) continue;
        this.pending.add(d);
        try { await this.loadFolder(d, ctx); }
        catch { this.folders.delete(d); }
        finally { this.pending.delete(d); }
      }
      if (this.current(ctx)) then?.();
      cx.notify();
    });
  }

  collapseAll(cx) { this.folders = new Set(); for (const k of [...this.entries.keys()]) if (k) this.entries.delete(k); cx.notify(); }

  // ── search ───────────────────────────────────────────────────────────────────────────
  search(query, cx) {
    this.query = query;
    const q = query.trim().toLowerCase();
    // Recent filters its own short list in rows(); only the tree searches disk.
    if (!q || this.view !== "tree") { this.hits = null; cx.notify(); return; }
    const seq = ++this.searchSeq, ctx = this.ctx;
    this.searching = true;
    cx.spawn(async (cx) => {
      try {
        if (!this.index) {
          const index = await buildIndex(ctx.root, ctx.on);
          if (!this.current(ctx)) return;
          this.index = index;
        }
        if (seq !== this.searchSeq) return;
        const matches = this.index.all.filter((rel) => rel.toLowerCase().includes(q) && (this.showHidden || !rel.split("/").some((s) => s.startsWith("."))));
        const named = matches.filter((rel) => baseOf(rel).toLowerCase().includes(q));
        this.hits = [...new Set([...named, ...matches])].slice(0, FIND_LIMIT);
        this.cursor = this.hits[0] ?? "";
        this.scrollTo = this.cursor;
      } catch (e) { if (seq === this.searchSeq) this.hits = []; this.error = String(e?.message ?? e); }
      finally { if (seq === this.searchSeq) this.searching = false; cx.notify(); }
    });
  }

  clearSearch(cx) {
    this.query = ""; this.hits = null; this.searchSeq++;
    this.input.set_value("");
    cx.notify();
  }

  jump(cx) {
    if (this.view !== "tree") {
      const first = this.rows().find((r) => r.rel === this.cursor) ?? this.rows()[0];
      if (first) { this.cursor = first.rel; this.handle.focus(); this.openFile(first.rel, cx); }
      return;
    }
    const target = this.hits?.includes(this.cursor) ? this.cursor : this.hits?.[0];
    this.clearSearch(cx);
    if (!target) return;
    this.cursor = target;
    this.handle.focus();
    this.open(ancestors(target), cx, () => { this.scrollTo = target; });
  }

  // ── rows ─────────────────────────────────────────────────────────────────────────────
  rows() {
    const out = [], q = this.query.trim().toLowerCase();
    if (this.view === "recent") return this.recentRows(q);
    if (this.hits) {
      const keep = new Set(), kids = new Map(), dirs = this.index?.dirs ?? new Set();
      for (const h of this.hits) { keep.add(h); for (const a of ancestors(h)) keep.add(a); }
      for (const rel of keep) { const p = dirOf(rel); if (!kids.has(p)) kids.set(p, []); kids.get(p).push(rel); }
      const entryOf = (rel) => this.entries.get(dirOf(rel))?.find((e) => e.name === baseOf(rel)) ?? { name: baseOf(rel), dir: dirs.has(rel), size: null, mtime: 0 };
      const walk = (p, depth) => {
        const list = (kids.get(p) ?? []).sort((a, b) => Number(dirs.has(b)) - Number(dirs.has(a)) || collator.compare(baseOf(a), baseOf(b)));
        for (const rel of list) { const e = entryOf(rel); out.push({ rel, e, depth, open: kids.has(rel) }); if (kids.has(rel)) walk(rel, depth + 1); }
      };
      walk("", 0);
      return out;
    }
    const walk = (prefix, depth) => {
      for (const e of this.entries.get(prefix) ?? []) {
        if (!this.showHidden && e.name.startsWith(".")) continue;
        const rel = prefix ? `${prefix}/${e.name}` : e.name, open = e.dir && this.folders.has(rel);
        out.push({ rel, e, depth, open });
        if (open && depth < 40) walk(rel, depth + 1);
      }
    };
    walk("", 0);
    return out;
  }

  // Recent: what Claude read, wrote or committed here, newest first, one row per file.
  recentRows(q) {
    const seen = new Set(), out = [];
    for (let i = this.history.length - 1; i >= 0; i--) {
      const h = this.history[i], rel = relTo(this.root, h.abs);
      if (!rel || seen.has(rel) || (q && !rel.toLowerCase().includes(q))) continue;
      seen.add(rel);
      const e = this.entries.get(dirOf(rel))?.find((x) => x.name === baseOf(rel)) ?? { name: baseOf(rel), dir: false, size: null, mtime: 0 };
      out.push({ rel, e, depth: 0, flat: true, recent: h });
    }
    return out;
  }

  isIgnored(rel) {
    if (!this.git.ignored.size) return false;
    for (let r = rel; r; r = dirOf(r)) if (this.git.ignored.has(r)) return true;
    return false;
  }
  underUntracked(rel) {
    if (!this.git.untracked.size) return false;
    for (let r = rel; r; r = dirOf(r)) if (this.git.untracked.has(r)) return true;
    return false;
  }

  // ── Claude activity, from the hook bridge ────────────────────────────────────────────
  watchActivity(cx) {
    const dir = `${home()}/.local/state/herdr-filetree`;
    cx.spawn(async (cx) => {
      try { await exec("mkdir", ["-p", dir]); } catch {}
      try {
        for (;;) {
          await watchFolder(dir);
          await this.readActivity(`${dir}/activity.jsonl`, cx);
        }
      } catch {}
    });
  }

  async readActivity(file, cx) {
    const text = await readTextFile(file).catch(() => null);
    if (!text) return;
    const fresh = [];
    for (const line of text.split("\n")) {
      if (!line) continue;
      try { const e = JSON.parse(line); if (e.at > this.seenAt) fresh.push(e); } catch {}
    }
    if (!fresh.length) return;
    this.seenAt = Math.max(...fresh.map((e) => e.at));
    const mode = this.config.activity, reads = mode === "reads and writes" || mode === "reads", writes = mode === "reads and writes" || mode === "writes";
    for (const e of fresh) {
      if (e.kind === "read" && reads) this.flash(e.paths ?? [], "purple", cx, e.paths?.length > 1 ? SEARCH_REVEAL : READ_REVEAL);
      else if (e.kind === "write" && writes) this.flash(e.paths ?? [], "orange", cx, READ_REVEAL);
      else if (e.kind === "mention") this.reveal(e.paths ?? [], cx);
      else if (e.kind === "bash-start") this.bashStarts.set(e.id, e.at);
      else if (e.kind === "bash-end" && writes) {
        const start = this.bashStarts.get(e.id) ?? e.at - 5000;
        this.bashStarts.delete(e.id);
        // The folder watch reports Bash's writes a moment later; take what changed while it ran.
        cx.timer.after(1200, (cx) => {
          const paths = new Set();
          for (const r of this.recent) if (r.at >= start - 300 && r.at <= e.at + 1200) for (const p of r.paths) {
            const rel = relTo(this.root, p);
            if (rel && rel !== ".git" && !rel.startsWith(".git/") && !this.isIgnored(rel)) paths.add(p);
          }
          this.flash([...paths].slice(0, 60), "orange", cx, READ_REVEAL);
        });
      } else if (e.kind === "git") this.gitEvent(e, cx);
    }
    cx.notify();
  }

  related(cwd) {
    const base = this.git.top || this.root;
    return Boolean(base && cwd && (relTo(base, cwd) !== null || relTo(cwd, base) !== null));
  }

  gitEvent(e, cx) {
    if (!this.related(e.cwd)) return;
    const a = e.actions?.[e.actions.length - 1];
    if (!a) return;
    this.chip = { label: e.actions.map((x) => x.label).join(" · "), tone: a.tone, state: e.state, detail: e.detail ?? "", at: e.at };
    if (e.state !== "running") {
      this.branchFlash = { tone: a.tone, at: Date.now() };
      if (e.paths?.length) this.flash(e.paths, "green", cx, READ_REVEAL);
      this.refresh(cx);
    }
  }

  flash(paths, tone, cx, limit) {
    const now = Date.now(), inside = [];
    for (const abs of paths) {
      const path = abs.replace(/\\/g, "/");
      this.flashes.set(path, { tone, at: now });
      this.history.push({ abs: path, kind: KIND[tone] ?? "write", at: now });
      const rel = relTo(this.root, abs);
      if (rel) inside.push(rel);
    }
    if (this.history.length > 120) this.history = this.history.slice(-80);
    try { localStorage.setItem("history", JSON.stringify(this.history)); } catch {}
    if (!inside.length || !this.config.follow || this.hits || this.view !== "tree") { cx.notify(); return; }
    const shown = inside.slice(0, limit), last = shown[shown.length - 1];
    this.open(shown.flatMap((rel) => ancestors(rel)), cx, () => { this.scrollTo = last; });
  }

  reveal(paths, cx) {
    const rels = paths.map((p) => relTo(this.root, p)).filter(Boolean);
    if (!rels.length) return;
    const last = rels[rels.length - 1];
    this.cursor = last;
    this.open(rels.flatMap((rel) => ancestors(rel)), cx, () => { this.scrollTo = last; });
  }

  flashOf(rel, open, now) {
    const abs = join(this.root, rel).replace(/\\/g, "/");
    const f = this.flashes.get(abs);
    if (f && now - f.at < TINT_MS) return { tone: f.tone, bright: now - f.at < FLASH_MS };
    // A folder that is closed over something lit glows faintly.
    if (!open && this.flashes.size) {
      const prefix = abs + "/";
      let best = null;
      for (const [p, v] of this.flashes) if (now - v.at < FLASH_MS && p.startsWith(prefix) && (!best || v.at > best.at)) best = v;
      if (best) return { tone: best.tone, bright: false };
    }
    return null;
  }

  // Redraws only when a highlight changes state (bright → tinted → gone), not every second.
  tick(cx) {
    const now = Date.now();
    let dirty = false;
    for (const [p, v] of this.flashes) {
      const age = now - v.at;
      if (age >= TINT_MS) { this.flashes.delete(p); dirty = true; }
      else if (age >= FLASH_MS && age < FLASH_MS + 1000) dirty = true;
    }
    if (this.chip && now - this.chip.at > (this.chip.state === "running" ? RUNNING_MS : CHIP_MS)) { this.chip = null; dirty = true; }
    if (this.branchFlash && now - this.branchFlash.at > FLASH_MS) { this.branchFlash = null; dirty = true; }
    if (this.showSize && this.view === "tree") this.pumpSizes(cx);
    // Recent shows "4m ago"-style times; refresh them twice a minute, only while shown.
    if (this.view === "recent" && now - this.agoAt > 30000) { this.agoAt = now; dirty = true; }
    if (dirty) cx.notify();
  }

  // ── sizes ────────────────────────────────────────────────────────────────────────────
  pumpSizes(cx) {
    if (windows(this.on)) return;
    const ctx = this.ctx;
    for (const rel of this.visible) {
      if (this.sizing.size >= 2) break;
      if (this.sizes.has(rel) || this.sizing.has(rel)) continue;
      this.sizing.add(rel);
      cx.spawn(async (cx) => {
        try {
          const r = await exec("du", ["-sk", "--", join(ctx.root, rel)], { on: ctx.on });
          const kb = Number(r.stdout.split(/\s/)[0]);
          if (this.current(ctx)) this.sizes.set(rel, Number.isFinite(kb) ? kb * 1024 : -1);
        } catch { if (this.current(ctx)) this.sizes.set(rel, -1); }
        finally { this.sizing.delete(rel); cx.notify(); }
      });
    }
  }

  // ── preview and opening ──────────────────────────────────────────────────────────────
  closePreview() {
    this.code?.release();
    this.code = null; this.md = null; this.file = null; this.fileError = null;
  }

  // inRender: called while drawing (a request from another mod), where notify is refused.
  show(rel, cx, inRender = false) {
    this.closePreview();
    this.file = rel;
    const ctx = this.ctx;
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(join(ctx.root, rel), { on: ctx.on });
        if (this.file !== rel || !this.current(ctx)) return;
        if (text === null) { this.fileError = "This file is no longer available"; return; }
        if (text.includes("\0")) { this.fileError = "Binary file · no text preview"; return; }
        const value = text.length > 400000 ? text.slice(0, 400000) + "\n… (file truncated)" : text;
        const ext = rel.includes(".") ? rel.split(".").pop().toLowerCase() : "txt";
        if (ext === "md" || ext === "markdown" || ext === "mdx") { this.md = value; return; }
        const t = theme();
        this.code = EditorState.new({ language: LANG[ext] ?? ext, readonly: true, value,
          font_family: settings().font_family, font_size: 12,
          syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      } catch { if (this.file === rel && this.current(ctx)) this.fileError = "Cannot preview this file (binary, too large, or unreadable)"; }
      finally { cx.notify(); }
    });
    if (!inRender) cx.notify();
  }

  // Double-click and Enter: config.json's "open". "preview" shows it here; "" the default
  // app; anything else is a command with {path} and {dir}, run without a shell.
  //
  // Local change (dotfiles): "tab" opens it in a tab of the main area, in Code Review's file
  // view (tabbed-changes, role "file": read-only, git gutter, line comments for agents). It
  // works on other machines too. The space comes from focused(): a space's `active` flag can
  // name another one.
  openFile(rel, cx) {
    const how = String(this.config.open ?? "preview").trim(), abs = join(this.root, rel);
    if (how === "tab") {
      const space = focused()?.space ?? spaces().find((s) => s.active)?.id;
      if (!space) { this.show(rel, cx); return; }
      run("tab.new", { space, name: baseOf(rel), mod: "tabbed-changes",
        props: { role: "file", file: abs, root: this.root, on: this.on ?? null, line: null } });
      return;
    }
    if (how === "preview" || this.on) { this.show(rel, cx); return; }
    cx.spawn(async (cx) => {
      try {
        if (!how) await openExternal(abs);
        else {
          const argv = words(how), dir = abs.replace(/[\\/][^\\/]*$/, "");
          const filled = argv.map((w) => w.replace(/\{(path|dir)\}/g, (_, k) => (k === "path" ? abs : dir)));
          const r = await exec(filled[0], [...filled.slice(1), ...(argv.some((w) => w.includes("{path}")) ? [] : [abs])], { cwd: dir });
          if (r.code !== 0) throw new Error(r.stderr.trim() || `${filled[0]} exited ${r.code}`);
        }
      } catch (e) { notify({ title: "Could not open the file", body: String(e?.message ?? e), level: "error", timeout: 4000 }); this.show(rel, cx); }
      cx.notify();
    });
  }

  openMenu(rel, dir) {
    const abs = join(this.root, rel);
    openOverlay({ mod: NAME, kind: "popup", width: 210, height: dir ? 5 * 28 + 10 : 7 * 28 + 10, props: { menu: { root: this.root, rel, abs, dir, local: !this.on } } });
  }

  // A virtual list's rows can't hold handlers, so the list reports the row and
  // a second press on the same row within 450 ms is the double-click.
  press(rel, cx) {
    const r = this.rows().find((x) => x.rel === rel);
    if (!r) return;
    const now = Date.now(), double = this.lastPress?.rel === rel && now - this.lastPress.at < 450;
    this.lastPress = double ? null : { rel, at: now };
    this.handle.focus();
    this.cursor = rel;
    if (r.flat && r.e.dir) this.revealInTree(rel, cx);
    else if (r.e.dir) { if (this.hits) this.jump(cx); else if (!double) this.toggle(rel, cx); }
    else if (double) this.openFile(rel, cx);
    cx.notify();
  }

  // ── keyboard ─────────────────────────────────────────────────────────────────────────
  move(rows, delta) {
    if (!rows.length) return;
    const at = rows.findIndex((r) => r.rel === this.cursor);
    const next = Math.max(0, Math.min(rows.length - 1, at < 0 ? (delta > 0 ? 0 : rows.length - 1) : at + delta));
    this.cursor = rows[next].rel;
    this.scroll.scroll_to_item(next);
  }

  revealInTree(rel, cx) {
    this.setView("tree", cx);
    if (this.query) this.clearSearch(cx);
    this.cursor = rel;
    this.open(ancestors(rel), cx, () => { this.scrollTo = rel; });
  }

  key(e, cx) {
    const k = e.key, rows = this.rows(), cur = rows.find((r) => r.rel === this.cursor);
    if (this.typing) {
      if (k === "escape") { if (this.query) this.clearSearch(cx); else this.handle.focus(); }
      else if (k === "down" || k === "up") this.move(rows, k === "down" ? 1 : -1);
      else return;
      cx.stop_propagation(); cx.notify(); return;
    }
    if (this.file) {
      if (k === "escape" || k === "left" || k === "h") this.closePreview();
      else if (k === "o" && !this.on) openExternal(join(this.root, this.file)).catch(() => {});
      else return;
      cx.stop_propagation(); cx.notify(); return;
    }
    const shift = e.modifiers?.shift;
    if (k === "up" || k === "k") this.move(rows, -1);
    else if (k === "down" || k === "j") this.move(rows, 1);
    else if (k === "pageup") this.move(rows, -10);
    else if (k === "pagedown") this.move(rows, 10);
    else if (k === "home") this.move(rows, -rows.length);
    else if (k === "end") this.move(rows, rows.length);
    else if (k === "/") { this.input.focus(); }
    else if (k === ".") { this.showHidden = !this.showHidden; this.savePrefs(); }
    else if (k === "escape") { if (this.query) this.clearSearch(cx); else this.cursor = ""; }
    else if (/^[1-9]$/.test(k) && VIEWS[Number(k) - 1]) this.setView(VIEWS[Number(k) - 1][0], cx);
    else if (!cur) return;
    else if (cur.flat && (k === "right" || k === "l")) this.revealInTree(cur.rel, cx);
    else if (cur.flat && (k === "left" || k === "h")) return;
    else if (cur.flat && cur.e.dir && (k === "enter" || k === "space")) this.revealInTree(cur.rel, cx);
    else if ((k === "right" || k === "l") && cur.e.dir && !cur.open) this.toggle(cur.rel, cx);
    else if (k === "left" || k === "h") { if (cur.e.dir && cur.open && !this.hits) this.toggle(cur.rel, cx); else if (dirOf(cur.rel) || cur.depth) { this.cursor = dirOf(cur.rel); this.scrollTo = this.cursor; } }
    else if (k === "enter") { if (this.hits) this.jump(cx); else if (cur.e.dir) this.toggle(cur.rel, cx); else this.openFile(cur.rel, cx); }
    else if (k === "space") { if (cur.e.dir) this.toggle(cur.rel, cx); else this.show(cur.rel, cx); }
    else if (k === "p" && !cur.e.dir) this.show(cur.rel, cx);
    else if (k === "y") copy(cx, shift ? join(this.root, cur.rel) : cur.rel);
    else if (k === "a") sendToAgent(cx, join(this.root, cur.rel));
    else return;
    cx.stop_propagation(); cx.notify();
  }

  // ── drawing ──────────────────────────────────────────────────────────────────────────
  button(id, label, tip, on, onClick, t, R) {
    return div().id(id).h(20).min_w(20).px(4).flex_none().flex().items_center().justify_center().rounded(R).cursor_pointer()
      .text_size(12).text_color(on ? t.foreground : t.dim).hover((s) => s.bg(t.hover).text_color(t.foreground)).tooltip(tip)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => { onClick(cx); cx.notify(); })
      .child(label);
  }

  pill(letter, color, R) {
    return div().size(16).flex_none().flex().items_center().justify_center().rounded(Math.min(R, 3)).bg(alpha(color, 0.15)).text_color(color).text_size(10).font_semibold().child(letter);
  }

  // A row of Recent: a status pill, the name, then what happened to it.
  flatRow(r, t, R, now) {
    const { rel, e } = r, tone = tones(t), selected = rel === this.cursor;
    const fl = this.flashOf(rel, true, now), lit = fl ? tone[fl.tone] : null;
    const pulse = (el) => el.loop("opacity", { from: 0.35, to: 1, period: 900 });
    const h = r.recent, color = h.kind === "read" ? tone.purple : h.kind === "commit" ? tone.green : tone.orange;
    return h_flex().id(`ft-${rel}`).h(ROW).flex_none().pl(8).pr(10).gap(7).items_center().rounded(R).cursor_pointer()
      .when(selected, (el) => el.bg(t.selected)).when(!selected, (el) => el.hover((s) => s.bg(t.hover)))
      .when(Boolean(fl?.bright), (el) => el.bg(alpha(lit, 0.13)))
      .child(this.pill(h.kind === "read" ? "R" : h.kind === "commit" ? "C" : "W", color, R))
      .child(div().flex_none().max_w(Math.max(80, this.width * 0.5)).truncate().text_color(lit ?? t.foreground).when(Boolean(fl?.bright), pulse).child(e.name))
      .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(dirOf(rel)))
      .child(div().flex_none().text_size(11).text_color(color).child(h.kind === "read" ? "read" : h.kind === "commit" ? "committed" : "wrote"))
      .child(div().flex_none().w(26).text_size(11).text_color(t.dim).text_right().child(ago(h.at)));
  }

  row(r, t, R, now) {
    if (r.flat) return this.flatRow(r, t, R, now);
    const { rel, e, depth, open } = r, g = this.git, tone = tones(t);
    const status = g.status.get(rel) ?? (this.underUntracked(rel) ? "?" : null);
    const ignored = !status && this.isIgnored(rel);
    const fl = this.flashOf(rel, open, now), lit = fl ? tone[fl.tone] : null;
    const gc = gitColor(t, status), hidden = e.name.startsWith(".");
    const nameColor = lit ?? (ignored ? t.dim : gc ?? (hidden ? t.muted : t.foreground));
    const loc = !e.dir ? g.diff.get(rel) : null, counts = e.dir ? g.counts.get(rel) : null;
    const meta = this.showSize
      ? (e.dir ? (this.sizes.has(rel) ? formatSize(this.sizes.get(rel)) : "…") : formatSize(e.size))
      : (!e.dir && !loc && this.width > 250 ? stamp(e.mtime) : "");
    const selected = rel === this.cursor;
    const pulse = (el) => el.loop("opacity", { from: 0.35, to: 1, period: 900 });
    return h_flex().id(`ft-${rel}`).h(ROW).flex_none().pl(6 + depth * 14).pr(10).gap(6).items_center().rounded(R).cursor_pointer()
      .when(selected, (el) => el.bg(t.selected)).when(!selected, (el) => el.hover((s) => s.bg(t.hover)))
      .when(Boolean(fl?.bright), (el) => el.bg(alpha(lit, 0.13)))
      .child(e.dir ? svg(ICON(`chevron-${open ? "down" : "right"}`)).size(12).flex_none().text_color(t.dim) : div().w(12).flex_none())
      .child(image(fileIcon(rel, e.dir, open, settings().dark !== false)).size(16).flex_none().when(Boolean(fl?.bright), pulse))
      .child(div().flex_1().min_w(0).truncate().text_color(nameColor).when(selected, (el) => el.font_medium())
        .when(status === "D" && !e.dir, (el) => el.line_through()).when(Boolean(fl?.bright), pulse).child(e.name + (e.link ? " ↪" : "")))
      .when(Boolean(meta), (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(meta)))
      .when(Boolean(loc?.[0]), (el) => el.child(div().flex_none().text_size(11).text_color(t.ansi2).child(`+${loc[0]}`)))
      .when(Boolean(loc?.[1]), (el) => el.child(div().flex_none().text_size(11).text_color(t.ansi1).child(`−${loc[1]}`)))
      .when(Boolean(counts), (el) => el.children(this.countChips(counts, t)))
      .when(!counts && Boolean(status), (el) => el.child(div().flex_none().w(10).text_size(11).font_semibold().text_color(gc).child(status)))
      .when(!counts && !status && ignored, (el) => el.child(div().flex_none().w(10).text_size(11).text_color(t.dim).child("⊘")));
  }

  countChips(c, t) {
    const out = [];
    if (c[0]) out.push(div().flex_none().text_size(11).text_color(t.ansi2).child(`?:${c[0]}`));
    if (c[1]) out.push(div().flex_none().text_size(11).text_color(t.ansi11 ?? t.ansi3).child(`M:${c[1]}`));
    if (c[2]) out.push(div().flex_none().text_size(11).text_color(t.ansi1).child(`D:${c[2]}`));
    return out;
  }

  // Branch, totals, a bar of modified / new / deleted, and its legend.
  summary(t) {
    const g = this.git, b = g.branch, tone = tones(t);
    if (!g.top) return h_flex().h(28).flex_none().px(10).gap(6).items_center().text_size(11.5).text_color(t.dim).border_b(1).border_color(t.border)
      .child(div().truncate().child(this.root ? "± no git repo · git status starts after git init" : ""));
    const lit = this.branchFlash ? tone[this.branchFlash.tone] : null, totals = g.diff.get("") ?? [0, 0];
    const c = g.counts.get("") ?? [0, 0, 0], total = c[0] + c[1] + c[2];
    const parts = [[c[1], tone.yellow, "modified"], [c[0], tone.green, "new"], [c[2], tone.red, "deleted"]].filter(([n]) => n > 0);
    const room = Math.max(40, this.width - 20 - 2 * (parts.length - 1));
    return v_flex().flex_none().px(10).pt(9).pb(8).gap(6).border_b(1).border_color(t.border)
      .child(h_flex().gap(6).items_center().text_size(12)
        .child(svg(ICON("git-branch")).size(12).flex_none().text_color(lit ?? t.foreground))
        .child(div().min_w(0).truncate().font_medium().text_color(lit ?? t.foreground).when(Boolean(lit), (el) => el.loop("opacity", { from: 0.4, to: 1, period: 900 })).child(b?.head ?? "…"))
        .when(Boolean(b?.ahead), (el) => el.child(div().flex_none().text_color(tone.teal).child(`↑${b.ahead}`)))
        .when(Boolean(b?.behind), (el) => el.child(div().flex_none().text_color(tone.blue).child(`↓${b.behind}`)))
        .child(div().flex_1())
        .when(Boolean(totals[0]), (el) => el.child(div().flex_none().text_size(11.5).text_color(t.ansi2).child(`+${totals[0]}`)))
        .when(Boolean(totals[1]), (el) => el.child(div().flex_none().text_size(11.5).text_color(t.ansi1).child(`−${totals[1]}`))))
      .child(total
        ? h_flex().h(4).gap(2).children(parts.map(([n, color]) => div().h_full().w(Math.max(3, (room * n) / total)).bg(color)))
        : div().h(4).w_full().bg(t.raised))
      .child(h_flex().gap(12).items_center().text_size(11).text_color(t.dim)
        .when(!total, (el) => el.child(div().child("clean · nothing to commit")))
        .children(parts.map(([n, color, label]) => h_flex().flex_none().gap(4).items_center().child(div().size(7).bg(color)).child(`${n} ${label}`)))
        .child(div().flex_1().min_w(0).truncate().text_right().child(b?.upstream ?? "")));
  }

  footer(t) {
    const c = this.chip, tone = tones(t);
    if (!this.cursor && !c) return null;
    const color = c ? (c.state === "failed" ? tone.red : tone[c.tone] ?? t.accent) : null;
    const hash = c?.state === "done" ? c.detail.split(" ")[0] : "";
    return h_flex().h(24).flex_none().px(10).gap(8).items_center().text_size(11).border_t(1).border_color(t.border)
      .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(this.cursor ? this.cursor : ""))
      .when(Boolean(c), (el) => el.child(h_flex().flex_none().gap(4).items_center().text_color(color)
        .child(div().when(c.state === "running", (d) => d.font_semibold().loop("opacity", { from: 0.4, to: 1, period: 1000 })).child(c.state === "running" ? `${c.label}…` : c.state === "done" ? `✓ ${c.label}` : c.label))
        .when(Boolean(hash), (d) => d.child(div().text_color(t.dim).child(hash)))));
  }

  renderMenu(cx) {
    const t = theme(), m = this.menu, R = frameLook().radius;
    const close = () => closeOverlay(props().overlay);
    const item = (id, label, act) => div().id(id).h(28).px(10).flex().items_center().rounded(R).cursor_pointer().text_size(12.5)
      .hover((s) => s.bg(t.hover)).on_click((_e, cx) => { close(); act(cx); }).child(label);
    const items = [];
    if (!m.dir) items.push(item("m-preview", "Preview", () => setShared(`${NAME}.preview`, { root: m.root, rel: m.rel, n: Date.now() })));
    if (!m.dir && m.local) items.push(item("m-open", "Open in default app", () => openExternal(m.abs).catch((e) => notify({ title: "Could not open the file", body: String(e?.message ?? e), level: "error" }))));
    if (m.local) items.push(item("m-reveal", window()?.platform === "macos" ? "Reveal in Finder" : "Show in folder", () => revealExternal(m.abs).catch(() => {})));
    items.push(item("m-rel", "Copy relative path", (cx) => copy(cx, m.rel)));
    items.push(item("m-abs", "Copy absolute path", (cx) => copy(cx, m.abs)));
    items.push(item("m-send", "Send to agent", (cx) => sendToAgent(cx, m.abs)));
    return v_flex().id("ft-menu").size_full().p(5).gap(0).bg(t.popover ?? t.surface).text_color(t.foreground).children(items);
  }

  // Local change (dotfiles): alt-shift-f (tabs-mods) stamps shared `filetree.focus` to give the
  // tree the keyboard, as tab-notes does. Pressed while the tree has it, the keyboard goes back:
  // dropping the focus target for a frame makes Herdr return it to the tab's focused pane.
  takeFocus(cx) {
    const ask = shared(`${NAME}.focus`);
    if (typeof ask !== "number" || ask <= this.focusSeen) return;
    this.focusSeen = ask;
    if (Date.now() - ask > 3000) return;
    // Typing in the filter box: move to the tree, as Esc does.
    if (this.typing) { this.handle.focus(); return; }
    if (this.handle.is_focused()) {
      this.letGo = true;
      cx.timer.after(50, (cx) => { this.letGo = false; cx.notify(); });
      return;
    }
    // The panel may only be on screen a frame or two later.
    for (const ms of [30, 200]) cx.timer.after(ms, () => { if (!this.handle.is_focused()) this.handle.focus(); });
  }

  render(cx) {
    if (this.menu) return this.renderMenu(cx);
    this.sync(cx);
    const req = shared(`${NAME}.preview`);
    if (req && req.n !== this.seenPreview) { this.seenPreview = req.n; if (req.root === this.root) this.show(req.rel, cx, true); }
    // Another mod (session-bar's changed chip) asks for a view.
    const want = shared(`${NAME}.view`);
    if (want && want.n !== this.seenView) {
      this.seenView = want.n;
      if (VIEWS.some(([v]) => v === want.view) && want.view !== this.view) { this.view = want.view; this.hits = null; this.closePreview(); this.savePrefs(); }
    }
    this.takeFocus(cx);
    const t = theme(), look = frameLook(), R = look.radius, now = Date.now();
    const rows = this.file ? [] : this.rows();
    if (this.scrollTo !== null && this.scrollTo !== undefined) {
      const at = rows.findIndex((r) => r.rel === this.scrollTo);
      if (at >= 0) { this.scroll.scroll_to_item(at, "center"); this.scrollTo = null; }
      else if (!this.pending.size && !this.loading) this.scrollTo = null;
    }
    const title = this.file ?? (this.root ? baseOf(this.root) : "Files");
    const btn = (id, label, tip, on, fn) => this.button(id, label, tip, on, fn, t, R);
    const header = h_flex().h(look.header).flex_none().px(8).gap(4).items_center().bg(t.chrome).border_b(1).border_color(t.border).text_size(12)
      .when(Boolean(this.file), (el) => el.child(btn("ft-back", svg(ICON("chevron-left")).size(12), "Back to the tree (Esc)", false, () => this.closePreview())))
      .when(Boolean(this.file), (el) => el.child(image(fileIcon(this.file, false, false, settings().dark !== false)).size(14).flex_none()))
      .child(div().flex_1().min_w(0).truncate().font_medium().text_color(this.file ? t.foreground : t.muted).child(title))
      .when(Boolean(this.file), (el) => el
        .when(!this.on, (el) => el.child(btn("ft-ext", "↗", "Open in default app (o)", false, () => openExternal(join(this.root, this.file)).catch(() => {}))))
        .child(btn("ft-copy", "⧉", "Copy path", false, (cx) => copy(cx, this.file)))
        .child(btn("ft-send", "@", "Send to agent", false, (cx) => sendToAgent(cx, join(this.root, this.file)))))
      .when(!this.file, (el) => el.child(h_flex().flex_none().gap(2).items_center().children(VIEWS.map(([id, label, icon], i) => {
        const on = this.view === id;
        return h_flex().id(`ft-tab-${id}`).h(22).px(7).gap(5).flex_none().items_center().rounded(R).cursor_pointer().text_size(11.5)
          .text_color(on ? t.foreground : t.dim).when(on, (el) => el.bg(t.selected)).when(!on, (el) => el.hover((s) => s.bg(t.hover).text_color(t.foreground)))
          .tooltip(`${label} (${i + 1})`).on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_click((_e, cx) => this.setView(id, cx))
          .child(svg(ICON(icon)).size(12).flex_none())
          .when(on || this.width >= 300, (el) => el.child(label));
      }))));

    // Tools sit beside the filter box and change with the view.
    const tools = this.view === "tree" ? [
      btn("ft-up", "↑", "Up a folder", false, () => { if (!this.root) return; this.follow = false; this.pinned = this.root.replace(/[\\/][^\\/]+[\\/]?$/, "") || "/"; this.pinnedOn = this.on; }),
      btn("ft-home", "⌂", this.follow ? "Following the focused pane" : "Back to the focused pane's folder", this.follow, () => { this.follow = true; this.pinned = null; }),
      btn("ft-hidden", this.showHidden ? "◉" : "○", this.showHidden ? "Hide dotfiles (.)" : "Show dotfiles (.)", this.showHidden, () => { this.showHidden = !this.showHidden; this.savePrefs(); }),
      btn("ft-size", "Σ", this.showSize ? "Show dates" : "Show sizes", Boolean(this.showSize), () => { this.showSize = !this.showSize; this.savePrefs(); }),
      btn("ft-collapse", "⊟", "Collapse all", false, (cx) => this.collapseAll(cx)),
    ] : [
      btn("ft-forget", "⊘", "Clear the list", false, () => { this.history = []; try { localStorage.setItem("history", "[]"); } catch {} }),
    ];

    // Local change (dotfiles): an accent border while the tree or its filter box has the keyboard,
    // like a focused terminal pane's and the Notes panel's.
    const root = v_flex().id(NAME).size_full().min_h(0).overflow_hidden().bg(t.background).text_color(t.foreground).text_size(13)
      .rounded(10).border_1().border_color(this.typing ? t.accent : t.border).focus((s) => s.border_color(t.accent))
      .when(!this.letGo, (el) => el.track_focus(this.handle)).on_key_down((e, cx) => this.key(e, cx))
      .on_size_change((size, cx) => { if (Math.abs(size.width - this.width) > 4) { this.width = size.width; cx.notify(); } })
      .child(header);

    if (this.file) {
      return root.child(this.code ? Editor.new(this.code).flex_1().min_h(0)
        : this.md !== null ? div().id("ft-md").flex_1().min_h(0).overflow_y_scrollbar().px(14).py(10).child(TextView.markdown("ft-md-text", this.md).selectable(true))
        : div().p(12).text_color(t.dim).child(this.fileError || "Loading file…"));
    }

    const q = this.query.trim();
    const note = this.error || (!this.root ? "No folder"
      : this.view === "recent" ? (rows.length ? null : q ? "No matches" : "Files Claude reads and writes here show up in this list")
      : this.searching && !rows.length ? "Searching…" : this.hits ? (rows.length ? null : "No matches") : this.loading && !rows.length ? "Loading files…" : !rows.length ? "Empty folder" : null);
    return root
      .child(this.summary(t))
      .child(h_flex().flex_none().mx(6).mt(6).mb(4).gap(2).items_center()
        .child(h_flex().flex_1().min_w(0).h(26).px(8).gap(6).items_center().rounded(R).bg(t.canvas ?? t.background).border_1().border_color(this.typing ? t.accent : t.input ?? t.border).cursor_text()
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .child(svg(ICON("search")).size(12).flex_none().text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12).text_color(t.foreground))
          .when(Boolean(this.query), (el) => el.child(div().id("ft-clear").flex_none().text_size(12).text_color(t.dim).cursor_pointer().hover((s) => s.text_color(t.foreground)).on_click((_e, cx) => this.clearSearch(cx)).child("×"))))
        .children(tools))
      .child(div().flex_1().min_h(0).relative().px(4)
        .child(v_virtual_list("ft-rows", rows.length, ROW, (i) => rows[i]?.rel ?? String(i), (range) => {
          const shown = rows.slice(range.start, range.end);
          this.visible = shown.filter((r) => !r.flat && r.e?.dir).map((r) => r.rel);
          return shown.map((r) => this.row(r, t, R, now));
        }).track_scroll(this.scroll).size_full()
          .on_item_click((rel, cx) => this.press(rel, cx))
          .on_item_secondary_click((rel, _e, cx) => { const r = this.rows().find((x) => x.rel === rel); if (!r) return; this.cursor = rel; this.openMenu(rel, r.e.dir); cx.notify(); }))
        .child(Scrollbar.vertical("ft-rows").viewport_from_layout().absolute().inset_0())
        .when(Boolean(note), (el) => el.child(div().absolute().top(4).left(0).right(0).px(10).text_size(12).text_color(t.dim).child(note))))
      .when(this.limited, (el) => el.child(div().px(10).py(3).text_size(11).text_color(t.dim).child(`Folders show their first ${PER_FOLDER} entries`)))
      .when(Boolean(this.hits?.length >= FIND_LIMIT), (el) => el.child(div().px(10).py(3).text_size(11).text_color(t.dim).child(`First ${FIND_LIMIT} matches · Enter jumps to the selected one`)))
      .when(Boolean(this.cursor || this.chip), (el) => el.child(this.footer(t)));
  }
}
