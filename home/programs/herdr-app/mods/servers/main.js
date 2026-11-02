import { View } from "gpui-kit";
import { props } from "herdr";
import { Panel } from "./panel.js";
import { Logs } from "./logs.js";

// The servers panel, or { view: "logs", machine, container } for a container's logs dialog.
export default class Servers extends View {
  init(_props, cx) {
    this.view = props()?.view === "logs" ? new Logs() : new Panel();
    this.view.init(props(), cx);
  }

  render(cx) {
    return this.view.render(cx);
  }
}
