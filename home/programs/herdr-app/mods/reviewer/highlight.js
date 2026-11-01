// A small line-by-line tokenizer for diff rows. tokenize(text, lang, state)
// returns { spans: [{ text, cls }], state } where cls is one of keyword,
// string, comment, number, function, type, boolean, variable, operator,
// punctuation or "" (plain). `state` carries an open block comment or
// triple-quoted string into the next line; pass null for the first line.

const words = (s) => new Set(s.split(/\s+/));

const JS_KW = words("abstract as async await break case catch class const continue debugger default delete do else enum export extends finally for from function get if implements import in instanceof interface let new of package private protected public return set static super switch throw try typeof var void while with yield declare type namespace readonly keyof satisfies");
const LANGS = {
  js: { kw: JS_KW, line: ["//"], block: ["/*", "*/"], quotes: ["\"", "'", "`"], self: words("this super") },
  rust: { kw: words("as async await break const continue crate dyn else enum extern fn for if impl in let loop match mod move mut pub ref return static struct super trait type unsafe use where while"), line: ["//"], block: ["/*", "*/"], quotes: ["\""], self: words("self Self") },
  python: { kw: words("and as assert async await break class continue def del elif else except finally for from global if import in is lambda nonlocal not or pass raise return try while with yield"), line: ["#"], block: null, triple: ["\"\"\"", "'''"], quotes: ["\"", "'"], self: words("self cls") },
  go: { kw: words("break case chan const continue default defer else fallthrough for func go goto if import interface map package range return select struct switch type var"), line: ["//"], block: ["/*", "*/"], quotes: ["\"", "'", "`"], self: words("") },
  c: { kw: words("auto break case char const continue default do double else enum extern float for goto if inline int long register return short signed sizeof static struct switch typedef union unsigned void volatile while class namespace new delete template typename public private protected virtual override using try catch throw bool constexpr friend operator explicit mutable noexcept"), line: ["//"], block: ["/*", "*/"], quotes: ["\"", "'"], self: words("this"), hash: true },
  java: { kw: words("abstract assert boolean break byte case catch char class const continue default do double else enum extends final finally float for if implements import instanceof int interface long native new package private protected public return short static strictfp super switch synchronized throw throws transient try void volatile while var record sealed permits yield fun val when object data companion override open internal is in suspend"), line: ["//"], block: ["/*", "*/"], quotes: ["\"", "'"], self: words("this super") },
  ruby: { kw: words("alias and begin break case class def do else elsif end ensure for if in module next not or redo rescue retry return super then undef unless until when while yield require include extend attr_accessor attr_reader attr_writer private public protected raise"), line: ["#"], block: ["=begin", "=end"], quotes: ["\"", "'"], self: words("self") },
  php: { kw: words("abstract and array as break callable case catch class clone const continue declare default do echo else elseif extends final finally fn for foreach function global if implements include instanceof interface isset list namespace new or print private protected public require return static switch throw trait try unset use var while xor yield match readonly enum"), line: ["//", "#"], block: ["/*", "*/"], quotes: ["\"", "'"], self: words("this self"), dollar: true },
  sh: { kw: words("if then else elif fi for while until do done case esac in function select time return exit export local readonly declare unset shift source alias set trap"), line: ["#"], block: null, quotes: ["\"", "'"], self: words(""), dollar: true, noType: true },
  sql: { kw: words("select from where and or not in is null as join inner left right outer full cross on group by order having limit offset insert into values update set delete create table index view drop alter add column primary key foreign references unique default constraint union all distinct exists between like case when then else end begin commit rollback with returning asc desc if replace truncate"), line: ["--"], block: ["/*", "*/"], quotes: ["'", "\""], self: words(""), ci: true, noType: true },
  css: { kw: words("important media import keyframes font-face supports"), line: [], block: ["/*", "*/"], quotes: ["\"", "'"], self: words(""), noType: true },
  html: { kw: words(""), line: [], block: ["<!--", "-->"], quotes: ["\"", "'"], self: words(""), tags: true, noType: true },
  yaml: { kw: words(""), line: ["#"], block: null, quotes: ["\"", "'"], self: words(""), noType: true, keys: true },
  json: { kw: words(""), line: [], block: null, quotes: ["\""], self: words(""), noType: true },
  swift: { kw: words("associatedtype class deinit enum extension fileprivate func import init inout internal let open operator private protocol public rethrows static struct subscript typealias var break case continue default defer do else fallthrough for guard if in repeat return switch where while as catch is throw throws try some any actor async await"), line: ["//"], block: ["/*", "*/"], quotes: ["\""], self: words("self Self super") },
};
const EXT = { js: "js", jsx: "js", mjs: "js", cjs: "js", ts: "js", tsx: "js", mts: "js", cts: "js", vue: "html", svelte: "html",
  rs: "rust", py: "python", pyi: "python", go: "go", c: "c", h: "c", cpp: "c", cc: "c", cxx: "c", hpp: "c", hh: "c", m: "c", mm: "c", cs: "java",
  java: "java", kt: "java", kts: "java", scala: "java", groovy: "java", rb: "ruby", rake: "ruby", php: "php", sh: "sh", bash: "sh", zsh: "sh", fish: "sh",
  sql: "sql", css: "css", scss: "css", less: "css", html: "html", htm: "html", xml: "html", svg: "html", yml: "yaml", yaml: "yaml", toml: "yaml",
  json: "json", jsonc: "json", swift: "swift" };
