// t4's sidebar: every tab of every space as one inbox
// of work. Pinned on top, then active (newest first; activity never
// reshuffles), then the snoozed and settled shelves, folded. A row: its
// project, its status (needs you, done, working for how long) or how long
// since it last changed; its name; its branch and the icons of what runs in
// it. A project is a repo, worked out from git (a worktree's space belongs
// to its repo); a space outside git is its own. Quiet rows recede so the
// ones that need you stand out. Hover a row to snooze, pin or settle it;
// right-click for the tab menu. Search opens the picker; the filter narrows
// the list to one project; + folder adds a project (a space), the pen a new
// thread. A branch with a pull request shows its number and state (from
// `gh`, refreshed every few minutes); click it to open. Pins and snoozes
// are this layout's own (shared "t4.pins", "t4.snoozed"); a snoozed thread
// wakes on time or when its agent needs you. Settling is everyone's.

import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, panes, run, theme, shared, setShared, openOverlay, exec, window as win } from "herdr";

const C = {
  bg: "#0e0e10",
  row: "#1b1b1f",
  rowOn: "#222227",
  text: "#ececee",
  muted: "#a1a1aa",
  dim: "#71717a",
  line: "#1f1f23",
  working: "#7dd3fc",
  blocked: "#fcd34d",
  done: "#6ee7b7",
  error: "#fca5a5",
};
const PR = {
  OPEN: { icon: "git-pull-request", color: "#4ade80" },
  MERGED: { icon: "git-merge", color: "#c084fc" },
  CLOSED: { icon: "git-pull-request-closed", color: "#f87171" },
};
const PR_EVERY = 180e3;
const DEFAULT_BRANCHES = ["main", "master", "trunk", "develop"];
const I = (name) => `mods/t4-threads/${name}.svg`;

// Snooze choices: label and when it wakes. Edit to taste.
const SNOOZE = [
  ["1 hour", () => Date.now() + 3600e3],
  ["Tonight", () => at(Date.now(), 19)],
  ["Tomorrow", () => at(Date.now() + 86400e3, 9)],
];
function at(ms, hour) {
  const d = new Date(ms);
  d.setHours(hour, 0, 0, 0);
  return d.getTime() > Date.now() ? d.getTime() : d.getTime() + 86400e3;
}
function until(ms) {
  const m = Math.max(1, Math.round((ms - Date.now()) / 60e3));
  return m < 60 ? `${m}m` : m < 1440 ? `${Math.round(m / 60)}h` : `${Math.round(m / 1440)}d`;
}

// Space colors, kept by space id in shared "space.colors": a theme
// color name ("ansi6") or a picked #rrggbb. A space seen without one gets
// the theme color fewest spaces use, once; every mod does the same in the
// same order, so they agree, and adding or renaming spaces moves nothing.
const PROJECT_COLORS = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
function spaceColors() {
  const ids = new Set(spaces().map((p) => p.id));
  const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
  let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
  for (const p of spaces()) {
    if (kept[p.id] || p.name === "~") continue;
    const uses = (c) => Object.values(kept).filter((v) => v === c).length;
    kept[p.id] = PROJECT_COLORS.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    changed = true;
  }
  if (changed) setShared("space.colors", kept);
  return kept;
}
function spaceColor(t, p) {
  if (p.name === "~") return t.dim;
  const c = spaceColors()[p.id] ?? PROJECT_COLORS[0];
  return c.startsWith("#") ? c : t[c];
}

