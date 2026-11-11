// t4's new thread: what it's about, the project, the
// current checkout or a new worktree, and the agent. Enter starts it as a
// tab with the agent running in its terminal; you talk to it there. A new
// worktree goes through the `worktree` mod (branch named after the
// thread). Projects are repos, worked out from git; a space outside git is
// its own. ctrl+P project, ctrl+W checkout, ctrl+A agent, Esc closes.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, machines, run, theme, props, closeOverlay, openOverlay, shared, setShared, exec } from "herdr";

// Name on the chip, and the command. Edit to taste.
const AGENTS = [
  ["Claude", ["claude"]],
  ["Codex", ["codex"]],
  ["Pi", ["pi"]],
  ["Grok", ["grok"]],
  ["shell", null],
];
const MAX_NAME = 48;
const branchOf = (name) =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9._/-]+/g, "-")
    .replace(/^-+|-+$/g, "");

// Space colors, kept by space id in shared "space.colors" (the same code
// in every mod that colors spaces, so they agree).
const PROJECT_COLORS = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
// Ids from another machine start with its name ("temis/sp…"). A space
// missing on a machine whose spaces haven't loaded, or can't (offline), is
// only missing for now: keep what's stored for it.
function loaded(id) {
  const name = id.includes("/") ? id.split("/")[0] : null;
  return machines().find((m) => (m.name ?? null) === name)?.layout === "ready";
}
function spaceColors() {
  const ids = new Set(spaces().map((p) => p.id));
  // Forget a space only when its machine is loaded and it's gone, or an
  // offline machine's spaces lose their colors and come back with new ones.
  const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id) || !loaded(id)));
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

