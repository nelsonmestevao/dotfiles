// Tells the person when a newer release is out. At most once a day, one GET to
// GitHub's public releases API: no token, nothing about the person or their
// repositories. "Stop checking" in the update window turns it off for good, and
// CHECK = false turns it off before it ever asks.
import { div } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { props, shared, setShared, closeOverlay, openOverlay, theme, settings } from "herdr";

export const VERSION = "0.3.0";
const CHECK = true;
const REPO = "rabeeh-ta/herdr-git-graph";
const DAY = 24 * 60 * 60 * 1000;
export const PROMPT = `Update the git-graph mod from github.com/${REPO}`;

// a > b for tags like v1.2.3.
export function newer(a, b) {
  const parts = (v) => String(v).replace(/^v/, "").split(".").map((n) => parseInt(n, 10) || 0);
  const [x, y] = [parts(a), parts(b)];
  for (let i = 0; i < 3; i++) if ((x[i] ?? 0) !== (y[i] ?? 0)) return (x[i] ?? 0) > (y[i] ?? 0);
  return false;
}

// Kept in shared state: it lasts across restarts and every graph copy sees it.
// A result saved for another repository (a fork, a test) counts as never checked.
const state = () => { const s = shared("git-graph.update") ?? {}; return s.repo === REPO ? s : { off: s.off }; };
const save = (change) => setShared("git-graph.update", { ...state(), ...change, repo: REPO });

// The release to offer, or null.
export function available() {
  const s = state();
  if (!CHECK || s.off || !s.latest || !newer(s.latest.tag, VERSION) || s.dismissed === s.latest.tag) return null;
  return s.latest;
}

export async function check() {
  const s = state();
  if (!CHECK || s.off || Date.now() - (s.checked ?? 0) < DAY) return;
  save({ checked: Date.now() }); // before asking, so the other copies don't ask too
  try {
    const r = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, { headers: { Accept: "application/vnd.github+json", "User-Agent": "herdr-git-graph" } });
    if (!r.ok) return;
    const j = await r.json();
    if (typeof j?.tag_name !== "string") return;
    const url = String(j.html_url ?? "");
    save({ latest: { tag: j.tag_name, notes: String(j.body ?? "").slice(0, 3000),
      url: url.startsWith(`https://github.com/${REPO}/`) ? url : `https://github.com/${REPO}/releases` } });
  } catch {}
}

export function openUpdate() {
  openOverlay({ mod: "git-graph", kind: "dialog", width: 460, height: 400, props: { role: "update" } });
}

// The update window, opened with props { role: "update" }.
export class Update {
  init(cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  render() {
    const t = theme(), latest = state().latest, close = () => closeOverlay(props().overlay);
    const button = (id, text, primary, action) => h_flex().id(id).h(32).px(14).items_center().rounded(8).border_1()
      .border_color(primary ? t.solid : t.input).bg(primary ? t.solid : t.raised)
      .text_color(primary ? t.solid_foreground : t.foreground).text_size(12.5).font_medium().cursor_pointer()
      .hover((st) => st.opacity(0.88)).on_click(action).child(text);
    return v_flex().id("git-graph-update").track_focus(this.handle).size_full().min_h(0).p(18).bg(t.popover).text_color(t.foreground).text_size(12.8)
      .on_key_down((e, cx) => { if (e.key === "escape") { close(); cx.stop_propagation(); } })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().child(`Git Graph ${latest?.tag ?? ""} is out`))
        .child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(div().pt(6).text_color(t.muted).child(`You have v${VERSION}. To update, ask your Herdr agent:`))
      .child(div().mt(8).px(10).py(8).rounded(8).bg(t.background).border_1().border_color(t.border).font_family(settings().font_family ?? "JetBrains Mono").text_size(12).child(PROMPT))
      .child(div().pt(14).pb(6).text_size(11.5).text_color(t.dim).child("What changed"))
      // Release notes are markdown; links open in the browser.
      .child(div().flex_1().min_h(0).text_size(12).text_color(t.muted)
        .child(TextView.markdown("gu-notes", latest?.notes?.trim() || "See the release page.").scrollable(true).selectable(true).size_full()))
      .child(h_flex().pt(14).gap(8).items_center()
        .child(div().id("gu-stop").text_size(12).text_color(t.dim).cursor_pointer().hover((st) => st.text_color(t.foreground))
          .on_click(() => { save({ off: true }); close(); }).child("Stop checking"))
        .child(div().flex_1())
        .child(button("gu-later", "Later", false, () => { save({ dismissed: latest?.tag }); close(); }))
        .child(button("gu-page", "Release page", false, (_e, cx) => cx.open_url(latest?.url ?? `https://github.com/${REPO}/releases`)))
        .child(button("gu-copy", "Copy prompt", true, (_e, cx) => { cx.write_to_clipboard(PROMPT); close(); })));
  }
}
