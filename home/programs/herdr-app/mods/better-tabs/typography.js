// Herdr's mod API accepts px/rem, so resolve em-like multipliers from its live font settings.
import { settings } from "herdr";

export function em(multiplier = 1) {
  const config = settings();
  const base = Number(config.ui_font_size ?? config.font_size);
  return (Number.isFinite(base) && base > 0 ? base : 14) * multiplier;
}

export function codeFont() {
  const config = settings();
  return config.font_family ?? config.font ?? config.ui_font_family ?? config.ui_font;
}
