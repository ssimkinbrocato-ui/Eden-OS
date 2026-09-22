#!/usr/bin/env bash
# Eden OS — fix1: push work first, then rewrite lexer with explicit types and rebuild. Safe to re-run.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
export PATH="$HOME/.cargo/bin:$PATH"

cat > halo0/src/lexer.rs <<'__EOF__'
//! Halo lexer (HolyC + Mojo keyword union, `#` compile-time directives, 8-byte char codes).
use logos::{Lexer, Logos};

fn lex_int(l: &mut Lexer<Tok>) -> Option<i64> {
    let s = l.slice().replace('_', "");
    if let Some(hex) = s.strip_prefix("0x") { i64::from_str_radix(hex, 16).ok() } else { s.parse::<i64>().ok() }
}
fn lex_float(l: &mut Lexer<Tok>) -> Option<f64> { l.slice().parse::<f64>().ok() }
fn lex_str(l: &mut Lexer<Tok>) -> Option<String> { let s = l.slice(); unescape(&s[1..s.len() - 1]) }
fn lex_char_code(l: &mut Lexer<Tok>) -> Option<u64> { let s = l.slice(); char_code(&s[1..s.len() - 1]) }
fn lex_text(l: &mut Lexer<Tok>) -> String { l.slice().to_string() }

#[derive(Logos, Debug, Clone, PartialEq)]
#[logos(skip r"[ \t\r\n]+")]
#[logos(skip r"//[^\n]*")]
#[logos(skip r"/\*([^*]|\*[^/])*\*/")]
pub enum Tok {
    // ---- keywords ----
    #[token("fn")] Fn, #[token("def")] Def, #[token("struct")] Struct, #[token("trait")] Trait,
    #[token("alias")] Alias, #[token("var")] Var, #[token("let")] Let, #[token("doc")] Doc,
    #[token("read")] Read, #[token("mut")] Mut, #[token("owned")] Owned, #[token("unsafe")] Unsafe,
    #[token("raises")] Raises, #[token("if")] If, #[token("else")] Else, #[token("while")] While,
    #[token("for")] For, #[token("in")] In, #[token("switch")] Switch, #[token("case")] Case,
    #[token("default")] Default, #[token("try")] Try, #[token("catch")] Catch, #[token("throw")] Throw,
    #[token("return")] Return, #[token("break")] Break, #[token("continue")] Continue,
    #[token("goto")] Goto, #[token("as")] As, #[token("self")] SelfKw,
    #[token("true")] True, #[token("false")] False,

    // ---- compile-time directives ----
    #[token("#include")] Include, #[token("#define")] Define, #[token("#exe")] Exe,
    #[token("#if")] CtIf, #[token("#else")] CtElse, #[token("#for")] CtFor, #[token("#act")] Act,

    // ---- literals ----
    #[regex(r"0x[0-9A-Fa-f_]+", lex_int)]
    #[regex(r"[0-9][0-9_]*", lex_int)]
    Int(i64),
    #[regex(r"[0-9]+\.[0-9]+([eE][+-]?[0-9]+)?", lex_float)]
    Float(f64),
    #[regex(r#""([^"\\]|\\.)*""#, lex_str)]
    Str(String),
    /// HolyC-style char code, 1..8 bytes: 'NoDisk'
    #[regex(r"'([^'\\]|\\.){1,8}'", lex_char_code)]
    CharCode(u64),

    // ---- punctuation ----
    #[token("@")] At, #[token("$")] Dollar, #[token("^")] Caret, #[token("...")] Ellipsis,
    #[token("..")] DotDot, #[token("->")] Arrow, #[token("::")] ColonColon,
    #[token("(")] LParen, #[token(")")] RParen, #[token("[")] LBrack, #[token("]")] RBrack,
    #[token("{")] LBrace, #[token("}")] RBrace, #[token(",")] Comma, #[token(";")] Semi,
    #[token(":")] Colon, #[token(".")] Dot, #[token("|")] Pipe,
    #[regex(r"(<<=|>>=|==|!=|<=|>=|&&|\|\||\+\+|--|\+=|-=|\*=|/=|%=|&=|\|=|\^=|<<|>>|[-+*/%&~!<>=?])", lex_text)]
    Op(String),

    #[regex(r"[A-Za-z_][A-Za-z0-9_]*", lex_text)]
    Ident(String),
}

/// 'NoDisk' -> little-endian packed u64 (HolyC convention).
fn char_code(s: &str) -> Option<u64> {
    let b = s.as_bytes();
    if b.is_empty() || b.len() > 8 { return None; }
    let mut v = 0u64;
    for (i, &c) in b.iter().enumerate() { v |= (c as u64) << (8 * i); }
    Some(v)
}

fn unescape(s: &str) -> Option<String> {
    let mut out = String::with_capacity(s.len());
    let mut it = s.chars();
    while let Some(c) = it.next() {
        if c != '\\' { out.push(c); continue; }
        match it.next()? {
            'n' => out.push('\n'), 't' => out.push('\t'), 'r' => out.push('\r'),
            '0' => out.push('\0'), '\\' => out.push('\\'), '"' => out.push('"'), '\'' => out.push('\''),
            other => { out.push('\\'); out.push(other); }
        }
    }
    Some(out)
}
__EOF__

# --- save to GitHub first, regardless of build result ---
git config user.name  >/dev/null 2>&1 || git config user.name  "Eden Setup"
git config user.email >/dev/null 2>&1 || git config user.email "eden-setup@users.noreply.github.com"
git add -A
git commit -m "Part 1: restructure docs, config, halo0 lexer, CI, README, STATUS" || echo "(nothing new to commit)"
git push

# --- now build and show the full result ---
echo
echo "================ BUILD OUTPUT ================"
if cargo build --release --manifest-path halo0/Cargo.toml 2>&1; then
  echo "=============================================="
  echo "✅ PART 1 DONE — code is on GitHub and the compiler builds. Next: tell the assistant 'part 2'."
else
  echo "=============================================="
  echo "❌ Build failed, but your work IS saved on GitHub. Copy everything above (from BUILD OUTPUT) and paste it to the assistant."
fi