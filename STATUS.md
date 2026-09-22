# Eden OS — Project Status

This file is the project's memory. If you are unsure what to do next, read this, then paste the
repo link to the assistant and say "what's next?".

## Done (part 1)
- [x] Revision 2 design docs (docs/rev2) — uploaded and restructured
- [x] Agent-loop flowchart (docs/diagrams/agent-loop.mmd)
- [x] Clean eden.toml and run/qemu-x86_64.sh
- [x] halo0: Rust stage-0 lexer + smoke checker
- [x] GitHub Actions CI (.github/workflows/eden-ci.yml)
- [x] README, .gitignore, justfile

## Next — ask the assistant for "part 3"  (part 2 done: kernel, Gardener core, boot slots)
- [ ] Halo source files at their real paths (Sys/Kernel, Sys/Kernel/Gardener, Sys/Drivers, boot/, Apps/)

## Then — "part 3"
- [ ] Revision 1 design docs (docs/rev1): Halo language spec, Seed kernel, syscall table,
      driver model, Canopy, Grove, Vine, Gardener v1

## Later
- [ ] halo0: parser + AST, semantic analysis, Spark baseline JIT
- [ ] seedboot UEFI stub + first bootable Seed image
- [ ] ActParser, Verify, Shadow.boot, Vine.train (referenced by Rev 2, not yet written)

## Notes
- docs/rev2/09-config.md contains the TOML and the QEMU script glued together (copy-paste
  artifact). The clean versions are eden.toml and run/qemu-x86_64.sh.
- Halo error codes are 8-byte char codes: keep them <= 8 characters ('Exhaust', not 'Exhausted').
- To work on the project: GitHub -> green Code button -> Codespaces -> open the codespace.