function age(ms) {
  if (!ms) return "";
  const s = Math.max(0, Math.floor((Date.now() - ms) / 1000));
  if (s < 60) return "now";
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

function duration(ms) {
  const s = Math.max(0, Math.floor((Date.now() - ms) / 1000));
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  return m < 60 ? `${m}m` : `${Math.floor(m / 60)}h ${m % 60}m`;
}

const num = (id) => Number(String(id).replace(/\D/g, "")) || 0;

function glyph(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}

export default class Threads extends View {
  init(_props, cx) {
    this.hover = null;
    this.showSettled = false;
    this.showSnoozed = false;
    this.snoozing = null; // the row showing its snooze choices
    this.picking = false;
    this.repos = {}; // folder -> { key, name } | null

    this.prs = {}; // "folder|branch" -> { number, state, url } | null
    this.asked = {}; // "folder|branch" -> when
    this.queue = [];
    // Durations tick: by the second while one shows seconds ("Working 12s"),
    // else twice a minute ("3m"). Each tick redraws this whole list.
    this.ticks = 0;
    cx.timer.every(1000, (cx) => {
      const now = Date.now();
      const seconds = spaces().some((w) => w.tabs.some((c) => c.status === "working" && c.working_since && now - c.working_since < 61000));
      if (seconds || ++this.ticks % 30 === 0) cx.notify();
    });
    cx.timer.every(1500, (cx) => this.lookup(cx));
  }

  // New folders only: a folder's repo doesn't change. Asked on render too,
  // so a new space shows its project at once.
  findRepos(cx) {
    const here = [...spaces().map((s) => [s.machine ?? null, s.folder]), ...panes().filter((p) => p.terminal).map((p) => [p.terminal.includes("/") ? p.terminal.split("/")[0] : null, p.cwd])].filter(([, cwd]) => cwd).map((at) => JSON.stringify(at));
    const folders = [...new Set(here.filter((f) => f && !(f in this.repos)))];
    if (!folders.length || this.finding) return;
    this.finding = true;
    cx.spawn(async (cx) => {
      for (const location of folders) {
        const [on, f] = JSON.parse(location);
        try {
          const r = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: f, on });
          const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: f, on });
          const key = r.code === 0 ? r.stdout.trim() : null;
          this.repos[location] = key && {
            key: JSON.stringify([on, key]),
            name: (key.endsWith("/.git") ? key.slice(0, -5) : key).split("/").pop(),
            linked: key !== `${top.stdout.trim()}/.git`,
          };
        } catch { this.repos[location] = null; }
      }
      this.finding = false;
      cx.notify();
    });
  }

  // The terminal a thread is about: the focused one, else its agent, else the first.
  lead(c, all = panes()) {
    const mine = all.filter((p) => p.tab === c.id && p.terminal);
    return mine.find((p) => p.focused) ?? mine.find((p) => p.program?.agent) ?? mine[0];
  }

  // A thread's project: the repo where its terminal is now (you cd'd there),
  // else its space's, else the space itself. Colored as the first space of that repo.
  project(w, c, all) {
    const where = this.lead(c, all)?.cwd;
    const r = (where && this.repos[JSON.stringify([w.machine ?? null, where])]) || this.repos[JSON.stringify([w.machine ?? null, w.folder])];
    if (!r) return { key: w.id, name: w.name, first: w, machine: w.machine };
    const first = spaces().find((s) => this.repos[JSON.stringify([s.machine ?? null, s.folder])]?.key === r.key) ?? w;
    return { key: r.key, name: r.name, first, machine: w.machine };
  }

  // Settling a worktree's last open thread offers to remove the worktree
  // (the `worktree` dialog; Esc keeps it).
  settle(w, c) {
    run("tab.settle", { id: c.id });
    const last = w.tabs.every((x) => x.id === c.id || x.settled);
    if (last && this.repos[JSON.stringify([w.machine ?? null, w.folder])]?.linked)
      openOverlay({ mod: "worktree", kind: "dialog", width: 440, height: 190, props: { space: w.id, action: "remove" } });
  }

  snoozed() {
    return shared("t4.snoozed") ?? {};
  }

  // Snoozed now: not yet due, and its agent hasn't asked for you since.
  asleep(c) {
    const s = this.snoozed()[c.id];
    if (!s || c.settled) return false;
    if (Date.now() >= s.until) return false;
    return !((c.status === "blocked" || c.status === "done") && (c.changed_at ?? 0) > s.at);
  }

  snooze(id, wake) {
    const all = { ...this.snoozed() };
    if (wake) all[id] = { until: wake, at: Date.now() };
    else delete all[id];
    setShared("t4.snoozed", all);
  }

  // The pull request of a branch, asked of `gh` at most every few minutes.
  pr(cwd, branch, on) {
    if (!cwd || !branch || DEFAULT_BRANCHES.includes(branch)) return null;
    const key = JSON.stringify([on ?? null, cwd, branch]);
    if (!(Date.now() - (this.asked[key] ?? 0) < PR_EVERY) && !this.queue.includes(key)) this.queue.push(key);
    return this.prs[key] ?? null;
  }

  lookup(cx) {
    if (this.looking || !this.queue.length) return;
    this.looking = true;
    const keys = this.queue.splice(0);
    cx.spawn(async (cx) => {
      for (const key of keys) {
        const [on, cwd, branch] = JSON.parse(key);
        this.asked[key] = Date.now();
        const r = await exec("gh", ["pr", "list", "--head", branch, "--state", "all", "--limit", "1", "--json", "number,state,url"], { cwd, on }).catch(() => ({ code: 1 }));
        let found = null;
        try {
          found = r.code === 0 ? (JSON.parse(r.stdout)[0] ?? null) : null;
        } catch {}
        this.prs[key] = found;
      }
      this.looking = false;
      cx.notify();
    });
  }

  badge(c, pr) {
    const look = PR[pr.state] ?? PR.OPEN;
    return h_flex()
      .id(`t4-pr-${c.id}`)
      .flex_none()
      .gap(3)
      .items_center()
      .text_color(look.color)
      .cursor_pointer()
      .hover((s) => s.opacity(0.8))
      .on_click((_e, cx) => {
        cx.stop_propagation();
        const p = win()?.platform;
        if (p === "windows") exec("explorer.exe", [pr.url]);
        else exec(p === "macos" ? "open" : "xdg-open", [pr.url]);
      })
      .child(svg(I(look.icon)).size(12))
      .child(`#${pr.number}`);
  }

  pins() {
    return shared("t4.pins") ?? [];
  }

  togglePin(id) {
    const pins = this.pins();
    setShared("t4.pins", pins.includes(id) ? pins.filter((p) => p !== id) : [...pins, id]);
  }

  status(c) {
    if (c.status === "blocked") return { icon: "message-circle-question", label: "Needs you", color: C.blocked };
    if (c.status === "done") return { icon: "circle-check", label: "Done", color: C.done };
    if (c.status === "working") return { icon: "circle-dashed", label: `Working ${c.working_since ? duration(c.working_since) : ""}`, color: C.working };
    return null;
  }

  button(id, label, icon, onClick) {
    return h_flex()
      .id(id)
      .gap(4)
      .px(6)
      .py(1)
      .rounded(6)
      .items_center()
      .text_size(12)
      .text_color(C.muted)
      .cursor_pointer()
      .hover((s) => s.text_color(C.text).bg("#ffffff10"))
      .on_click((_e, cx) => {
        cx.stop_propagation();
        onClick();
        cx.notify();
      })
      .when(Boolean(icon), (el) => el.child(svg(I(icon)).size(13)))
      .child(label);
  }

  row(t, r, all) {
    const { w, c } = r;
    const mine = all.filter((p) => p.tab === c.id && p.terminal);
    const lead = mine.find((p) => p.focused) ?? mine.find((p) => p.program?.agent) ?? mine[0];
    const programs = [...new Map(mine.map((p) => [p.program?.key, p.program])).values()].filter((p) => p && !p.shell);
    const st = this.status(c);
    const pr = this.pr(lead?.cwd, lead?.branch, w.machine);
    const here = w.active && c.active;
    const hovered = this.hover === c.id;
    const pinned = this.pins().includes(c.id);
    const asleep = this.asleep(c);
    const pj = this.project(w, c, all);
    // Quiet rows recede: what needs you (or what you're on) stays bright.
    const recede = !here && !hovered && c.status !== "blocked" && c.status !== "done";
    const right = hovered
      ? c.settled
        ? this.button(`t4-un-${c.id}`, "Unsettle", "check", () => run("tab.unsettle", { id: c.id }))
        : asleep
          ? this.button(`t4-wake-${c.id}`, "Wake", "clock", () => this.snooze(c.id, null))
          : h_flex()
              .gap(2)
              .child(
                this.button(`t4-snooze-${c.id}`, "", "clock", () => {
                  this.snoozing = this.snoozing === c.id ? null : c.id;
                }),
              )
              .child(this.button(`t4-pin-${c.id}`, pinned ? "Unpin" : "", "pin", () => this.togglePin(c.id)))
              .child(this.button(`t4-settle-${c.id}`, "Settle", "check", () => this.settle(w, c)))
      : asleep
        ? div().text_size(12).text_color(C.working).child(until(this.snoozed()[c.id].until))
        : st
          ? h_flex().gap(4).items_center().text_size(12).text_color(st.color).child(svg(I(st.icon)).size(13)).child(st.label)
          : div().text_size(12).text_color(C.dim).child(age(c.settled ? c.settled_at : c.changed_at));
    const short = c.settled || asleep;
    return v_flex()
      .id(`t4-row-${c.id}`)
      .mx(8)
      .px(10)
      .py(short ? 6 : 8)
      .gap(short ? 0 : 3)
      .rounded(10)
      .cursor_pointer()
      .when(here, (el) => el.bg(C.rowOn))
      .when(!here, (el) => el.hover((s) => s.bg(C.row)))
      .when(recede, (el) => el.opacity(0.62))
      .on_hover((h, cx) => {
        if (h) this.hover = c.id;
        else if (this.hover === c.id) this.hover = null;
        if (!h && this.snoozing === c.id) this.snoozing = null;
        cx.notify();
      })
      .on_click(() => run("tab.select", { id: c.id }))
      .on_mouse_down("right", () =>
        openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "tab", target: { id: c.id, space: w.id, settled: c.settled } } }),
      )
      .child(
        h_flex()
          .h(20)
          .gap(7)
          .items_center()
          .text_size(12)
          .text_color(C.dim)
          .child(div().w(8).h(8).rounded(2).flex_none().bg(spaceColor(t, pj.first)))
          .child(div().truncate().child(pj.name))
          .when(Boolean(pj.machine), (el) => el.child(div().flex_none().px(5).rounded(4).bg(C.row).text_size(11).child(pj.machine)))
          .child(div().flex_1())
          .when(pinned && !hovered, (el) => el.child(svg(I("pin")).size(12).text_color(C.dim)))
          .child(right),
      )
      .when(!short, (el) =>
        el
          .child(div().truncate().text_size(14).font_medium().text_color(here ? C.text : "#d4d4d8").child(c.name))
          .child(
            h_flex()
              .h(18)
              .gap(6)
              .items_center()
              .text_size(12)
              .text_color(C.dim)
              .when(Boolean(lead?.branch), (el) => el.child(svg(I("git-branch")).size(12)).child(div().flex_1().truncate().child(lead.branch)))
              .when(!lead?.branch, (el) => el.child(div().flex_1()))
              .when(Boolean(pr), (el) => el.child(this.badge(c, pr)))
              .children(programs.filter((p) => p.icon).slice(0, 3).map((p) => glyph(p, 14, C.muted))),
          ),
      )
      .when(short, (el) => el.child(div().truncate().text_size(13).text_color(C.muted).child(c.name)))
      .when(this.snoozing === c.id, (el) =>
        el.child(
          h_flex()
            .gap(4)
            .pt(4)
            .children(
              SNOOZE.map(([label, wake], i) =>
                this.button(`t4-sn-${c.id}-${i}`, label, null, () => {
                  this.snoozing = null;
                  this.snooze(c.id, wake());
                }),
              ),
            ),
        ),
      );
  }

  section(id, label, open, onClick) {
    return h_flex()
      .id(id)
      .mx(18)
      .mt(10)
      .mb(4)
      .gap(8)
      .items_center()
      .text_size(12)
      .text_color(C.dim)
      .cursor_pointer()
      .hover((s) => s.text_color(C.muted))
      .on_click(onClick)
      .child(label)
      .child(div().flex_1().h(1).bg(C.line))
      .child(svg(I(open ? "chevron-down" : "chevron-right")).size(13));
  }

  render(cx) {
    this.findRepos(cx);
    const t = theme();
    const all = panes();
    const ps = spaces();
    const scope = shared("t4.project");
    const every = ps.flatMap((w) => w.tabs.map((c) => ({ w, c, pj: this.project(w, c, all) })));
    const projects = [...new Map(every.map((r) => [r.pj.key, r.pj])).values()];
    const rows = every.filter((r) => !scope || r.pj.key === scope);
    const pins = this.pins();
    const awake = (r) => !r.c.settled && !this.asleep(r.c);
    const pinned = pins.map((id) => rows.find((r) => r.c.id === id && awake(r))).filter(Boolean);
    const active = rows.filter((r) => awake(r) && !pins.includes(r.c.id)).sort((a, b) => num(b.c.id) - num(a.c.id));
    const snoozed = rows.filter((r) => this.asleep(r.c)).sort((a, b) => this.snoozed()[a.c.id].until - this.snoozed()[b.c.id].until);
    const settled = rows.filter((r) => r.c.settled).sort((a, b) => (b.c.settled_at ?? 0) - (a.c.settled_at ?? 0));

    const tool = (id, icon, label, onClick) =>
      h_flex()
        .id(id)
        .mx(8)
        .px(10)
        .h(34)
        .gap(10)
        .items_center()
        .rounded(8)
        .text_size(14)
        .text_color(C.muted)
        .cursor_pointer()
        .hover((s) => s.bg(C.row).text_color(C.text))
        .on_click(onClick)
        .child(svg(I(icon)).size(16))
        .child(div().flex_1().child(label));

    return v_flex()
      .size_full()
      .bg(C.bg)
      .text_color(C.text)
      .pt(4)
      .child(
        h_flex()
          .child(div().flex_1().child(tool("t4-search", "search", "Search", () => run("mod.open", { name: "picker" }))))
          .child(
            this.button("t4-filter", "", "list-filter", () => {
              this.picking = !this.picking;
            }).when(Boolean(scope), (el) => el.text_color(C.working)),
          )
          .child(this.button("t4-add", "", "folder-plus", () => run("space.new")))
          .child(this.button("t4-new", "", "square-pen", () => run("mod.open", { name: "t4-new" })).mr(12)),
      )
      .when(this.picking, (el) =>
        el.children(
          [{ key: null, name: "All projects" }, ...projects].map((w) =>
            h_flex()
              .id(`t4-scope-${w.key ?? "all"}`)
              .mx(8)
              .pl(36)
              .h(28)
              .items_center()
              .rounded(8)
              .text_size(13)
              .text_color((scope ?? null) === w.key ? C.text : C.muted)
              .cursor_pointer()
              .hover((s) => s.bg(C.row))
              .on_click((_e, cx) => {
                setShared("t4.project", w.key);
                this.picking = false;
                cx.notify();
              })
              .child(w.name),
          ),
        ),
      )
      .child(
        v_flex()
          .flex_1()
          .min_h(0)
          .overflow_y_scrollbar()
          .pt(8)
          .gap(2)
          .children(pinned.map((r) => this.row(t, r, all)))
          .when(pinned.length > 0, (el) => el.child(div().mx(18).my(6).h(1).bg(C.line)))
          .children(active.map((r) => this.row(t, r, all)))
          .when(snoozed.length > 0, (el) =>
            el.child(
              this.section("t4-snoozed", `Snoozed (${snoozed.length})`, this.showSnoozed, (_e, cx) => {
                this.showSnoozed = !this.showSnoozed;
                cx.notify();
              }),
            ),
          )
          .when(this.showSnoozed, (el) => el.children(snoozed.map((r) => this.row(t, r, all))))
          .when(settled.length > 0, (el) =>
            el.child(
              this.section("t4-settled", `Settled (${settled.length})`, this.showSettled, (_e, cx) => {
                this.showSettled = !this.showSettled;
                cx.notify();
              }),
            ),
          )
          .when(this.showSettled, (el) => el.children(settled.map((r) => this.row(t, r, all))))
          .child(div().h(12)),
      )
      .child(
        h_flex()
          .h(44)
          .px(14)
          .gap(4)
          .items_center()
          .border_t(1)
          .border_color(C.line)
          .child(this.button("t4-settings", "", "settings", () => run("app.settings")))
          .child(this.button("t4-keys", "", "keyboard", () => run("app.help")))
          .child(this.button("t4-layout", "", "layers", () => run("layout.switch"))),
      );
  }
}
