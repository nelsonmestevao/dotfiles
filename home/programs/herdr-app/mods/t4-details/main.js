// t4's thread details: a card floating over the terminal's
// top right, shown by the header's details toggle (shared "t4.details").
// For the shown thread's folder: where it is, open it in your editor, the
// branch, what changed (click: the right panel's diff), and commit / push /
// pull request (`git`, `gh`). An example: change EDITOR, the buttons, or
// what a commit does.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, panes, run, shared, setShared, exec, home, layout } from "herdr";

// The command that opens a folder in your editor.
const EDITOR = ["code"];
const C = { text: "#ececee", muted: "#a1a1aa", dim: "#71717a", line: "#26262b", row: "#1b1b1f", add: "#4ade80", del: "#f87171", field: "#0e0e10", accent: "#60a5fa" };
const I = (name) => `mods/t4-threads/${name}.svg`;
// Home as ~ (git says C:/Users/x where Windows says C:\Users\x).
const tilde = (path) => {
  if (!path) return "";
  const [p, h] = [path, home()].map((s) => s.replace(/\\/g, "/"));
  return p.startsWith(h) ? `~${p.slice(h.length)}` : path;
};

function shown(node, id) {
  if (!node) return false;
  if (node.id === id) return !node.hidden;
  return (node.children ?? []).some((c) => shown(c, id));
}

export default class Details extends View {
  init(_props, cx) {
    this.git = null; // { key, root, branch, add, del, files, ahead, upstream }
    this.message = "";
    this.typing = false;
    this.busy = "";
    this.note = "";
    this.handle = cx.focus_handle();
    this.refresh(cx);
    cx.timer.every(4000, (cx) => this.refresh(cx));
  }

  folder() {
    const p = spaces().find((x) => x.active);
    const c = p?.tabs.find((x) => x.active);
    const mine = panes().filter((x) => x.tab === c?.id && x.terminal);
    const lead = mine.find((x) => x.program?.agent) ?? mine[0];
    return lead?.cwd ?? p?.folder ?? null;
  }

  // The shown thread's folder and machine. `key` names the pair, and every
  // result is stamped with it, so the card never shows (or commits in) the
  // repo of a thread you've left.
  where() {
    const cwd = this.folder();
    const on = spaces().find((s) => s.active)?.machine;
    return { cwd, on, key: JSON.stringify([on ?? null, cwd]) };
  }

  // What's loaded for the shown thread, or null while it loads.
  current() {
    return this.git?.key === this.where().key ? this.git : null;
  }

