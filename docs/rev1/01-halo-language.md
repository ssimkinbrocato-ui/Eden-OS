# Halo — The Language

> HolyC's insight: the shell *is* the compiler and the kernel *is* the library.
> Mojo's insight: compile-time parameters, SIMD/tensor-native types and ownership give Python ergonomics at C++ speed.
> Halo: C-style braces, HolyC's instant JIT, Mojo's type system. File extension `.halo`.

## 1. Heritage

| From HolyC | From Mojo | Dropped |
|---|---|---|
| Explicit-width primitives `U0 U8 ... I64 F64` | `fn` (strict) vs `def` (flexible) | HolyC: ring-0 only, no isolation |
| JIT everything; shell accepts raw statements | Compile-time params `[T: DType, N: I64]` | HolyC: 640x480, no Unicode/network |
| Bare call without parens: `Reboot;` | `struct` with methods, `trait`s | Mojo: Python indentation syntax |
| Omitted args: `Foo(,,3)` | Ownership: `read`/`mut`/`owned`, `^` transfer | Mojo: Python runtime dependency |
| `"fmt %d\n", x;` print statement | `SIMD[T,W]`, `Tensor[...]` first-class | C: header files, forward declarations |
| `#exe {}` compile-time codegen | `#for` / `#if` compile-time unrolling | C: implicit narrowing |
| `case 1...5:` ranges | Multi-level IR (HIR -> tensor/simd -> native) | |
| `throw 'ErrCode';` 8-byte char codes | `alias`, `@inline`, `@register_passable` | |
| Live docs with embedded code (DolDoc) | Value semantics, no GC | |

## 2. Grammar (EBNF, condensed)

~~~
module      := item* ;
item        := directive | attr* (fn_decl | struct_decl | trait_decl | alias_decl | doc_decl) | stmt ;
directive   := '#include' STRING | '#define' IDENT token* NEWLINE | '#exe' block
             | '#if' expr block ('#else' block)? | '#for' IDENT 'in' expr block | '#act' block ;
attr        := '@' IDENT ('(' arg_list ')')? ;
fn_decl     := ('fn' | 'def') IDENT ct_params? '(' params? ')' ('->' type)? 'raises'? (block | ';') ;
ct_params   := '[' ct_param (',' ct_param)* ']' ;
ct_param    := IDENT ':' type ('=' expr)? ;
param       := ('read' | 'mut' | 'owned')? IDENT (':' type)? ('=' expr)? ;
struct_decl := 'struct' IDENT ct_params? (':' type_list)? '{' (field | fn_decl)* '}' ;
field       := 'var' IDENT ':' type ('=' expr)? ';' ;
trait_decl  := 'trait' IDENT ct_params? (':' type_list)? '{' fn_decl* '}' ;
alias_decl  := 'alias' IDENT (':' type)? '=' expr ';' ;
doc_decl    := 'doc' IDENT '{' doc_node* '}' ;
doc_node    := '$' TAG (STRING | '(' expr ')' | '->' block | IDENT)* ;
type        := IDENT ('[' type_arg (',' type_arg)* ']')? | 'fn' '(' type_list? ')' '->' type ;
stmt        := ('var' | 'let') IDENT (':' type)? ('=' expr)? ';'
             | STRING (',' expr)* ';'            (* print statement *)
             | IDENT ';'                         (* bare call *)
             | expr ';'
             | 'if' '(' expr ')' block ('else' (block | stmt))?
             | 'while' '(' expr ')' block | 'for' IDENT 'in' expr block
             | 'switch' '(' expr ')' '{' case* '}'
             | 'try' block 'catch' ('(' IDENT ')')? block
             | 'return' expr? ';' | 'throw' expr ';' | 'break' ';' | 'continue' ';'
             | 'goto' IDENT ';' | IDENT ':' | 'unsafe' block | block ;
case        := 'case' const ('...' const)? ':' stmt* | 'default' ':' stmt* ;
call        := expr ct_args? '(' (expr?) (',' expr?)* ')' ;   (* empty slots = omitted args *)
expr        := C precedence + postfix '^' (transfer) + 'as' type (cast) + 'a..b' (range) ;
~~~

## 3. Type System

Static, nominal, parametric; gradual only inside `def`.

