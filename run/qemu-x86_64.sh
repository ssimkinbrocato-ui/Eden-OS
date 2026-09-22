#!/usr/bin/env bash
# Launch Eden in QEMU (x86_64, UEFI). Requires: qemu-system-x86, OVMF, build/eden.img
set -euo pipefail
OVMF_CODE=${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE.fd}
OVMF_VARS_SRC=${OVMF_VARS_SRC:-/usr/share/OVMF/OVMF_VARS.fd}
mkdir -p build
[ -f build/OVMF_VARS.fd ] || cp "$OVMF_VARS_SRC" build/OVMF_VARS.fd   # boot-slot vars live here
exec qemu-system-x86_64 -M q35 -m 16G -smp 8 -cpu host,+vmx -enable-kvm \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file=build/OVMF_VARS.fd \
  -drive file=build/eden.img,if=none,id=d0,format=raw -device virtio-blk-pci,drive=d0 \
  -device virtio-gpu-pci -device virtio-keyboard-pci -device virtio-mouse-pci \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
  -serial mon:stdio
