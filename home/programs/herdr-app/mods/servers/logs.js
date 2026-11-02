import { div } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState } from "gpui-base";
import { exec, theme, props, closeOverlay, settings } from "herdr";

const TAIL = "300";
const TIMEOUT_S = 15;
const TIMED_OUT = 124;
// The container name reaches docker as "$1", never as shell text. docker logs can hang (seen right
// after a log rotation), so it gets a deadline where the machine has timeout(1).
const LOGS = `docker logs --tail ${TAIL} --timestamps -- "$1" 2>&1`;
// Terminal colors (ESC [ … m) would show as junk in the viewer.
const ANSI = /\u001b\[[0-9;?]*[A-Za-z]/g;
const LOGS_SCRIPT = `if command -v timeout >/dev/null 2>&1; then timeout ${TIMEOUT_S} ${LOGS}; else ${LOGS}; fi`;

// A container's last lines, newest first (the viewer can't scroll itself to the end).
export class Logs {
  init(p, cx) {
    this.machine = p?.machine ?? null; this.container = p?.container ?? "";
    this.editor = EditorState.new({ value: "Loading…", readonly: true, line_numbers: false, folding: false, font_size: 11.5, font_family: settings().font_family });
    if (this.container) this.load(cx);
    else this.editor.set_value("Open this from a container in the Servers panel.");
  }

  load(cx) {
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("sh", ["-c", LOGS_SCRIPT, "sh", this.container], { on: this.machine });
        if (r.code === TIMED_OUT) { this.editor.set_value(`docker logs didn't answer in ${TIMEOUT_S} s. Try Refresh, or run docker logs on ${this.machine ?? "this computer"} to see why.`); return; }
        const lines = (r.stdout || r.stderr || "").replace(ANSI, "").trimEnd().split("\n").reverse();
        this.editor.set_value(lines.join("\n") || "(no output)");
      } catch (e) { this.editor.set_value(`Could not read logs: ${e}`); }
      finally { this.loading = false; cx.notify(); }
    });
    cx.notify();
  }

  button(id, label, onClick, t) {
    return div().id(id).h(26).px(10).flex().items_center().rounded(7).cursor_pointer().text_size(11.5).text_color(t.muted)
      .hover((s) => s.bg(t.hover)).on_click((_e, cx) => onClick(cx)).child(label);
  }

  render() {
    const t = theme();
    return v_flex().id("logs").size_full().min_h(0).bg(t.popover).text_color(t.foreground).text_size(12.5)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child(this.container))
        .child(div().text_color(t.dim).child(`${this.machine ?? "This computer"} · last ${TAIL} lines, newest first`))
        .child(div().flex_1())
        .child(this.button("logs-refresh", this.loading ? "…" : "Refresh", (cx) => this.load(cx), t))
        .child(this.button("logs-close", "Close", () => closeOverlay(props().overlay), t)))
      .child(Editor.new(this.editor).flex_1().min_h(0));
  }
}
