// The graph itself: Git Graph's table (graph, description, date, author,
// commit) for the focused pane's repository, or `props.folder` when opened as
// a pane. Labels take double-clicks (checkout) and right-clicks (menus).
import { div, svg, PathBuilder } from "gpui-kit";
import { v_flex, h_flex, Scrollbar, v_virtual_list } from "gpui-base";
import { spaces, panes, focused, exec, watchFolder, readTextFile, theme, settings, props, shared, setShared, openOverlay, home, notify, knownAgents, updates } from "herdr";
import { layoutLanes } from "./lanes.js";
import { READ, STATUS, UNCOMMITTED, LABEL, logArgs, parseLog, parseStatus, withUncommitted, labelsOf, hitLabel,
  menuFor, menuHeight, fileArgs, joinFiles, diffArgs, diffRows } from "./git.js";
import { perform, openDialog, showChanges } from "./act.js";
import { icon } from "./menu.js";
import { available, check, openUpdate, newer } from "./update.js";
import { depthOf, unsearched, findArgs, parseFound, REPO_STATUS, LATEST_TAG, FETCH, REMOTES, fetchable, parseRepoStatus, parseRemotes, webUrl, syncOf } from "./repos.js";

function location(folder) {
  if (folder) return { cwd: folder, on: null };
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on };
}

const PAGE = 300, ROW = 24, LANE = 12, PAD = 6, DIFF_ROW = 20;
// Herdr 0.1.12 zooms a list itself ("Lists in mods follow the zoom"): its row
// heights and the lines painted in its rows are layout units there, where before
// they were screen pixels. Asked once: the version doesn't change while running.
let zoomedLists;
const listsZoom = () => zoomedLists ??= (() => { try { const v = updates()?.app?.version; return Boolean(v) && !newer("0.1.12", v); } catch { return false; } })();
// The graph column's default keeps room for its "Graph" heading (and a lane or two) in narrow repos.
const GRAPH_MIN = 56;
// side: which way a drag widens it. Graph's handle is on its right edge, the others' on their left.
const COLUMNS = { graph: { width: null, min: 24, side: 1 }, date: { width: 62, min: 36, max: 240, side: -1 },
  author: { width: 120, min: 50, max: 400, side: -1 }, hash: { width: 66, min: 40, max: 200, side: -1 } };
const withDefaults = (saved) => ({ ...Object.fromEntries(Object.entries(COLUMNS).map(([k, c]) => [k, c.width])), ...saved });
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const pad2 = (n) => String(n).padStart(2, "0");
const laneColors = (t) => [t.ansi4, t.ansi2, t.ansi5, t.ansi3, t.ansi6, t.ansi1, t.ansi12, t.ansi10, t.ansi13, t.ansi11, t.ansi14, t.ansi9];
const isRefChange = (p) => /\/(HEAD|packed-refs)$|\/refs\//.test(p);
const inGitDir = (p) => p.includes("/.git/") || p.endsWith("/.git");