  refresh(cx) {
    const { cwd, on, key } = this.where();
    if (shared("t4.details") !== true || !cwd || this.looking) return;
    this.looking = true;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (top.code !== 0) this.git = { key, root: null };
        else {
          const root = top.stdout.trim();
          const st = await exec("git", ["status", "--porcelain=v2", "--branch"], { cwd: root, on });
          const num = await exec("git", ["diff", "HEAD", "--numstat"], { cwd: root, on });
          const g = { key, root, on, branch: null, add: 0, del: 0, files: 0, ahead: 0, upstream: false };
          for (const l of st.stdout.split("\n")) {
            if (l.startsWith("# branch.head ")) g.branch = l.slice(14);
            else if (l.startsWith("# branch.upstream ")) g.upstream = true;
            else if (l.startsWith("# branch.ab ")) g.ahead = Math.abs(parseInt(l.slice(12), 10)) || 0;
            else if (l && !l.startsWith("#")) g.files++;
          }
          for (const l of num.stdout.split("\n").filter(Boolean)) {
            const [a, d] = l.split("\t");
            g.add += +a || 0;
            g.del += +d || 0;
          }
          if (this.where().key !== key) return;
          // A note about the thread you left doesn't belong to this one.
          if (this.git?.key !== key) this.note = "";
          this.git = g;
        }
      } catch (error) {
        // Stamped with the key, so render doesn't ask again at once: a deleted
        // folder or an offline machine would refresh and redraw in a tight
        // loop. The timer tries again in a few seconds.
        this.git = { key, root: null };
        this.note = String(error);
      }
      finally { this.looking = false; cx.notify(); }
    });
  }

  act(cx, label, steps) {
    if (this.busy || !this.current()?.root || this.looking) return;
    const { root, on } = this.git;
    this.busy = label;
    this.note = "";
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        for (const [cmd, args] of steps) {
          const r = await exec(cmd, args, { cwd: root, on });
          if (r.code !== 0) {
            this.note = (r.stderr || r.stdout || `${cmd} failed`).trim().split("\n").pop();
            break;
          }
        }
        if (!this.note && label === "Commit") this.message = "";
      } catch (error) { this.note = String(error); }
      this.busy = "";
      this.looking = false;
      this.refresh(cx);
      cx.notify();
    });
  }

  commit(cx) {
    const m = this.message.trim();
    if (!m) {
      this.typing = true;
      this.handle.focus();
      return;
    }
    this.act(cx, "Commit", [
      ["git", ["add", "-A"]],
      ["git", ["commit", "-m", m]],
    ]);
  }

  row(id, icon, label, right, onClick) {
    return h_flex()
      .id(id)
      .h(32)
      .px(10)
      .gap(10)
      .items_center()
      .rounded(8)
      .text_size(13)
      .text_color(C.text)
      .when(Boolean(onClick), (el) => el.cursor_pointer().hover((s) => s.bg(C.row)).on_click(onClick))
      .child(svg(I(icon)).size(15).text_color(C.muted))
      .child(div().flex_1().truncate().child(label))
      .when(Boolean(right), (el) => el.child(right));
  }

  small(id, label, onClick, on = true) {
    return div()
      .id(id)
      .px(10)
      .py(4)
      .rounded(7)
      .border_1()
      .border_color(C.line)
      .text_size(12)
      .text_color(on ? C.text : C.dim)
      .when(on, (el) => el.cursor_pointer().hover((s) => s.bg(C.row)).on_click(onClick))
      .child(this.busy === label ? `${label}…` : label);
  }

  render(cx) {
    if (shared("t4.details") !== true) return div();
    // Nothing loaded for this thread yet (just opened, or you switched): ask now.
    const g = this.current();
    if (!g) this.refresh(cx);
    const cwd = this.folder();
    const on = g?.on ?? spaces().find((s) => s.active)?.machine;
    const changed = g?.root && g.files > 0;
    return v_flex()
      .id("t4-details")
      .w(280)
      .p(6)
      .gap(2)
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (!this.typing) return;
        const m = e.modifiers;
        if (e.key === "enter") this.commit(cx);
        else if (e.key === "escape") this.typing = false;
        else if (e.key === "backspace") this.message = this.message.slice(0, -1);
        else if (e.key_char && !m.control && !m.platform) this.message += e.key_char;
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(this.row("td-where", "folder", tilde(g?.root ?? cwd), null, null))
      .when(!on, (el) => el.child(this.row("td-open", "external-link", `Open in ${EDITOR[0]}`, null, () => exec(EDITOR[0], [...EDITOR.slice(1), g?.root ?? cwd]))))
      .when(Boolean(g?.root), (el) =>
        el
          .child(div().mx(4).my(4).h(1).bg(C.line))
          .child(
            this.row(
              "td-branch",
              "git-branch",
              g.branch ?? "",
              g.ahead > 0 ? div().text_size(12).text_color(C.dim).child(`↑${g.ahead}`) : null,
              null,
            ),
          )
          .child(
            this.row(
              "td-changes",
              "file-diff",
              changed ? `Changes · ${g.files} file${g.files === 1 ? "" : "s"}` : "No changes",
              changed
                ? h_flex()
                    .gap(6)
                    .text_size(12)
                    .child(div().text_color(C.add).child(`+${g.add}`))
                    .child(div().text_color(C.del).child(`−${g.del}`))
                : null,
              changed
                ? () => {
                    if (!shown(layout(), "panel")) run("layout.show", { id: "panel" });
                    run("layout.select", { stack: "panel-body", child: "diff" });
                  }
                : null,
            ),
          )
          .when(Boolean(changed), (el) =>
            el.child(
              div()
                .id("td-message")
                .mx(4)
                .mt(4)
                .px(10)
                .py(7)
                .rounded(8)
                .border_1()
                .border_color(this.typing ? C.accent : C.line)
                .bg(C.field)
                .text_size(12)
                .cursor_text()
                .on_click((_e, cx) => {
                  this.typing = true;
                  this.handle.focus();
                  cx.notify();
                })
                .child(
                  this.message
                    ? div().text_color(C.text).child(this.message + (this.typing ? "▏" : ""))
                    : div().text_color(C.dim).child((this.typing ? "▏" : "") + "Commit message"),
                ),
            ),
          )
          .child(
            h_flex()
              .px(4)
              .pt(6)
              .pb(2)
              .gap(6)
              .child(this.small("td-commit", "Commit", (_e, cx) => this.commit(cx), Boolean(changed)))
              .child(this.small("td-push", "Push", (_e, cx) => this.act(cx, "Push", [["git", ["push", "-u", "origin", "HEAD"]]]), !changed && (g.ahead > 0 || !g.upstream)))
              .child(this.small("td-pr", "Pull request", (_e, cx) => this.act(cx, "Pull request", [["gh", ["pr", "create", "--fill", "--web"]]]), !changed)),
          )
          .when(Boolean(this.note), (el) => el.child(div().px(8).pt(4).text_size(11).text_color(C.del).child(this.note))),
      );
  }
}
