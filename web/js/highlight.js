/**
 * highlight.js (project-local, NOT the highlight.js library)
 *
 * A small, self-contained Luau tokenizer. hardluau deliberately avoids
 * pulling in a third-party highlighter: the suite exists to exercise edge
 * cases (long-bracket strings with levels, backtick interpolation, compound
 * assignment, attributes) that generic Lua grammars mishandle, so a purpose
 * -built ~150-line tokenizer is both lighter and more correct here than
 * vendoring and patching a general-purpose library.
 *
 * Exposes `window.highlightLuau(source) -> string` (HTML, already escaped).
 */
(function () {
  "use strict";

  const KEYWORDS = new Set([
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "if", "in", "local", "nil", "not", "or", "repeat",
    "return", "then", "true", "until", "while", "continue",
  ]);

  const LUAU_KEYWORDS = new Set(["type", "export"]);

  // Ordered token specs. First match at the current position wins.
  // `y` (sticky) anchors the match to `lastIndex` exactly.
  const SPECS = [
    { type: "comment", re: /--\[(=*)\[[\s\S]*?\]\1\]/y }, // long comment
    { type: "comment", re: /--[^\n]*/y },                  // line comment
    { type: "string", re: /\[(=*)\[[\s\S]*?\]\1\]/y },     // long string
    { type: "string-interp", re: /`(?:\\.|\{[^}\n]*\}|[^`\\\n])*`/y },
    { type: "string", re: /"(?:\\.|[^"\\\n])*"/y },
    { type: "string", re: /'(?:\\.|[^'\\\n])*'/y },
    { type: "attribute", re: /@[A-Za-z_]\w*/y },
    { type: "number", re: /0[xX][0-9a-fA-F_]+/y },
    { type: "number", re: /\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?/y },
    { type: "op", re: /::/y },
    { type: "op", re: /(?:\+|-|\*|\/\/|\/|%|\^|\.\.)=/y }, // compound assign
    { type: "op", re: /\.\.\.|\.\./y },
    { type: "op", re: /(?:==|~=|<=|>=|->|[+\-*/%^#<>=,.:;(){}\[\]])/y },
    { type: "ident", re: /[A-Za-z_]\w*/y },
    { type: "space", re: /[ \t]+/y },
    { type: "newline", re: /\n/y },
  ];

  function escapeHtml(s) {
    return s
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  // Highlight the interior of a backtick interpolated string: keep `{...}`
  // segments in their own span so the punctuation reads distinctly from the
  // string body, without fully re-tokenizing the embedded expression.
  function renderInterp(raw) {
    let out = "";
    let i = 0;
    while (i < raw.length) {
      const brace = raw.indexOf("{", i);
      if (brace === -1) {
        out += escapeHtml(raw.slice(i));
        break;
      }
      out += escapeHtml(raw.slice(i, brace));
      const close = raw.indexOf("}", brace);
      if (close === -1) {
        out += escapeHtml(raw.slice(brace));
        break;
      }
      out +=
        '<span class="tok-interp-brace">{</span>' +
        '<span class="tok-interp">' +
        escapeHtml(raw.slice(brace + 1, close)) +
        "</span>" +
        '<span class="tok-interp-brace">}</span>';
      i = close + 1;
    }
    return out;
  }

  function highlightLuau(source) {
    let i = 0;
    let out = "";
    const len = source.length;
    let prevIdent = null; // last significant identifier-ish token, for fn-call heuristic

    while (i < len) {
      let matched = false;

      for (const spec of SPECS) {
        spec.re.lastIndex = i;
        const m = spec.re.exec(source);
        if (!m || m.index !== i) continue;

        const text = m[0];
        i += text.length;
        matched = true;

        if (spec.type === "space" || spec.type === "newline") {
          out += text;
          break;
        }

        if (spec.type === "string-interp") {
          out += '<span class="tok-string">' + renderInterp(text) + "</span>";
          break;
        }

        if (spec.type === "ident") {
          if (KEYWORDS.has(text)) {
            out += '<span class="tok-keyword">' + text + "</span>";
          } else if (LUAU_KEYWORDS.has(text)) {
            out += '<span class="tok-luau-keyword">' + text + "</span>";
          } else if (text === "self") {
            out += '<span class="tok-self">' + text + "</span>";
          } else {
            // function-call / definition heuristic: identifier immediately
            // followed by "(" (ignoring spaces) reads as a call/def name.
            let j = i;
            while (j < len && (source[j] === " " || source[j] === "\t")) j++;
            if (source[j] === "(") {
              out += '<span class="tok-fn">' + escapeHtml(text) + "</span>";
            } else {
              out += '<span class="tok-ident">' + escapeHtml(text) + "</span>";
            }
          }
          prevIdent = text;
          break;
        }

        const cls =
          {
            comment: "tok-comment",
            string: "tok-string",
            attribute: "tok-attribute",
            number: "tok-number",
            op: "tok-op",
          }[spec.type] || "";

        out += '<span class="' + cls + '">' + escapeHtml(text) + "</span>";
        break;
      }

      if (!matched) {
        // Unknown character — emit escaped and move on so we never hang.
        out += escapeHtml(source[i]);
        i++;
      }
    }

    return out;
  }

  window.highlightLuau = highlightLuau;
})();
