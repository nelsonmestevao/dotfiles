// A small, line-at-a-time syntax tokenizer for diff rows. No Herdr imports (node-testable).
// Lines are coloured on their own, so a comment or string that spans lines is approximate.
const KEYWORDS = new Set(("break case catch class const continue debugger default delete do else enum export extends finally for from function if implements import in instanceof interface let new of package private protected public readonly return static super switch this throw try type typeof var void while with yield async await as is keyof declare namespace abstract override " +
  "def elif except lambda pass raise del global nonlocal and or not " +
  "fn pub mut impl trait struct use mod match loop where crate unsafe move ref " +
  "func go chan defer range select package fun val when object companion data sealed suspend override open internal inline " +
  "int long float double char bool boolean string void").split(" "));
const CONSTANTS = new Set(["true", "false", "null", "undefined", "None", "True", "False", "nil", "NaN", "Infinity"]);
const HASH = new Set(["py", "sh", "bash", "zsh", "yaml", "yml", "toml", "rb", "conf", "env", "gitignore", "dockerfile", "makefile", "mk", "ini"]);
const NO_KEYWORDS = new Set(["json", "md", "txt", "lock", "csv"]);
const RE = /(\/\/.*|\/\*.*?\*\/|\/\*.*|^\s*\*.*)|("(?:[^"\\]|\\.)*"?|'(?:[^'\\]|\\.)*'?|`(?:[^`\\]|\\.)*`?)|(\b0x[\da-fA-F]+\b|\b\d[\d_]*(?:\.\d+)?(?:e[+-]?\d+)?\b)|([A-Za-z_$][\w$]*)|(<\/?|\/?>|=>|[{}()[\];,.:?!&|=<>+\-*/%^~@#]+)|(\s+)/g;
const HASH_RE = new RegExp(RE.source.replace("(\\/\\/.*|", "(#.*|\\/\\/.*|"), "g");

export const extOf = (path) => {
  const name = path.split("/").pop().toLowerCase();
  return name.includes(".") ? name.split(".").pop() : name;
};

// -> [{ text, kind }] kind: comment | string | number | keyword | constant | function | type | punct | ""
export function tokenize(text, ext) {
  if (text.length > 400) return [{ text, kind: "" }];
  const re = new RegExp((HASH.has(ext) ? HASH_RE : RE).source, "g"), out = [];
  let m, at = 0;
  while ((m = re.exec(text)) && m[0] !== "") {
    if (m.index > at) out.push({ text: text.slice(at, m.index), kind: "" });
    at = m.index + m[0].length;
    const [s] = m;
    let kind = "";
    if (m[1] !== undefined) kind = "comment";
    else if (m[2] !== undefined) kind = "string";
    else if (m[3] !== undefined) kind = "number";
    else if (m[4] !== undefined) {
      if (CONSTANTS.has(s)) kind = "constant";
      else if (!NO_KEYWORDS.has(ext) && KEYWORDS.has(s)) kind = "keyword";
      else if (text[at] === "(" || (text[at] === "<" && /^[a-z]/.test(s) && false)) kind = "function";
      else if (/^[A-Z][A-Za-z0-9]*$/.test(s) && s.length > 1) kind = "type";
    } else if (m[5] !== undefined) kind = "punct";
    out.push({ text: s, kind });
  }
  if (at < text.length) out.push({ text: text.slice(at), kind: "" });
  return out;
}
