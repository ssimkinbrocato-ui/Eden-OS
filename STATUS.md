# Eden OS — Project Status

This file is the project's memory. If unsure what to do next: read this, then paste the repo link
to the assistant and say "what's next?".

How to work on the project: GitHub -> green Code button -> Codespaces -> open the codespace.
To run a script the assistant gives you: open setup4.sh, Ctrl+A, Delete, paste, Ctrl+S, then in the
terminal run: bash setup4.sh

## Done — initial setup complete
- [x] Design docs: Rev 1 (docs/rev1) and Rev 2 (docs/rev2), index at docs/README.md
- [x] Agent-loop flowchart (docs/diagrams/agent-loop.mmd)
- [x] Halo sources: Sys/Kernel (Main, HotPatch, Fault), Sys/Kernel/Gardener (Agent, Evolution,
      Escalation, Sovereignty), Sys/Drivers/Block/VirtioBlk, Sys/Vine/Kernels/MatmulQ4,
      Apps/Notes, boot/seedboot/Slot, Sys/Boot
- [x] eden.toml, run/qemu-x86_64.sh, justfile
- [x] halo0: Rust stage-0 lexer + smoke checker; GitHub Actions CI builds it and lex-checks all .halo files
- [x] README, .gitignore

## Next (ask the assistant for "phase 2")
- [ ] halo0: parser + AST for the grammar in docs/rev1/01-halo-language.md
- [ ] halo0: semantic analysis (types, ownership), then Spark baseline codegen
- [ ] Sys/Kernel/Gardener: ActParser, Verify, Sensors, Reflex, Memory, Skills (referenced, not yet written)
- [ ] Shadow.boot (nested-guest shadow boot) and Vine.train (autograd + LoRA)
- [ ] seedboot UEFI stub + first bootable Seed image; make `just image` and `just run` real
- [ ] Canopy compositor core; Grove on-disk format implementation

## Notes
- docs/rev2/09-config.md has the TOML and QEMU script glued together (copy-paste artifact); the clean
  versions are eden.toml and run/qemu-x86_64.sh.
- Halo error codes are 8-byte char codes: keep them <= 8 characters.
- If the CI badge on GitHub is red, copy the error text to the assistant.