~~~
Primitives   U0 Bool U8 U16 U32 U64 I8 I16 I32 I64 F16 BF16 F32 F64
Compound     struct, trait (existential via dyn Trait), tuples (A, B)
Parametric   SIMD[T: DType, W: I64]   Tensor[T: DType, dims: I64...]   QTensor[Q: QuantFmt, ...]
Memory       Ptr[T] (raw, unsafe deref)   Span[T] (bounded view)   Ref[T] (checked borrow)
Std          Str, StrRef, List[T], Dict[K,V], Optional[T], Result[T,E], Handle, Cap
GUI          Doc, Node, Event
Dynamic      Object  (boxed; only inside def bodies and the shell)
~~~

- Integer literals are `I64`, float literals `F64`. Implicit widening only; narrowing requires `x as U8`.
- `fn`: every variable typed, ownership checked, no `Object`. Optimizing tier.
- `def`: untyped params default to `Object`, implicit `var`, may raise anything. Baseline tier.
- Traits are checked at instantiation; generic `fn`s monomorphize.
- `raises` is part of the signature. Errors are 8-byte char codes (max 8 chars) or any `struct : Error`.

## 4. Memory Model

- Value semantics + ownership, no GC. One owner per value; destroyed at last use (ASAP).
- Argument conventions: `read` (default borrow), `mut` (mutable borrow), `owned` (moved in; caller writes `x^`).
- `Ptr[T]` deref, pointer arithmetic and `MAlloc/Free` only inside `unsafe { }`. The kernel's unsafe surface is enumerable and audited.
- Task arenas: every task owns an arena heap, released wholesale when the task dies.
- TensorArena: 1 GiB-page, pinned, IOMMU-mapped region for `Tensor` storage (zero-copy to GPU/NPU).
- Sanctum: plain pointers in one address space. Cells: same source, own address space, kernel objects via `Handle`.

## 5. Compilation Pipeline

~~~
source -> Lexer -> Parser -> AST -> Sema (types, ownership, traits, comptime #exe/#for/#if) -> HIR (typed SSA)
  Tier 0 "Spark": single-pass baseline JIT, ~1M lines/s. Shell, def, Gardener action blocks.
  Tier 1 "Forge": HIR -> dialects (halo / simd / tensor / llvm) -> optimized native. Kernel AOT,
                  drivers, Vine kernels, background re-JIT of hot Spark code.
Targets: x86_64, AArch64, (RISC-V planned), WASM (Cells).
~~~

## 6. Examples

~~~
"Hello, Eden! %d cores, %s\n", Cpu.count, Arch.name;   // print statement
Dir;                                                    // bare call
Beep(,300);                                             // first arg omitted -> default

trait Shape { fn area(self) -> F64; }
struct Circle : Shape {
    var r: F64;
    fn __init__(mut self, r: F64) { self.r = r; }
    fn area(self) -> F64 { return Math.pi * self.r * self.r; }
}
fn total_area[S: Shape](shapes: List[S]) -> F64 {
    var acc: F64 = 0;
    for s in shapes { acc += s.area(); }
    return acc;
}
fn consume(owned buf: List[U8]) -> I64 { return buf.len; }   // buf destroyed here
var b = List[U8](4096);
let n = consume(b^);                                          // ^ transfers ownership

fn dot[T: DType, W: I64 = simd_width[T]()](a: Span[Scalar[T]], b: Span[Scalar[T]]) -> Scalar[T] {
    var acc = SIMD[T, W](0);
    var i: I64 = 0;
    while (i + W <= a.len) { acc += a.load[W](i) * b.load[W](i); i += W; }
    var tail: Scalar[T] = 0;
    while (i < a.len) { tail += a[i] * b[i]; i++; }
    return acc.reduce_add() + tail;
}

#exe { for i in 0..5 { emit("alias PAGE_%d: I64 = %d;\n", i, 4096 << (i * 9)); } }
fn hsum[N: I64](v: SIMD[F32, N]) -> F32 { var s: F32 = 0; #for i in 0..N { s += v[i]; } return s; }

fn classify(ch: U8) raises -> Str {
    switch (ch) {
        case 'a'...'z': return "lower";
        case 0x00...0x1F: throw 'CtrlChr';
        default: return "other";
    }
}

doc SysPanel {                              // live document = GUI window
    $H1 "Eden"
    $BT "Reboot" -> { Sys.reboot; }
    $CODE { Dir("/Home"); }                 // clickable, JIT-runs inline
}
~~~

## 7. Halo 1.1 additions (agency)
`#act { }` streamed action blocks, `@hot` / `@pinned` / `@core`, `@invariant(expr)`, `@test`, `@migrate(from: T)`, `@skill(doc)`, first-class `Incident`. See docs/rev2/03-halo-1.1-additions.md.
