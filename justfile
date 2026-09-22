# Eden OS build commands.  Install `just`: https://github.com/casey/just

default: bootstrap lex

# Build the stage-0 Halo compiler
bootstrap:
    cargo build --release --manifest-path halo0/Cargo.toml

# Lex-check every Halo source file
lex: bootstrap
    find . -name '*.halo' -not -path './halo0/*' -print0 | xargs -0 -r -n1 ./halo0/target/release/halo0

# Build bootable image (not yet implemented)
image:
    @echo "TODO: seedboot + Seed image (see STATUS.md)"

# Run in QEMU
run: image
    ./run/qemu-x86_64.sh
