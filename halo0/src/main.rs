//! halo0 — stage-0 Halo compiler. Currently: lexer + smoke checker.
//! Usage: halo0 <file.halo>      (set HALO_DUMP=1 to print tokens)
#![allow(dead_code)]
mod lexer;

use logos::Logos;

fn main() {
    let path = std::env::args().nth(1).unwrap_or_else(|| {
        eprintln!("usage: halo0 <file.halo>");
        std::process::exit(2);
    });
    let src = std::fs::read_to_string(&path).expect("cannot read file");
    let mut lex = lexer::Tok::lexer(&src);
    let dump = std::env::var("HALO_DUMP").is_ok();
    let mut count = 0usize;
    while let Some(item) = lex.next() {
        match item {
            Ok(tok) => {
                count += 1;
                if dump { println!("{:?}", tok); }
            }
            Err(_) => {
                let line = src[..lex.span().start].matches('\n').count() + 1;
                eprintln!("{}:{}: lex error near {:?}", path, line, lex.slice());
                std::process::exit(1);
            }
        }
    }
    println!("{}: {} tokens OK", path, count);
}
