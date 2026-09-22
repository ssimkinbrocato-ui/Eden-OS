#!/usr/bin/env bash
# Eden OS — finish part 1: CI file, Rust install if needed, build check, commit, push. Safe to re-run.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
mkdir -p .github/workflows

cat > .github/workflows/eden-ci.yml <<'__EOF__'
name: eden-ci
on: [push, pull_request]
jobs:
  halo0:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - name: Build stage-0 compiler
        run: cargo build --release --manifest-path halo0/Cargo.toml
      - name: Lex-check all Halo sources
        run: find . -name "*.halo" -not -path "./halo0/*" -print0 | xargs -0 -r -n1 ./halo0/target/release/halo0
__EOF__

# --- make sure Rust is available ---
export PATH="$HOME/.cargo/bin:$PATH"
if ! command -v cargo >/dev/null 2>&1; then
  echo "Rust not found — installing (1-2 minutes)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal >/dev/null 2>&1 || true
  export PATH="$HOME/.cargo/bin:$PATH"
fi

if command -v cargo >/dev/null 2>&1; then
  echo "Building halo0..."
  cargo build --release --manifest-path halo0/Cargo.toml
else
  echo "(Could not install Rust here — skipping local build; GitHub CI will build it.)"
fi

# --- commit + push ---
git config user.name  >/dev/null 2>&1 || git config user.name  "Eden Setup"
git config user.email >/dev/null 2>&1 || git config user.email "eden-setup@users.noreply.github.com"
git add -A
git commit -m "Part 1: restructure docs, add config, halo0 lexer, CI, README, STATUS" || echo "(nothing new to commit)"
git push

echo
echo "✅ PART 1 DONE — everything is on GitHub. Next: tell the assistant 'part 2'."