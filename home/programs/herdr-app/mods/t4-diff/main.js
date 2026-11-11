// t4's diff panel: what changed in the shown tab's folder
// since the last commit (staged, unstaged and new files). The top says the
// totals; each file says how much changed; click one to read its diff,
// colored. Refreshes every few seconds while shown. The Diff surface of
// the layout's right panel (the header's panel toggle shows it).

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, focused, settings, readTextFile } from "herdr";

const C = { bg: "#0b0b0d", text: "#ececee", muted: "#a1a1aa", dim: "#71717a", line: "#1f1f23", row: "#18181b", add: "#4ade80", del: "#f87171", addBg: "#14532d40", delBg: "#7f1d1d40", hunk: "#60a5fa" };
const MAX_LINES = 1500;

export default class Diff extends View {
  init(_props, cx) {
    this.files = [];
    this.open = null;
    this.lines = [];
    this.error = null;
    this.busy = false;
    this.refresh(cx);
    cx.timer.every(3000, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    const f = focused();
    const cwd = f?.cwd;
    const on = f?.terminal?.includes("/") ? f.terminal.split("/")[0] : undefined;
    if (!cwd || this.busy) return;
    this.busy = true;
    cx.spawn(async (cx) => {
      try {
        if (cwd !== this.cwd || on !== this.on) {
          this.cwd = cwd;
          this.on = on;
          this.open = null;
          this.lines = [];
        }
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (top.code !== 0) {
          this.files = [];
          this.error = "not a git folder";
          return;
        }
        this.root = top.stdout.trim();
        const stat = await exec("git", ["diff", "HEAD", "--numstat"], { cwd: this.root, on: this.on });
        const files = stat.stdout
          .split("\n")
          .filter(Boolean)
          .map((l) => {
            const [a, d, ...p] = l.split("\t");
            return { path: p.join("\t"), add: a === "-" ? 0 : +a, del: d === "-" ? 0 : +d, binary: a === "-" };
          });
        const fresh = await exec("git", ["ls-files", "--others", "--exclude-standard"], { cwd: this.root, on: this.on });
        for (const path of fresh.stdout.split("\n").filter(Boolean)) files.push({ path, add: 0, del: 0, fresh: true });
        this.files = files;
        this.error = null;
        if (this.open) await this.load(this.open);
      } catch (error) { this.files = []; this.error = String(error); }
      finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  async load(path) {
    const f = this.files.find((x) => x.path === path);
    if (!f) {
      this.open = null;
      this.lines = [];
      return;
    }
    // A new file is all added: read it here (no /dev/null on Windows).
    if (f.fresh) {
      const text = (await readTextFile(`${this.root}/${path}`, { on: this.on })) ?? "";
      const body = text.replace(/\n$/, "").split("\n");
      this.lines = [`@@ new file, ${body.length} lines @@`, ...body.map((l) => `+${l}`)].slice(0, MAX_LINES);
      return;
    }
    const r = await exec("git", ["diff", "HEAD", "--", path], { cwd: this.root, on: this.on });
    // Skip the header down to the first hunk.
    const all = r.stdout.split("\n");
    const start = all.findIndex((l) => l.startsWith("@@"));
    this.lines = (start < 0 ? [] : all.slice(start)).slice(0, MAX_LINES);
  }

  pick(path, cx) {
    this.open = this.open === path ? null : path;
    cx.spawn(async (cx) => {
      if (this.open) await this.load(this.open);
      else this.lines = [];
      cx.notify();
    });
  }

  line(l, i) {
    const k = l[0];
    const color = k === "+" ? C.add : k === "-" ? C.del : k === "@" ? C.hunk : C.muted;
    return div()
      .px(12)
      .min_h(18)
      .when(k === "+", (el) => el.bg(C.addBg))
      .when(k === "-", (el) => el.bg(C.delBg))
      .when(k === "@", (el) => el.mt(i ? 6 : 0))
      .text_color(color)
      .child(l || " ");
  }

  render(cx) {
    const add = this.files.reduce((n, f) => n + f.add, 0);
    const del = this.files.reduce((n, f) => n + f.del, 0);
    const name = (p) => p.split("/").pop();
    const dir = (p) => (p.includes("/") ? p.slice(0, p.lastIndexOf("/") + 1) : "");
    return v_flex()
      .size_full()
      .bg(C.bg)
      .text_color(C.text)
      .child(
        h_flex()
          .h(36)
          .flex_none()
          .px(16)
          .gap(10)
          .items_center()
          .border_b(1)
          .border_color(C.line)
          .child(div().flex_1().text_size(12).text_color(C.dim).truncate().child(this.root ? `Changes in ${this.root.split("/").pop()}` : ""))
          .when(this.files.length > 0, (el) =>
            el
              .when(add > 0, (el) => el.child(div().text_size(12).text_color(C.add).child(`+${add}`)))
              .when(del > 0, (el) => el.child(div().text_size(12).text_color(C.del).child(`\u2212${del}`))),
          ),
      )
      .when(Boolean(this.error), (el) => el.child(div().p(16).text_size(13).text_color(C.dim).child(this.error)))
      .when(!this.error && this.files.length === 0, (el) => el.child(div().p(16).text_size(13).text_color(C.dim).child("No changes since the last commit.")))
      .child(
        v_flex()
          .flex_1()
          .min_h(0)
          .overflow_y_scrollbar()
          .py(6)
          .children(
            this.files.flatMap((f) => {
              const on = f.path === this.open;
              const row = h_flex()
                .id(`df-${f.path}`)
                .mx(6)
                .px(10)
                .h(28)
                .gap(8)
                .items_center()
                .rounded(6)
                .text_size(13)
                .cursor_pointer()
                .when(on, (el) => el.bg(C.row))
                .hover((s) => s.bg(C.row))
                .on_click((_e, cx) => this.pick(f.path, cx))
                .child(svg(`mods/t4-threads/${on ? "chevron-down" : "chevron-right"}.svg`).size(13).text_color(C.dim))
                .child(
                  h_flex()
                    .flex_1()
                    .min_w(0)
                    .child(div().truncate().text_color(C.dim).child(dir(f.path)))
                    .child(div().flex_none().text_color(C.text).child(name(f.path))),
                )
                .when(Boolean(f.fresh), (el) => el.child(div().text_size(11).text_color(C.add).child("new")))
                .when(Boolean(f.binary), (el) => el.child(div().text_size(11).text_color(C.dim).child("binary")))
                .when(f.add > 0, (el) => el.child(div().text_size(12).text_color(C.add).child(`+${f.add}`)))
                .when(f.del > 0, (el) => el.child(div().text_size(12).text_color(C.del).child(`\u2212${f.del}`)));
              if (!on) return [row];
              const body = v_flex()
                .mx(6)
                .my(4)
                .py(6)
                .rounded(6)
                .border_1()
                .border_color(C.line)
                .font_family(settings().font_family ?? "JetBrains Mono")
                .text_size(12)
                .children(this.lines.map((l, i) => this.line(l, i)))
                .when(this.lines.length >= MAX_LINES, (el) => el.child(div().px(12).pt(6).text_color(C.dim).child("\u2026 more lines not shown")));
              return [row, body];
            }),
          ),
      );
  }
}