const BOOL = words("true false null undefined NaN Infinity None True False nil nullptr NULL TRUE FALSE");
const PUNCT = new Set("()[]{},;");
const OPS = new Set("+-*/%=<>!&|^~?:.@");
const MAX = 600, MAX_SPANS = 24;
// Classes that get a span of their own; the rest stay plain so a row is few elements.
const KEEP = new Set(["keyword", "string", "string.escape", "comment", "number", "function", "type", "boolean", "variable"]);

/** The tokenizer language for a file path, or null when the file gets no colors. */
export function languageOf(path) {
  const name = (path ?? "").split("/").pop().toLowerCase();
  if (name === "dockerfile" || name === "makefile") return "sh";
  const ext = name.includes(".") ? name.split(".").pop() : "";
  return EXT[ext] ?? null;
}

const isWord = (c) => /[A-Za-z0-9_$]/.test(c);

export function tokenize(text, lang, state) {
  const L = LANGS[lang];
  if (!L) return { spans: [{ text, cls: "" }], state: null };
  const spans = [];
  const push = (t, cls) => {
    if (!t) return;
    if (!KEEP.has(cls) || (spans.length >= MAX_SPANS && cls !== spans[spans.length - 1]?.cls)) cls = "";
    if (cls === "string.escape") cls = "string";
    const last = spans[spans.length - 1];
    if (last && last.cls === cls) last.text += t; else spans.push({ text: t, cls });
  };
  let i = 0, prev = "";
  const n = Math.min(text.length, MAX);
  if (state) {
    const end = text.indexOf(state.close);
    if (end < 0) { push(text, state.cls); return { spans, state }; }
    push(text.slice(0, end + state.close.length), state.cls);
    i = end + state.close.length; prev = "x"; state = null;
  }
  // A YAML key or a preprocessor line is decided at the line's start.
  if (L.keys) { const m = /^(\s*-?\s*)([\w.\-/]+)(\s*:)(\s|$)/.exec(text); if (m) { push(m[1], ""); push(m[2], "variable"); push(m[3], "punctuation"); i = m[1].length + m[2].length + m[3].length; } }
  if (L.hash && /^\s*#/.test(text)) { push(text, "keyword"); return { spans, state: null }; }
  while (i < n) {
    const c = text[i];
    if (/\s/.test(c)) { let j = i; while (j < n && /\s/.test(text[j])) j++; push(text.slice(i, j), ""); i = j; continue; }
    const lc = L.line.find((s) => text.startsWith(s, i));
    if (lc && !(lang === "sql" && false)) { push(text.slice(i), "comment"); return { spans, state: null }; }
    if (L.block && text.startsWith(L.block[0], i)) {
      const end = text.indexOf(L.block[1], i + L.block[0].length);
      if (end < 0) { push(text.slice(i), "comment"); return { spans, state: { close: L.block[1], cls: "comment" } }; }
      push(text.slice(i, end + L.block[1].length), "comment"); i = end + L.block[1].length; prev = "/"; continue;
    }
    const triple = L.triple?.find((q) => text.startsWith(q, i));
    if (triple) {
      const end = text.indexOf(triple, i + 3);
      if (end < 0) { push(text.slice(i), "string"); return { spans, state: { close: triple, cls: "string" } }; }
      push(text.slice(i, end + 3), "string"); i = end + 3; prev = "\""; continue;
    }
    if (L.quotes.includes(c)) {
      let j = i + 1;
      while (j < text.length && text[j] !== c) { if (text[j] === "\\") j++; j++; }
      const s = text.slice(i, Math.min(j + 1, text.length));
      // Escapes inside the string get their own class.
      for (const part of s.split(/(\\.)/)) push(part, part.length === 2 && part[0] === "\\" ? "string.escape" : "string");
      i = j + 1; prev = "\""; continue;
    }
    if (L.tags && c === "<") {
      const m = /^<\/?[A-Za-z][\w:-]*/.exec(text.slice(i));
      if (m) { push(m[0], "keyword"); i += m[0].length; prev = "<"; continue; }
    }
    if (L.dollar && c === "$") { const m = /^\$\{?[\w@#?*!-]+\}?/.exec(text.slice(i)); if (m) { push(m[0], "variable"); i += m[0].length; prev = "$"; continue; } }
    if (/[0-9]/.test(c) && !isWord(prev)) {
      const m = /^(0[xXbBoO][0-9a-fA-F_]+|\d[\d_]*(\.\d[\d_]*)?([eE][+-]?\d+)?)[a-zA-Z0-9_]*/.exec(text.slice(i));
      push(m[0], "number"); i += m[0].length; prev = "0"; continue;
    }
    if (/[A-Za-z_$]/.test(c)) {
      let j = i + 1; while (j < n && isWord(text[j])) j++;
      if (lang === "ruby" && (text[j] === "?" || text[j] === "!")) j++;
      const w = text.slice(i, j), key = L.ci ? w.toLowerCase() : w;
      let k = j; while (k < n && text[k] === " ") k++;
      let cls = "";
      if (L.kw.has(key)) cls = "keyword";
      else if (BOOL.has(w)) cls = "boolean";
      else if (L.self.has(w)) cls = "variable";
      else if (text[k] === "(" || (lang === "ruby" && prev === ".")) cls = "function";
      else if (!L.noType && /^[A-Z]/.test(w) && !/^[A-Z0-9_]+$/.test(w)) cls = "type";
      else if (!L.noType && /^[A-Z][A-Z0-9_]+$/.test(w)) cls = "boolean";
      else if (lang === "css" && (prev === "." || prev === "#")) cls = "type";
      push(w, cls); i = j; prev = w[w.length - 1]; continue;
    }
    if (lang === "css" && c === "#" && /^#[0-9a-fA-F]{3,8}\b/.test(text.slice(i))) { const m = /^#[0-9a-fA-F]{3,8}/.exec(text.slice(i)); push(m[0], "number"); i += m[0].length; prev = "#"; continue; }
    if (PUNCT.has(c)) { push(c, "punctuation"); i++; prev = c; continue; }
    if (OPS.has(c)) { let j = i; while (j < n && OPS.has(text[j])) j++; push(text.slice(i, j), "operator"); i = j; prev = text[j - 1]; continue; }
    push(c, ""); i++; prev = c;
  }
  if (text.length > MAX) push(text.slice(MAX), "");
  return { spans, state: null };
}