export default class NewThread extends View {
  init(_props, cx) {
    this.name = "";
    // The space you picked, not a place in the list: the list changes when
    // the git lookups below finish (a repo's spaces merge into one entry),
    // and a place would then point at another project. Null: the first.
    this.picked = null;
    this.agent = Math.max(0, AGENTS.findIndex(([n]) => n === localStorage.getItem("agent")));
    this.worktree = localStorage.getItem("worktree") === "yes";
    this.repos = {}; // folder -> { key, name, main } | null
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.spawn(async (cx) => {
      for (const s of spaces()) {
        try {
          const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: s.folder, on: s.machine });
          const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: s.folder, on: s.machine });
          if (top.code !== 0 || common.code !== 0) continue;
          const key = common.stdout.trim();
          const main = key.endsWith("/.git") ? key.slice(0, -5) : key;
          this.repos[JSON.stringify([s.machine ?? null, s.folder])] = { key: JSON.stringify([s.machine ?? null, key]), name: main.split("/").pop(), main: main === top.stdout.trim() };
        } catch {}
      }
      cx.notify();
    });
  }

  // One entry per project: its repo's main-checkout space (else the first),
  // the shown space's project first. `members`: the ids of all its spaces.
  projects() {
    const out = new Map();
    const list = spaces();
    const ordered = [...list.filter((s) => s.active), ...list.filter((s) => !s.active)];
    for (const s of ordered) {
      const r = this.repos[JSON.stringify([s.machine ?? null, s.folder])];
      const key = r?.key ?? s.id;
      const have = out.get(key);
      if (!have) out.set(key, { key, name: r?.name ?? s.name, space: s, git: Boolean(r), members: [s.id] });
      else {
        have.members.push(s.id);
        if (r?.main && !this.repos[JSON.stringify([have.space.machine ?? null, have.space.folder])]?.main) have.space = s;
      }
    }
    return [...out.values()];
  }

  // The project of the space you picked, else the first.
  current(ps = this.projects()) {
    return ps.find((p) => p.members.includes(this.picked)) ?? ps[0];
  }

  close() {
    closeOverlay(props().overlay);
  }

  start() {
    const name = this.name.trim();
    if (!name) {
      this.nudge = true;
      return;
    }
    const p = this.current();
    if (!p) return;
    const [label, argv] = AGENTS[this.agent];
    localStorage.setItem("agent", label);
    localStorage.setItem("worktree", this.worktree ? "yes" : "no");
    this.close();
    if (this.worktree && p.git)
      openOverlay({
        mod: "worktree",
        kind: "dialog",
        width: 440,
        height: 190,
        props: { space: p.space.id, action: "new", branch: branchOf(name), tab: name, argv: argv ?? undefined },
      });
    else run("tab.new", { space: p.space.id, argv: argv ?? undefined, name });
  }

  chip(t, id, label, on, onClick, color) {
    return h_flex()
      .id(id)
      .gap(6)
      .items_center()
      .px(10)
      .py(4)
      .rounded(7)
      .cursor_pointer()
      .bg(on ? t.hover : t.raised)
      .text_color(on ? t.foreground : t.muted)
      .when(on, (el) => el.border_1().border_color(t.border))
      .hover((s) => s.text_color(t.foreground))
      .on_click(onClick)
      .when(Boolean(color), (el) => el.child(div().w(8).h(8).rounded(2).bg(color)))
      .child(label);
  }

  render() {
    const t = theme();
    const ps = this.projects();
    const p = this.current(ps);
    const git = Boolean(p?.git);
    const key = (k) => div().px(5).rounded(4).border_1().border_color(t.border).text_color(t.dim).child(k);
    const hint = (k, what) => h_flex().gap(5).items_center().child(key(k)).child(div().child(what));
    const row = (label, ...chips) =>
      h_flex()
        .gap(6)
        .items_center()
        .flex_wrap()
        .child(div().w(72).flex_none().text_color(t.dim).child(label))
        .children(chips);
    const pick = (field, i) => (_e, cx) => {
      this[field] = i;
      cx.notify();
    };
    return v_flex()
      .id("t4-new")
      .track_focus(this.handle)
      .w_full()
      .bg(t.popover)
      .on_key_down((e, cx) => {
        const k = e.key;
        const m = e.modifiers;
        if (k === "escape") return this.close();
        if (k === "enter") this.start();
        else if (k === "p" && m.control) {
          // The list as it is now: lookups may have finished since this render.
          const now = this.projects();
          this.picked = now[(now.indexOf(this.current(now)) + 1) % Math.max(1, now.length)]?.space.id ?? null;
        }
        else if (k === "a" && m.control) this.agent = (this.agent + 1) % AGENTS.length;
        else if (k === "w" && m.control) this.worktree = !this.worktree;
        else if (k === "backspace") this.name = this.name.slice(0, -1);
        else if (e.key_char && !m.control && !m.alt) {
          if (this.name.length < MAX_NAME) this.name += e.key_char;
          this.nudge = false;
        } else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(
        div()
          .px(18)
          .pt(18)
          .pb(14)
          .text_size(20)
          .border_b(1)
          .border_color(t.border)
          .child(
            this.name
              ? div().text_color(t.foreground).child(this.name + "▏")
              : div()
                  .text_color(this.nudge ? t.blocked : t.dim)
                  .child(`▏What should we build${p ? ` in ${p.name}` : ""}?`),
          ),
      )
      .child(
        v_flex()
          .px(18)
          .py(12)
          .gap(10)
          .border_b(1)
          .border_color(t.border)
          .text_size(12)
          .child(
            row(
              "Project",
              ...ps.map((x, i) =>
                this.chip(t, `tn-p${i}`, x.name, x === p, (_e, cx) => {
                  this.picked = x.space.id;
                  cx.notify();
                }, spaceColor(t, x.space)),
              ),
            ),
          )
          .when(git, (el) =>
            el.child(
              row(
                "Checkout",
                this.chip(t, "tn-cur", "Current checkout", !this.worktree, pick("worktree", false)),
                this.chip(t, "tn-wt", "New worktree", this.worktree, pick("worktree", true)),
              ),
            ),
          )
          .child(row("Agent", ...AGENTS.map(([n], i) => this.chip(t, `tn-a${i}`, n, i === this.agent, pick("agent", i))))),
      )
      .child(
        h_flex()
          .px(18)
          .py(9)
          .gap(16)
          .text_size(11)
          .text_color(t.dim)
          .child(hint("enter", "start"))
          .child(hint("ctrl+p", "project"))
          .when(git, (el) => el.child(hint("ctrl+w", "checkout")))
          .child(hint("ctrl+a", "agent"))
          .child(hint("esc", "cancel"))
          .when(git && this.worktree && Boolean(this.name.trim()), (el) =>
            el.child(div().flex_1()).child(div().truncate().child(`branch ${branchOf(this.name.trim())}`)),
          ),
      );
  }
}
