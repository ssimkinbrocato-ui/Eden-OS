# Eden OS

**An AI-driven operating system, written in a new language called Halo, with a sovereign agent (the Gardener) built into the kernel.**

| Component | Name | Role |
|---|---|---|
| Language | **Halo** (`.halo`) | HolyC's instant-JIT philosophy + Mojo's type system, SIMD and ownership |
| Kernel | **Seed** | Hybrid: single-address-space ring-0 *Sanctum* + isolated ring-3 *Cells* |
| GUI | **Canopy** | Every window is a live document the AI can read and edit |
| Filesystem | **Grove** | Copy-on-write, content-addressed, built-in vector index |
| Tensor runtime | **Vine** | SIMD/GPU/NPU kernels written in Halo |
| AI agent | **Gardener** | Ring-0 agent: fixes faults recursively, writes its own skills, builds and ships its own updates |

## Layout

~~~
docs/rev1/      Foundation design: Halo language, Seed kernel, syscalls, drivers, GUI, FS, tensors
docs/rev2/      Revision 2: the Sovereign Gardener (agent loop, hot-patching, boot slots, evolution)
docs/diagrams/  Mermaid diagrams
halo0/          Stage-0 Halo compiler (Rust) — currently a lexer / smoke-checker
Sys/            Kernel, Gardener, drivers, tensor kernels (Halo source)
Apps/           Example apps (Halo)
boot/           seedboot bootloader
run/            QEMU launch scripts
eden.toml       Image + Gardener configuration
justfile        Build commands
STATUS.md       What is done and what to do next  <-- start here
~~~

## Quick start (in a GitHub Codespace)

~~~
cargo build --release --manifest-path halo0/Cargo.toml   # build stage-0 compiler
just lex                                                  # lex-check every .halo file
~~~

## Status
See [STATUS.md](STATUS.md).