function ago(seconds) {
  const s = Date.now() / 1000 - seconds;
  if (s < 60) return "now";
  if (s < 3600) return `${Math.round(s / 60)}m`;
  if (s < 86400) return `${Math.round(s / 3600)}h`;
  if (s < 86400 * 30) return `${Math.round(s / 86400)}d`;
  const d = new Date(seconds * 1000);
  return d.getFullYear() === new Date().getFullYear() ? `${MONTHS[d.getMonth()]} ${d.getDate()}` : `${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

function stamp(seconds) {
  const d = new Date(seconds * 1000);
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())} ${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
}

const tilde = (path, on) => (!on && path?.startsWith(home()) ? "~" + path.slice(home().length) : path);
const brief = (c) => ({ hash: c.hash, subject: c.subject, parents: c.parents });
const count = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`;
const sameFiles = (a, b) => a.length === b.length && a.every((f, i) => f.path === b[i].path && f.status === b[i].status);
const scopeOf = ({ all, remotes }) => `${all} ${remotes}`;
// Folders kept as they were last read, and commits' details (a commit never changes).
const SEEN = 24, DETAILS = 200;
const keep = (map, key, value, max) => { map.delete(key); map.set(key, value); if (map.size > max) map.delete(map.keys().next().value); };

// What belongs to one folder: a new folder starts from this, and leaving one keeps it.
// workspace: the repositories under a folder that isn't one (Manygit), their
// statuses, and the one opened from that list (its graph shows until Back).
const folderState = () => ({
  state: "loading", root: null, on: null, cwd: null, error: null,
  workspace: null, statuses: new Map(), opened: null, skipped: false,
  base: [], commits: [], rows: [], lanes: 1, labels: new Map(), index: new Map(), hasMore: false, limit: PAGE, files: [], ctx: null,
  head: null, current: null, branches: [], remoteNames: [], signature: null, scope: null, moreAsked: null,
  selected: null, details: null, diff: null,
});

// Everything the table shows for a folder, in one round of git calls: each
// answers from any subfolder, and status names paths from the repository root.
async function readFolder(cwd, on, { all, remotes, limit }) {
  const git = (args) => exec("git", [...READ, ...args], { cwd, on });
  const [top, log, head, current, branches, remoteNames, status] = await Promise.all([
    // One commit past the page says whether there are more, as Git Graph asks.
    exec("git", ["rev-parse", "--show-toplevel"], { cwd, on }), git(logArgs({ all, remotes, limit: limit + 1 })),
    git(["rev-parse", "--verify", "-q", "HEAD"]), git(["symbolic-ref", "-q", "--short", "HEAD"]),
    git(["for-each-ref", "--format=%(refname)", "refs/heads"]), git(["remote"]), git(STATUS)]);
  if (top.code !== 0) return { state: "norepo", cwd, on };
  // A log that fails without a HEAD is a repository with no commits yet.
  if (log.code !== 0 && head.code === 0) throw new Error(log.stderr.trim());
  const base = log.code === 0 ? parseLog(log.stdout) : [];
  return {
    root: top.stdout.trim(), on, cwd, base: base.slice(0, limit), limit, hasMore: base.length > limit,
    head: head.code === 0 ? head.stdout.trim() : null, current: current.code === 0 ? current.stdout.trim() : null,
    branches: branches.stdout.split("\n").filter(Boolean).map((r) => r.replace(/^refs\/heads\//, "")),
    remoteNames: remoteNames.stdout.split("\n").filter(Boolean),
    files: status.code === 0 ? parseStatus(status.stdout) : [],
    signature: [log.stdout, head.stdout, current.stdout, branches.stdout, remoteNames.stdout].join("\0"), scope: scopeOf({ all, remotes }),
  };
}

// A row's status: one git call (with the newest tag beside it when tags show),
// and `git remote` only when the branch has no upstream.
async function readRepo(path, on, tags) {
  const [r, tag] = await Promise.all([exec("git", REPO_STATUS, { cwd: path, on }), tags ? exec("git", LATEST_TAG, { cwd: path, on }) : null]);
  if (r.code !== 0) return { error: (r.stderr || "git status failed").trim().split("\n").pop() };
  const st = parseRepoStatus(r.stdout);
  if (tag?.code === 0 && tag.stdout.trim()) st.tag = tag.stdout.trim();
  if (!st.upstream) st.hasRemote = Boolean((await exec("git", [...READ, "remote"], { cwd: path, on })).stdout.trim());
  return st;
}

// Runs fn over items, at most `limit` at a time (manygit's 8).
async function pool(items, limit, fn) {
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, async () => { while (next < items.length) await fn(items[next++]); }));
}
const depthSetting = () => depthOf(shared("git-graph.depth"));
const tagsShown = () => shared("git-graph.tags") === true;


export class Graph {
  init(cx) {
    this.folder = props()?.folder ?? null;
    // A scrollbar finds its list by name: each copy (panel, pane) needs its own.
    this.listId = `graph-rows-${Math.random().toString(36).slice(2)}`;
    this.diffId = `${this.listId}-diff`;
    this.all = true; this.remotes = true; this.wide = false; this.graphMax = 160; this.scale = null;
    this.watchToken = 0; this.seenChange = shared("git-graph.changed");
    this.cols = withDefaults(); this.drag = null;
    this.seen = new Map(); this.commitDetails = new Map();
    // Fetch all: its progress for one Manygit folder, and each repository's last failure.
    this.fetchAll = null; this.fetchErrors = new Map();
    // Manygit's .git watchers, one per repository, kept while it's listed (see watchRepos).
    this.watched = new Set();
    // Herdr's agents per machine, for a row's "New … tab" (as its + menu lists them).
    this.agents = new Map();
    this.handle = cx.focus_handle();
    this.reset();
    this.refresh(cx);
    cx.timer.after(1500, (cx) => this.warm(cx));
    // Remote spaces can't be watched: poll them gently. New folders get read ahead.
    // The Manygit list re-reads too: edits in a working tree don't touch .git.
    cx.timer.every(15000, (cx) => { if (!this.watching || this.state === "workspace") this.refresh(cx, true, true); this.warm(cx); check(); });
    check();
  }

  key() { return JSON.stringify(location(this.folder)); }

  reset() {
    Object.assign(this, folderState());
    this.watchToken++; this.watching = null; this.picking = false;
  }

  // Leaving a folder keeps it as it was; coming back shows that at once, while refresh reads it again.
  enter(context) {
    if (this.context && ["ready", "empty", "norepo", "workspace"].includes(this.state)) {
      keep(this.seen, this.context, Object.fromEntries(Object.keys(folderState()).map((k) => [k, this[k]])), SEEN);
    }
    this.context = context; this.reset(); this.loading = null;
    const kept = this.seen.get(context);
    if (kept && (kept.state === "workspace" || (kept.state === "norepo" ? !kept.warmed : kept.scope === scopeOf(this)))) {
      Object.assign(this, kept);
      // A folder read ahead has its history but no table yet.
      if (this.root && !this.commits.length) this.build();
    }
  }

  // Like manygit: read the folders open in other spaces ahead, one at a time, so switching to one shows it at once.
  warm(cx) {
    if (this.folder || this.warming) return;
    const machineOf = new Map(spaces().flatMap((s) => s.tabs.map((tab) => [tab.id, s.machine ?? null])));
    const todo = new Map();
    for (const p of panes()) {
      if (!p.cwd) continue;
      const where = { cwd: p.cwd, on: machineOf.get(p.tab) ?? null };
      todo.set(JSON.stringify(where), where);
    }
    // Other machines answer slower, and may not answer at all: last.
    const order = [...todo].filter(([key]) => key !== this.context && !this.seen.has(key)).sort(([, a], [, b]) => (a.on ? 1 : 0) - (b.on ? 1 : 0));
    if (!order.length) return;
    this.warming = true;
    cx.spawn(async () => {
      try {
        for (const [key, { cwd, on }] of order) {
          const scope = scopeOf(this);
          const read = await readFolder(cwd, on, { all: this.all, remotes: this.remotes, limit: PAGE }).catch(() => null);
          if (read && key !== this.context && !this.seen.has(key) && scope === scopeOf(this)) {
            // A folder that isn't a repository may hold some: entering it searches (Manygit).
            keep(this.seen, key, { ...folderState(), state: read.state ?? "ready", ...read, warmed: read.state === "norepo" }, SEEN);
          }
        }
      } finally { this.warming = false; }
    });
  }
  // A load belongs to its folder: a new folder starts at once, and a slower
  // load for the old one finds itself stale and drops its result.
  // timer: the 15 s re-read, which doesn't search a folder again that held no repositories.
  refresh(cx, full = true, timer = false) {
    const { cwd, on } = location(this.folder), context = this.key();
    if (context !== this.context) { this.enter(context); full = true; }
    if (!cwd) { this.state = "nofolder"; return; }
    // A repository opened from the Manygit list loads in place of the folder.
    const { all, remotes, limit } = this, opened = this.opened;
    const loadKey = JSON.stringify([context, opened]);
    if (this.loading?.key === loadKey) { this.again = this.again === "full" || full ? "full" : "status"; return; }
    // Each load has its own id: opening a repository and coming back can't revive an older one.
    const id = this.loadSeq = (this.loadSeq ?? 0) + 1;
    this.loading = { key: loadKey, id }; this.again = null;
    const stale = () => this.loadSeq !== id || this.key() !== context;
    cx.spawn(async (cx) => {
      try {
        if (full || !this.root) {
          const read = await readFolder(opened ?? cwd, on, { all, remotes, limit });
          if (stale()) return;
          if (read.state === "norepo") {
            if (opened) { this.state = "error"; this.error = `${tilde(opened, on)} isn't a git repository any more.`; return; }
            await this.scan(cwd, on, stale, cx, timer); return;
          }
          if (!opened) this.workspace = null;
          if (!on) this.watch(read.root, context, cx);
          // A second look that finds nothing new leaves the table as it is.
          const shown = this.state === "ready" || this.state === "empty";
          if (shown && read.signature === this.signature && read.scope === this.scope && sameFiles(read.files, this.files)) return;
          Object.assign(this, read);
        } else {
          const status = await exec("git", [...READ, ...STATUS], { cwd: this.root, on: this.on });
          if (stale()) return;
          const files = status.code === 0 ? parseStatus(status.stdout) : [];
          if (sameFiles(files, this.files)) return;
          this.files = files;
        }
        this.build();
        if (this.selected === UNCOMMITTED && this.details) this.loadDetails(this.commits[0], cx);
      } catch (e) {
        if (!stale()) { this.state = "error"; this.error = String(e?.message ?? e); }
      } finally {
        if (this.loading?.id === id) {
          this.loading = null; cx.notify();
          if (this.again) this.refresh(cx, this.again === "full");
        }
      }
    });
  }

  // Manygit: find the repositories under cwd, then read each one's status.
  async scan(cwd, on, stale, cx, timer) {
    const depth = depthSetting();
    if (timer && this.state === "norepo" && this.cwd === cwd) return;
    if (unsearched(cwd, on ? null : home())) { this.reset(); Object.assign(this, { state: "norepo", cwd, on, skipped: true }); return; }
    const found = await exec("find", findArgs(cwd, depth), { on }).catch(() => ({ stdout: "" }));
    if (stale()) return;
    const repos = parseFound(cwd, found.stdout);
    if (!repos.length) { this.reset(); Object.assign(this, { state: "norepo", cwd, on }); return; }
    // The same list keeps its rows' statuses while they're read again.
    const same = this.workspace?.root === cwd, statuses = same ? this.statuses : new Map();
    if (!same) this.reset();
    this.workspace = { root: cwd, depth, repos }; this.statuses = statuses; this.cwd = cwd; this.on = on; this.state = "workspace";
    if (!on) { this.watching = "workspace"; this.watchRepos(repos, cx); }
    cx.notify();
    await pool(repos, 8, (repo) => this.readStatus(repo.path, on, stale, cx));
  }

  // on: the machine the list was read on, never whatever the panel shows by the time it runs.
  async readStatus(path, on, stale, cx) {
    if (stale()) return;
    const st = await readRepo(path, on, tagsShown()).catch((e) => ({ error: String(e?.message ?? e) }));
    if (stale() || !this.workspace) return;
    if (JSON.stringify(st) !== JSON.stringify(this.statuses.get(path))) { this.statuses.set(path, st); cx.notify(); }
  }

  // A commit, checkout or fetch in any listed repository updates its row (local
  // folders). One loop per repository, whoever asks: opening one and coming back
  // keeps them, and the loop of a repository no longer listed ends at its next change.
  watchRepos(repos, cx) {
    for (const { path } of repos) {
      if (this.watched.has(path)) continue;
      this.watched.add(path);
      cx.spawn(async (cx) => {
        try {
          for (;;) {
            const paths = await watchFolder(`${path}/.git`), ws = this.workspace;
            if (!ws || this.on || !ws.repos.some((r) => r.path === path)) break;
            const root = ws.root;
            if (paths.some((p) => isRefChange(p.replace(/\\/g, "/")) || /[/\\]index$/.test(p))) await this.readStatus(path, null, () => this.workspace?.root !== root, cx);
          }
        } catch {} // a worktree's .git is a file: its row updates with the list
        this.watched.delete(path);
      });
    }
  }

  // Manygit's fetch: every repository with a remote, 8 at a time, each row
  // updated as its fetch ends. It goes on in the background if you open a repository.
  fetchEvery(cx) {
    const ws = this.workspace;
    if (!ws || this.fetchAll?.root === ws.root) return;
    const repos = ws.repos.filter((r) => fetchable(this.statuses.get(r.path))), on = this.on;
    const run = this.fetchAll = { root: ws.root, done: 0, total: repos.length, failed: 0 };
    const stale = () => this.workspace?.root !== run.root;
    cx.spawn(async (cx) => {
      await pool(repos, 8, async (r) => {
        const out = await exec("env", FETCH, { cwd: r.path, on }).catch((e) => ({ code: 1, stderr: String(e?.message ?? e) }));
        if (out.code === 0) this.fetchErrors.delete(r.path);
        else { run.failed++; this.fetchErrors.set(r.path, (out.stderr || "git fetch failed").trim().split("\n").pop()); }
        run.done++;
        await this.readStatus(r.path, on, stale, cx);
        cx.notify();
      });
      if (this.fetchAll === run) this.fetchAll = null;
      const repositories = (n) => `${n} ${n === 1 ? "repository" : "repositories"}`;
      notify(run.failed ? { title: `Fetched ${run.total - run.failed} of ${repositories(run.total)}`, body: "The failed ones show git's error on their row.", level: "warning" }
        : { title: `Fetched ${repositories(run.total)}`, level: "success", timeout: 3000 });
      cx.notify();
    });
    cx.notify();
  }

  // A row's right-click: its remotes and the machine's agents are read first
  // (one quick git call), then the menu opens at the pointer.
  repoMenu(r, cx) {
    const st = this.statuses.get(r.path), on = this.on, where = on ?? "";
    cx.spawn(async (cx) => {
      const [remotes, agents] = await Promise.all([
        exec("git", REMOTES, { cwd: r.path, on }).then((o) => parseRemotes(o.stdout)).catch(() => []),
        // Herdr's + menu keeps the same list: use it at once rather than wait for the shell.
        this.agents.get(where) ?? shared("new-menu.agents")?.[where] ?? knownAgents({ on }).catch(() => []),
      ]);
      const installed = agents.filter((a) => a.installed);
      this.agents.set(where, agents);
      const web = webUrl((remotes.find((x) => x.name === "origin") ?? remotes[0])?.url ?? "");
      const ctx = { root: r.path, on, current: st?.detached ? null : st?.branch ?? null, head: st?.head ?? null, branches: [], remotes: remotes.map((x) => x.name) };
      const target = { kind: "repo", path: r.path, status: st, agents: installed, web };
      openOverlay({ mod: "git-graph", kind: "popup", at: "pointer", width: 268, height: menuHeight(menuFor(target, ctx)), props: { role: "menu", target, ctx } });
      // Ask again in the background, so a newly installed agent shows next time.
      knownAgents({ on }).then((a) => this.agents.set(where, a)).catch(() => {});
    });
  }

  open(path, cx) {
    const { workspace, statuses, cwd, on } = this;
    this.reset(); Object.assign(this, { workspace, statuses, cwd, on, opened: path, state: "loading" });
    this.refresh(cx); cx.notify();
  }

  back(cx) {
    const { workspace, statuses, cwd, on } = this;
    this.reset(); Object.assign(this, { workspace, statuses, cwd, on, state: "workspace" });
    this.refresh(cx); cx.notify();
  }

  build() {
    const commits = withUncommitted(this.base, this.files.length, this.head);
    const { rows, width } = layoutLanes(commits);
    this.commits = commits; this.rows = rows; this.lanes = width;
    this.labels = new Map(commits.map((c) => [c.hash, labelsOf(c, this.remotes)]));
    this.index = new Map(commits.map((c, i) => [c.hash, i]));
    this.ctx = { root: this.root, on: this.on, current: this.current, head: this.head, branches: this.branches, remotes: this.remoteNames };
    this.state = commits.length ? "ready" : "empty"; this.error = null;
    if (this.selected && !this.index.has(this.selected)) { this.selected = null; this.details = null; this.diff = null; }
  }

  // Ref moves reload the history; other edits only the uncommitted row, at most every 1.5 s.
  watch(root, context, cx) {
    if (this.watching === root) return;
    this.watching = root;
    const token = this.watchToken;
    const loop = (dir, gitDir) => cx.spawn(async (cx) => {
      try {
        while (token === this.watchToken) {
          // Windows reports backslashes; the ref checks read slashes.
          const paths = (await watchFolder(dir)).map((p) => p.replace(/\\/g, "/"));
          if (token !== this.watchToken) return;
          if (paths.some((p) => (gitDir || inGitDir(p)) && isRefChange(p))) this.refresh(cx, true);
          else if (paths.some((p) => !gitDir && !inGitDir(p))) this.statusSoon(cx);
        }
      } catch { if (token === this.watchToken) this.watching = null; }
    });
    loop(root, false);
    // A linked worktree keeps its refs in the main checkout's .git.
    cx.spawn(async (cx) => {
      const common = (await exec("git", [...READ, "rev-parse", "--git-common-dir"], { cwd: root })).stdout.trim();
      const dir = /^([a-zA-Z]:)?[\\/]/.test(common) ? common : `${root}/${common}`;
      if (token === this.watchToken && this.key() === context && !dir.startsWith(`${root}/`)) loop(dir, true);
    });
  }

  statusSoon(cx) {
    if (this.statusTimer) return;
    this.statusTimer = true;
    cx.timer.after(Math.max(0, 1500 - (Date.now() - (this.lastStatus ?? 0))), (cx) => {
      this.statusTimer = false; this.lastStatus = Date.now(); this.refresh(cx, false);
    });
  }

  loadMore(cx) { this.limit += PAGE; this.refresh(cx); cx.notify(); }
  setScope(all, cx) { if (this.all !== all) { this.all = all; this.limit = PAGE; this.refresh(cx); } cx.notify(); }
  setRemotes(cx) { this.remotes = !this.remotes; this.refresh(cx); cx.notify(); }

  fetch(cx) {
    if (this.fetching || !this.ctx) return;
    this.fetching = true;
    const ctx = this.ctx;
    cx.spawn(async (cx) => {
      await perform({ type: "fetch" }, {}, ctx).catch(() => {});
      this.fetching = false; this.refresh(cx); cx.notify();
    });
    cx.notify();
  }

  graphWidth() { return this.cols.graph ? this.clampColumn("graph", this.cols.graph) : Math.min(Math.max(GRAPH_MIN, PAD * 2 + this.lanes * LANE), this.graphMax); }
  trailing() { return this.wide ? ["date", "author", "hash"] : ["date"]; }

  clampColumn(key, w) {
    const { min, max = (this.width ?? Infinity) * 0.7 } = COLUMNS[key];
    return Math.round(Math.max(min, Math.min(max, w)));
  }

  startDrag(key, e, cx) {
    cx.stop_propagation();
    if (e.click_count < 2) { this.drag = { key, x: e.position.x, from: key === "graph" ? this.graphWidth() : this.cols[key] }; return; }
    if (this.cols[key] !== COLUMNS[key].width) { this.cols = { ...this.cols, [key]: COLUMNS[key].width }; this.saveColumns(); cx.notify(); }
  }

  moveDrag(e, cx) {
    const d = this.drag;
    if (!d) return;
    const w = this.clampColumn(d.key, d.from + COLUMNS[d.key].side * (e.position.x - d.x) / this.unit());
    if (w !== this.cols[d.key]) { this.cols = { ...this.cols, [d.key]: w }; d.moved = true; cx.notify(); }
  }

  endDrag(cx) {
    const d = this.drag;
    if (!d) return;
    this.drag = null;
    if (d.moved) this.saveColumns();
    cx.notify();
  }

  saveColumns() { this.seenCols = JSON.stringify(this.cols); setShared("git-graph.columns", this.cols); }
  // Where the description column ends: labels past it are clipped, so not clickable.
  labelLimit() {
    if (!this.width) return Infinity;
    return this.width - 2 - 10 - this.trailing().reduce((n, k) => n + this.cols[k] + LABEL.GAP, 0);
  }
  // Pointer positions come in window units; layout sizes are these units times the zoom.
  unit() { return this.scale ?? settings().zoom ?? 1; }

  // A row is a whole number of screen pixels (21.6 at zoom 0.9 leaves hairline gaps between rows): rowPx is that,
  // rowH the same in the units an element's h() takes (the zoom scales it back).
  rowPx() { return Math.max(1, Math.round(ROW * (settings().zoom ?? 1))); }
  rowH() { return this.rowPx() / (settings().zoom ?? 1); }
  // The list's row height: units where Herdr zooms lists (rowH, still a whole number
  // of pixels once zoomed), screen pixels before.
  listRow() { return listsZoom() ? this.rowH() : this.rowPx(); }
  // What the lines' coordinates are multiplied by: nothing where Herdr zooms them itself.
  pathScale() { return listsZoom() ? 1 : this.unit(); }

  // A left press, then on release the list names the row: together, a click on a label.
  clicked(key, cx) {
    const press = this.press; this.press = null;
    if (key === "more") return this.loadMore(cx);
    const commit = this.commits[this.index.get(key)];
    if (!commit) return;
    if (press?.count >= 2) {
      const hit = hitLabel(this.labels.get(key), press.x, this.graphWidth(), this.labelLimit());
      if (hit) this.checkout(hit.part, cx);
      return;
    }
    this.pick(commit, cx);
  }

  checkout(part, cx) {
    const ctx = this.ctx;
    if (part.kind === "branch" && part.name !== ctx.current) cx.spawn(async () => { await perform({ type: "checkout", name: part.name }, {}, ctx); });
    else if (part.kind === "remote") {
      const branch = part.name.slice(part.name.indexOf("/") + 1);
      if (ctx.branches.includes(branch)) { if (branch !== ctx.current) cx.spawn(async () => { await perform({ type: "checkout", name: branch }, {}, ctx); }); }
      else openDialog({ type: "checkoutRemote", name: part.name, remote: part.name.slice(0, part.name.indexOf("/")), branch }, ctx);
    }
  }

  contextMenu(key, e, cx) {
    const commit = this.commits[this.index.get(key)];
    if (!commit || !this.ctx) return;
    if (e.bounds?.height) this.scale = e.bounds.height / this.rowH();
    const x = (e.local_position?.x ?? 0) / this.unit();
    const hit = commit.uncommitted ? null : hitLabel(this.labels.get(key), x, this.graphWidth(), this.labelLimit());
    const target = commit.uncommitted ? { kind: "uncommitted", commit: brief(commit), staged: this.files.some((f) => f.staged) }
      : hit && hit.part.kind !== "head" ? { kind: hit.part.kind, name: hit.part.name, commit: brief(commit) }
      : { kind: "commit", commit: brief(commit) };
    const items = menuFor(target, this.ctx);
    openOverlay({ mod: "git-graph", kind: "popup", at: "pointer", width: 268, height: menuHeight(items), props: { role: "menu", target, ctx: this.ctx } });
  }

  pick(commit, cx) {
    if (this.selected === commit.hash) { this.selected = null; this.details = null; this.diff = null; cx.notify(); return; }
    this.selected = commit.hash; this.details = null; this.diff = null;
    this.loadDetails(commit, cx);
    this.handle.focus();
    cx.notify();
  }

  loadDetails(commit, cx) {
    const hash = commit.hash, git = (args) => exec("git", [...READ, ...args], { cwd: this.root, on: this.on });
    const key = `${this.on}\0${this.root}\0${hash}`, known = !commit.uncommitted && this.commitDetails.get(key);
    if (known) { this.details = known; return; }
    cx.spawn(async (cx) => {
      try {
        let details;
        if (commit.uncommitted) {
          const numstat = this.head ? await git(["diff", "--no-renames", "--no-ext-diff", "--numstat", "HEAD"]) : { stdout: "" };
          const stats = joinFiles(this.files.map((f) => `${f.status}\t${f.path}`).join("\n"), numstat.stdout);
          details = { files: stats.slice(0, 500), more: Math.max(0, stats.length - 500) };
        } else {
          const args = fileArgs(commit);
          const [body, status, numstat] = await Promise.all([git(["show", "-s", "--format=%an%x1f%ae%x1f%cn%x1f%ct%x1f%B", hash]), git(args.status), git(args.numstat)]);
          if (body.code !== 0) throw new Error(body.stderr.trim());
          const [author, email, committer, committed, message] = body.stdout.split("\x1f");
          const files = joinFiles(status.stdout, numstat.stdout);
          details = { author, email, committer, committed: Number(committed), message: (message ?? "").trim(), files: files.slice(0, 500), more: Math.max(0, files.length - 500) };
          keep(this.commitDetails, key, details, DETAILS);
        }
        if (this.selected === hash) this.details = details;
      } catch (e) { if (this.selected === hash) this.details = { error: String(e?.message ?? e) }; }
      cx.notify();
    });
  }

  openDiff(commit, file, cx) {
    this.diff = { path: file.path, rows: null, width: 300 };
    const hash = commit.hash;
    cx.spawn(async (cx) => {
      let rows;
      try {
        if (commit.uncommitted && file.untracked) {
          const text = await readTextFile(`${this.root}/${file.path}`, { on: this.on }).catch(() => null);
          rows = text === null || text.includes("\0") ? [{ kind: "", text: "Binary or unreadable file" }]
            : diffRows(`@@ -0,0 +1 @@\n${text.slice(0, 400000).split("\n").slice(0, 3000).map((l) => `+${l}`).join("\n")}`);
        } else {
          const r = await exec("git", [...READ, ...diffArgs(commit, file.path)], { cwd: this.root, on: this.on });
          if (r.code !== 0) throw new Error(r.stderr.trim());
          rows = diffRows(r.stdout) ?? [{ kind: "", text: file.binary ? "Binary file changed" : "No text changes" }];
        }
      } catch (e) { rows = [{ kind: "", text: `Can't show this diff: ${e?.message ?? e}` }]; }
      if (this.selected === hash && this.diff?.path === file.path) {
        this.diff = { path: file.path, rows, width: Math.max(300, ...rows.map((r) => r.text.length * 6.6 + 60)) };
      }
      cx.notify();
    });
    cx.notify();
  }

  // ---- drawing

  graphCell(row, commit, colors, t, width) {
    const x = (lane) => PAD + lane * LANE + LANE / 2, y = (v) => v * this.rowH(), paths = new Map();
    // Elements are scaled by the zoom; before Herdr 0.1.12 a list's paint_path wasn't, so the lines scale to match the dots.
    const z = this.pathScale(), px = (lane) => x(lane) * z, py = (v) => y(v) * z;
    // One stroked path per color: a row is a handful of paints, however many lanes cross it.
    for (const [a, ya, b, yb, c, dashed] of row.segments) {
      const color = dashed ? t.dim : colors[c % colors.length], key = `${color}${dashed ? "-" : ""}`;
      let p = paths.get(key)?.p ?? (dashed ? PathBuilder.stroke(1.5 * z).dash_array([3 * z, 3 * z]) : PathBuilder.stroke(1.5 * z));
      p = p.move_to(px(a), py(ya));
      if (a === b) p = p.line_to(px(b), py(yb));
      else { const mid = (py(ya) + py(yb)) / 2; p = p.cubic_bezier_to(px(b), py(yb), px(a), mid, px(b), mid); }
      paths.set(key, { p, color });
    }
    const color = commit.uncommitted ? t.dim : colors[row.lane % colors.length];
    const dot = div().absolute().left(x(row.lane) - 4).top(this.rowH() / 2 - 4).size(8).rounded(4);
    return div().relative().flex_none().w(width).h(this.rowH()).overflow_hidden()
      .children([...paths.values()].map(({ p, color }) => window.paint_path(p.build(), color).absolute().top(0).left(0).size_full()))
      // HEAD is a ring, as in Git Graph; uncommitted changes a gray one.
      .child(commit.head || commit.uncommitted ? dot.bg(t.background).border(2).border_color(color) : dot.bg(color));
  }

  label(label, color, t, mono) {
    const current = label.kind === "branch" && label.head;
    const edge = label.kind === "tag" ? t.ansi3 : label.kind === "head" ? t.accent : color;
    return h_flex().flex_none().w(label.width).h(18).rounded(5).border_1().border_color(edge).overflow_hidden()
      .when(current, (e) => e.bg(color)).when(label.kind === "head", (e) => e.bg(t.accent))
      .children(label.parts.map((part, i) => {
        const fg = current || part.kind === "head" ? t.background : part.kind === "tag" ? t.ansi3 : i > 0 ? t.muted : t.foreground;
        const glyph = part.kind === "branch" ? (part.head ? "check" : "branch") : part.kind === "tag" ? "tag" : "cloud";
        return h_flex().w(part.width).h_full().flex_none().px(LABEL.PAD).gap(3).items_center().overflow_hidden()
          .when(i > 0, (e) => e.border_l(1).border_color(edge).bg(current ? t.background + "33" : edge + "1f"))
          .when(Boolean(part.icon), (e) => e.child(svg(icon(glyph)).size(10).flex_none().text_color(fg)))
          .child(div().font_family(mono).text_size(LABEL.FONT).when(current, (e) => e.font_semibold()).text_color(fg).child(part.text));
      }));
  }

  row(i, t, colors, mono, width) {
    const commit = this.commits[i], row = this.rows[i], color = colors[row.lane % colors.length];
    // Merge commits are muted, as Git Graph does by default.
    const fg = commit.uncommitted ? t.muted : commit.parents.length > 1 ? t.dim : t.foreground;
    return h_flex().id(`c-${commit.hash}`).w_full().h(this.rowH()).flex_none().pr(10).gap(LABEL.GAP).items_center().overflow_hidden()
      .when(commit.head, (e) => e.bg(color + "14")).when(this.selected === commit.hash, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
      .child(this.graphCell(row, commit, colors, t, width))
      // Labels and description clip together, so many labels never push the fixed columns out.
      .child(h_flex().flex_1().min_w(0).h_full().gap(LABEL.GAP).items_center().overflow_hidden()
        .children(this.labels.get(commit.hash).map((l) => this.label(l, color, t, mono)))
        .child(div().flex_1().min_w(0).truncate().text_color(fg).when(commit.head, (e) => e.font_semibold()).child(commit.subject)))
      .child(div().w(this.cols.date).flex_none().text_right().truncate().text_color(t.dim).child(commit.uncommitted ? "*" : ago(commit.time)))
      .when(this.wide, (e) => e
        .child(div().w(this.cols.author).flex_none().truncate().text_color(t.muted).child(commit.uncommitted ? "*" : commit.author))
        .child(div().w(this.cols.hash).flex_none().font_family(mono).text_size(11).text_color(t.dim).child(commit.uncommitted ? "*" : commit.hash.slice(0, 8))));
  }

  iconButton(id, glyph, tip, active, action, t) {
    return h_flex().id(id).h(24).px(6).gap(5).flex_none().items_center().rounded(6).text_size(11.5).cursor_pointer()
      .text_color(active ? t.foreground : t.muted).when(active, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover).text_color(t.foreground))
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_click(action)
      .child(svg(icon(glyph)).size(13).flex_none()).when(Boolean(tip), (e) => e.child(tip));
  }

  header(t) {
    const ready = this.state === "ready" || this.state === "empty", ws = this.workspace;
    const where = this.current ?? (this.head ? `detached at ${this.head.slice(0, 8)}` : null);
    // Opened from the Manygit list: "‹ Manygit" goes back to it, the repository's name
    // drops the same rows down over the graph to switch to another.
    const repo = ws && this.opened ? ws.repos.find((r) => r.path === this.opened) : null;
    const settingsShown = this.state === "workspace" || (this.state === "norepo" && !this.skipped);
    return h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
      .when(!repo, (e) => e.child(div().text_size(13).font_semibold().child(ws ? "Manygit" : "Git")))
      .when(Boolean(repo), (e) => e
        .child(h_flex().id("graph-back").h(24).pl(2).pr(6).gap(3).flex_none().items_center().rounded(6).cursor_pointer()
          .hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.back(cx))
          .child(svg(icon("back")).size(14).flex_none().text_color(t.muted)).child(div().text_size(13).font_semibold().child("Manygit")))
        .child(h_flex().id("graph-repository").h(22).px(7).gap(5).min_w(0).items_center().rounded(6).cursor_pointer()
          .bg(this.picking ? t.selected : t.raised).text_color(t.foreground).hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.togglePicker(cx))
          .child(svg(icon("folder")).size(12).flex_none()).child(div().min_w(0).truncate().text_size(11.5).font_semibold().child(repo.name))))
      .when(ready && Boolean(where), (e) => e.child(h_flex().h(22).px(7).gap(5).min_w(0).items_center().rounded(6).bg(t.accent + "26").text_color(t.accent)
        .child(svg(icon(this.current ? "branch" : "commit")).size(12).flex_none()).child(div().min_w(0).truncate().text_size(11.5).font_semibold().child(where))))
      .when(this.state === "workspace", (e) => e.child(div().flex_none().text_size(11.5).text_color(t.dim).child(count(ws.repos.length, "repo"))))
      .child(div().flex_1())
      // A newer release: a dot, and the update window on click.
      .when(Boolean(available()), (e) => e.child(h_flex().id("graph-update").h(24).px(7).gap(5).flex_none().items_center().rounded(6).text_size(11.5)
        .cursor_pointer().text_color(t.accent).hover((s) => s.bg(t.hover)).on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click(() => openUpdate()).child(div().size(6).rounded(3).bg(t.accent)).child("Update Graph")))
      .when(ready && this.remoteNames?.length > 0, (e) => e.child(this.iconButton("graph-fetch", "fetch", this.fetching ? "Fetching…" : null, false, (_e, cx) => this.fetch(cx), t)))
      .when(this.state === "workspace", (e) => {
        const run = this.fetchAll?.root === ws.root ? this.fetchAll : null;
        return e.child(this.iconButton("graph-fetch-all", "fetch", run ? `Fetching ${run.done}/${run.total}…` : "Fetch all", Boolean(run), (_e, cx) => this.fetchEvery(cx), t));
      })
      .when(this.state !== "nofolder", (e) => e.child(this.iconButton("graph-refresh", "refresh", null, false, (_e, cx) => this.refresh(cx), t)))
      .when(settingsShown, (e) => e.child(this.iconButton("graph-settings", "settings", null, false, () => this.openSettings(), t)));
  }

  openSettings() {
    openOverlay({ mod: "git-graph", kind: "popup", at: "pointer", width: 240, height: 92, props: { role: "settings" } });
  }

  // Manygit's repository pane: grouped by folder, each row its branch, uncommitted
  // changes and how it stands against its upstream. A click opens its graph.
  repoRows(t) {
    const repos = this.workspace.repos, grouped = repos.some((r) => r.group);
    const rows = [];
    let height = 8;
    repos.forEach((r, i) => {
      if (grouped && r.group !== repos[i - 1]?.group) {
        rows.push(div().h(26).flex_none().px(14).pt(9).text_size(11).text_color(t.dim).truncate().child(r.group ? `${r.group}/` : "./"));
        height += 26;
      }
      rows.push(this.repoRow(r, i, grouped, t));
      height += 34;
    });
    return { rows, height };
  }

  workspaceList(t) {
    return v_flex().id(`${this.listId}-repos`).flex_1().min_h(0).py(4).overflow_y_scrollbar().children(this.repoRows(t).rows);
  }

  // The dropdown under the header while a repository is open: at most 260px, scrolling.
  picker(t) {
    const { rows, height } = this.repoRows(t);
    return v_flex().id(`${this.listId}-picker`).h(Math.min(height, 260)).flex_none().py(4).overflow_y_scrollbar()
      .bg(t.raised).border_b(1).border_color(t.border).children(rows);
  }

  // Opening it reads every row again, since the list stopped watching while the graph showed.
  togglePicker(cx) {
    this.picking = !this.picking;
    if (this.picking) {
      const { repos, root } = this.workspace, on = this.on;
      cx.spawn((cx) => pool(repos, 8, (r) => this.readStatus(r.path, on, () => this.workspace?.root !== root, cx)));
    }
    cx.notify();
  }

  // The name with its status right after it, the branch on the right (as PR #2's
  // picker). Under a folder heading the row steps in, to read as inside it.
  repoRow(r, i, indent, t) {
    const st = this.statuses.get(r.path), fetchError = this.fetchErrors.get(r.path), sync = syncOf(st, fetchError), here = r.path === this.opened;
    // ↑ and ↓ as Herdr's Spaces list draws them (ansi2, ansi1); in sync shows nothing.
    const counts = ["ahead", "behind", "diverged"].includes(sync.kind) && !fetchError;
    const color = { loading: t.dim, error: t.ansi1, unpushed: t.ansi1, gone: t.ansi1, local: t.dim }[sync.kind];
    const label = counts || sync.kind === "ok" ? null : fetchError ? sync.text : { unpushed: "not pushed", error: "error" }[sync.kind] ?? sync.text;
    // A failure (reading it, or its last fetch) shows git's words where the branch goes.
    const problem = st?.error ?? fetchError;
    const branch = st && !problem ? (st.detached ? "detached" : st.branch) : null, tag = !problem && tagsShown() && st?.tag;
    return h_flex().id(`graph-repo-${i}`).h(34).flex_none().pl(indent ? 28 : 14).pr(14).gap(10).items_center().cursor_pointer()
      .when(here, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => { if (here) { this.picking = false; cx.notify(); } else this.open(r.path, cx); })
      .on_mouse_down("right", (_e, cx) => { cx.stop_propagation(); if (st && !st.error) this.repoMenu(r, cx); })
      .child(div().min_w(0).truncate().text_size(11.5).text_color(here ? t.accent : t.foreground).child(r.name))
      .child(h_flex().flex_none().gap(5).items_center().text_size(11.5)
        .when(st?.dirty > 0, (e) => e.child(h_flex().mr(2).gap(4).items_center().text_color(t.blocked)
          .child(div().size(6).rounded(3).bg(t.blocked)).child(String(st.dirty))))
        .when(counts && st.ahead > 0, (e) => e.child(div().text_color(t.ansi2).child(`\u2191${st.ahead}`)))
        .when(counts && st.behind > 0, (e) => e.child(div().text_color(t.ansi1).child(`\u2193${st.behind}`)))
        .when(Boolean(label), (e) => e.child(div().text_color(color).child(label))))
      .child(div().flex_1())
      // The newest tag, just before the branch (Show tags).
      .when(Boolean(tag), (e) => e.child(h_flex().flex_none().max_w(120).gap(4).items_center().text_color(t.dim)
        .child(svg(icon("tag")).size(11).flex_none()).child(div().min_w(0).truncate().text_size(11).child(tag))))
      .when(Boolean(branch), (e) => e.child(h_flex().flex_none().max_w(200).gap(5).items_center().text_color(t.muted)
        .child(svg(icon("branch")).size(12).flex_none()).child(div().min_w(0).truncate().text_size(11).child(branch))))
      .when(Boolean(problem), (e) => e.child(div().flex_none().max_w(200).truncate().text_size(11).text_color(t.ansi1).child(problem)));
  }


  toolbar(t) {
    const segment = (id, text, on, action) => div().id(id).h(22).px(9).flex().items_center().rounded(5).text_size(11.5).cursor_pointer()
      .bg(on ? t.raised : t.background).text_color(on ? t.foreground : t.muted).when(on, (e) => e.border_1().border_color(t.border))
      .hover((s) => s.text_color(t.foreground)).on_click(action).child(text);
    return h_flex().h(34).flex_none().px(10).gap(8).items_center().border_b(1).border_color(t.border)
      .child(h_flex().p(2).gap(2).rounded(7).bg(t.background).border_1().border_color(t.border)
        .child(segment("graph-all", "All branches", this.all, (_e, cx) => this.setScope(true, cx)))
        .child(segment("graph-current", "Current", !this.all, (_e, cx) => this.setScope(false, cx))))
      .child(h_flex().id("graph-remotes").h(24).px(6).gap(6).items_center().rounded(6).cursor_pointer().text_size(11.5).text_color(t.muted)
        .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click((_e, cx) => this.setRemotes(cx))
        .child(div().size(13).rounded(3).border_1().border_color(this.remotes ? t.accent : t.input).when(this.remotes, (e) => e.bg(t.accent)).flex().items_center().justify_center()
          .when(this.remotes, (e) => e.child(svg(icon("check")).size(10).text_color(t.accent_foreground))))
        .child("Remotes"));
  }

  columns(t, width) {
    const head = (text, w) => div().when(w !== undefined, (e) => e.w(w).flex_none()).truncate().child(text);
    const titles = { date: "Date", author: "Author", hash: "Commit" };
    // Handles stand in for the rows' gaps, 1px wider each side.
    const handle = (key) => div().id(`graph-col-${key}`).w(LABEL.GAP + 2).mx(-1).h_full().flex_none().flex().justify_center().cursor_col_resize()
      .on_mouse_down("left", (e, cx) => this.startDrag(key, e, cx))
      .child(div().w(1).h_full().when(this.drag?.key === key, (e) => e.bg(t.accent)))
      .hover((s) => s.bg(t.border));
    return h_flex().h(24).flex_none().pr(10).items_center().border_b(1).border_color(t.border).text_size(11).text_color(t.dim)
      .child(head("Graph", width).pl(PAD)).child(handle("graph")).child(div().flex_1().min_w(0).child("Description"))
      .children(this.trailing().flatMap((k) => [handle(k), head(titles[k], this.cols[k]).when(k === "date", (e) => e.text_right())]));
  }

  list(t, mono) {
    const colors = laneColors(t), width = this.graphWidth(), count = this.commits.length + (this.hasMore ? 1 : 0);
    return div().flex_1().min_h(0).relative()
      .on_mouse_down("left", (e) => { this.press = { x: (e.local_position?.x ?? 0) / this.unit(), count: e.click_count }; })
      .child(v_virtual_list(this.listId, count, this.listRow(), (i) => this.commits[i]?.hash ?? "more",
        (range, cx) => {
          // Scrolling to the end loads the next page, as Git Graph does; the row also takes a click.
          if (range.end > this.commits.length && this.hasMore && !this.loading && this.moreAsked !== this.limit) {
            this.moreAsked = this.limit;
            cx.spawn(async (cx) => this.loadMore(cx));
          }
          return Array.from({ length: range.end - range.start }, (_x, k) => range.start + k).map((i) => i < this.commits.length
            ? this.row(i, t, colors, mono, width)
            : div().id("graph-more").h(this.rowH()).flex_none().px(14).flex().items_center().text_color(t.accent).hover((s) => s.bg(t.hover))
              .child(this.loading ? "Loading more commits…" : `Load ${PAGE} more commits`));
        })
        // Rows of a virtual list can't hold their own handlers: the list reports the row's key.
        .on_item_click((key, cx) => this.clicked(key, cx))
        .on_item_secondary_click((key, e, cx) => this.contextMenu(key, e, cx))
        .size_full())
      .child(Scrollbar.vertical(this.listId).viewport_from_layout().absolute().inset_0());
  }

  detailsPane(t, mono) {
    const commit = this.commits[this.index.get(this.selected)], d = this.details;
    if (!commit) return div();
    const top = h_flex().h(32).flex_none().px(10).gap(6).items_center().border_b(1).border_color(t.border).text_size(11.5);
    const close = div().id("graph-details-close").px(6).py(1).rounded(4).text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
      .on_click((_e, cx) => { this.selected = null; this.details = null; this.diff = null; cx.notify(); }).child("×");
    if (this.diff) {
      const rows = this.diff.rows;
      return v_flex().flex_none().h(320).border_t(1).border_color(t.border)
        .child(top.child(div().id("graph-diff-back").px(6).py(1).rounded(4).text_color(t.muted).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
            .on_click((_e, cx) => { this.diff = null; cx.notify(); }).child("← Files"))
          .child(div().flex_1().min_w(0).truncate().font_family(mono).text_color(t.foreground).child(this.diff.path)).child(close))
        .child(div().flex_1().min_h(0).relative().font_family(mono).text_size(11)
          .when(!rows, (e) => e.child(div().p(12).text_color(t.dim).child("Loading diff…")))
          .when(Boolean(rows), (e) => e.child(div().id(`${this.diffId}-x`).size_full().overflow_x_scrollbar()
              .child(div().w_full().min_w(this.diff.width).h_full().child(v_virtual_list(this.diffId, rows.length, DIFF_ROW, (i) => String(i),
                (range) => rows.slice(range.start, range.end).map((r) => this.diffRow(r, t))).size_full())))
            .child(Scrollbar.vertical(this.diffId).viewport_from_layout().absolute().inset_0())));
    }
    const title = commit.uncommitted ? "Uncommitted changes" : `Commit ${commit.hash.slice(0, 8)}`;
    const body = v_flex().id("graph-details").flex_1().min_h(0).overflow_y_scrollbar().px(14).py(10).gap(4);
    const pane = (content) => v_flex().flex_none().h(320).border_t(1).border_color(t.border)
      .child(top.child(div().flex_1().text_color(t.muted).child(title))
        .when(Boolean(commit.uncommitted), (e) => e.child(div().id("graph-open-changes").px(6).py(1).rounded(4).text_color(t.accent).cursor_pointer().hover((s) => s.bg(t.hover))
          .on_click(() => showChanges()).child("Open Changes")))
        .child(close))
      .child(content);
    if (d?.error) return pane(body.child(div().text_color(t.ansi1).child(d.error)));
    const meta = (k, v, color) => h_flex().gap(8).text_size(11.5).child(div().w(64).flex_none().text_color(t.dim).child(k)).child(div().min_w(0).truncate().text_color(color ?? t.muted).child(v));
    // The history already has the header: it shows at once, and what git adds lands below it.
    const head = commit.uncommitted ? body : body
      .child(div().font_semibold().child(commit.subject))
      .child(meta("Commit", commit.hash, t.accent).font_family(mono))
      .child(meta("Parents", commit.parents.map((p) => p.slice(0, 8)).join(", ") || "none"))
      .child(meta("Author", `${commit.author} <${commit.email}>`))
      .child(meta("Date", `${stamp(commit.time)} · ${ago(commit.time)}`));
    if (!d) return pane(head.child(div().pt(8).text_size(11.5).text_color(t.dim).child(commit.uncommitted ? "Loading…" : "Loading files…")));
    const add = d.files.reduce((n, f) => n + f.add, 0), del = d.files.reduce((n, f) => n + f.del, 0);
    const lines = commit.uncommitted ? "" : d.message.split("\n").slice(1).join("\n").trim();
    return pane(head
      .when(Boolean(d.committer && d.committer !== d.author), (el) => el.child(meta("Committer", d.committer)))
      .when(Boolean(lines), (el) => el.child(v_flex().pt(6).children(lines.split("\n").map((line) => div().text_color(t.muted).child(line || " ")))))
      .child(h_flex().pt(8).pb(2).gap(8).items_center().text_size(11.5)
        .child(div().text_color(t.muted).child(count(d.files.length + d.more, "file")))
        .when(add > 0 || del > 0, (e) => e.child(div().text_color(t.ansi2).child(`+${add}`)).child(div().text_color(t.ansi1).child(`−${del}`))))
      .children(d.files.map((f, i) => {
        const parts = f.path.split("/"), name = parts.pop();
        const sc = f.status === "A" ? t.ansi2 : f.status === "D" || f.status === "U" ? t.ansi1 : t.blocked;
        return h_flex().id(`gf-${i}`).h(24).flex_none().px(6).gap(8).items_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => this.openDiff(commit, f, cx))
          .child(div().w(12).flex_none().text_size(11).text_color(sc).child(f.status))
          .child(h_flex().flex_1().min_w(0).child(div().text_color(t.dim).truncate().child(parts.length ? parts.join("/") + "/" : "")).child(div().min_w(0).truncate().child(name)))
          .when(f.add > 0, (e) => e.child(div().text_size(11).text_color(t.ansi2).child(`+${f.add}`)))
          .when(f.del > 0, (e) => e.child(div().text_size(11).text_color(t.ansi1).child(`−${f.del}`)));
      }))
      .when(d.more > 0, (e) => e.child(div().text_size(11).text_color(t.dim).child(`and ${d.more} more`))));
  }

  diffRow({ kind, number, text }, t) {
    if (kind === "@") return div().w_full().px(12).h(DIFF_ROW).flex_none().truncate().bg(t.raised).text_color(t.dim).child(text);
    return h_flex().w_full().h(DIFF_ROW).flex_none().gap(10).when(kind === "+", (e) => e.bg(t.ansi2 + "18")).when(kind === "-", (e) => e.bg(t.ansi1 + "18"))
      .child(div().w(34).flex_none().text_right().text_color(t.dim).child(number === undefined ? "" : String(number)))
      .child(div().flex_1().min_w(0).truncate().child(text));
  }

  empty(t) {
    const s = this.state, where = tilde(this.cwd, this.on);
    const [glyph, title, body] = s === "nofolder" ? ["folder", "No folder", "Focus a terminal to see the history of the repository it's in."]
      : s === "norepo" && this.skipped ? ["folder", "Not a git repository", `${where ?? "This folder"} isn't a repository, and is too big to search for them. Focus a terminal in a repository, or in a folder that holds some.`]
      : s === "norepo" ? ["folder", "Not a git repository", `${where ?? "This folder"} isn't inside a git repository, and holds none within ${count(depthSetting(), "level")}. Focus a terminal in one, or search deeper in settings.`]
      : s === "empty" ? ["commit", "No commits yet", "Make the first commit and it shows up here."]
      : s === "error" ? ["graph", "Can't read the history", this.error]
      : ["graph", "Loading history…", ""];
    return v_flex().flex_1().min_h(0).items_center().justify_center().gap(10).px(28).pb(40)
      .child(div().size(46).rounded(12).bg(t.raised).border_1().border_color(t.border).flex().items_center().justify_center()
        .child(svg(icon(glyph)).size(22).text_color(s === "error" ? t.ansi1 : t.muted)))
      .child(div().text_size(14).font_semibold().text_color(t.foreground).child(title))
      .when(Boolean(body), (e) => e.child(div().max_w(280).text_center().text_size(12).text_color(t.muted).child(body)));
  }

  render(cx) {
    if (this.key() !== this.context) this.refresh(cx);
    const changed = shared("git-graph.changed");
    const savedCols = shared("git-graph.columns"), seen = JSON.stringify(savedCols ?? null);
    if (!this.drag && seen !== this.seenCols) { this.seenCols = seen; this.cols = withDefaults(savedCols); }
    const fetched = shared("git-graph.fetched");
    if (fetched?.at !== this.seenFetched) { this.seenFetched = fetched?.at; if (fetched?.root) this.fetchErrors.delete(fetched.root); }
    // After an action (here, or from a Manygit row's menu) the graph or the list reads again.
    if (changed !== this.seenChange) { this.seenChange = changed; if (this.root || this.state === "workspace") this.refresh(cx); }
    // New settings: a depth searches again, tags read every row again.
    const setting = `${depthSetting()} ${tagsShown()}`;
    if (setting !== this.seenSetting) { const first = this.seenSetting === undefined; this.seenSetting = setting; if (!first && !this.opened) this.refresh(cx); }
    const t = theme(), mono = settings().font_family ?? "JetBrains Mono", ready = this.state === "ready";
    return v_flex().id("git-graph").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border)
      .text_color(t.foreground).text_size(12.5).track_focus(this.handle)
      .on_mouse_move((e, cx) => this.moveDrag(e, cx))
      .on_mouse_up("left", (_e, cx) => this.endDrag(cx))
      .on_hover((hovered, cx) => { if (!hovered) this.endDrag(cx); })
      .on_key_down((e, cx) => {
        if (e.key !== "escape" || !(this.selected || this.opened)) return;
        // Esc closes the dropdown, a diff, then the details, then goes back to the Manygit list.
        if (this.picking) this.picking = false; else if (this.diff) this.diff = null; else if (this.selected) { this.selected = null; this.details = null; } else this.back(cx);
        cx.stop_propagation(); cx.notify();
      })
      .on_size_change((size, cx) => {
        const width = size.width / this.unit(), wide = width >= 600, graphMax = Math.max(60, Math.round(width * 0.4));
        this.width = width;
        if (wide !== this.wide || graphMax !== this.graphMax) { this.wide = wide; this.graphMax = graphMax; cx.notify(); }
      })
      .child(this.header(t))
      .when(this.state === "workspace", (e) => e.child(this.workspaceList(t)))
      .when(Boolean(this.picking && this.workspace && this.opened), (e) => e.child(this.picker(t)))
      .when(ready, (e) => e.child(this.toolbar(t)).child(this.columns(t, this.graphWidth())).child(this.list(t, mono))
        .when(Boolean(this.selected), (el) => el.child(this.detailsPane(t, mono))))
      .when(!ready && this.state !== "workspace", (e) => e.child(this.empty(t)));
  }
}
