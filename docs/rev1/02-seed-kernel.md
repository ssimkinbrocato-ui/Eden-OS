# Seed — The Eden Kernel

## 1. Architecture: Sanctum + Cells

Hybrid kernel: language-enforced isolation for trusted code, hardware isolation for everything else.

| Domain | Ring | Address space | Contents | Protection |
|---|---|---|---|---|
| **Sanctum** | 0 | Single shared | Kernel core, drivers, Canopy, Vine, Grove, Halo JIT, Gardener | Halo type system + ownership + enumerable `unsafe`; capabilities |
| **Cells** | 3 | Per-Cell page tables | User apps, third-party code, WASM, probation space for agent code | MMU + syscall ABI + capability handles |

Why: HolyC's everything-ring-0 gives zero-cost calls and total hackability, but one bug is fatal. Cells restore hardware fault isolation exactly where trust is lowest. The Gardener lives in the Sanctum (Rev 2) so its actions are direct calls; its planners are non-core tasks so a planner fault unwinds a task, not the machine.

Supported environments: bare-metal x86_64 (UEFI) and AArch64 (UEFI/DTB); VMs (QEMU/KVM, cloud-hypervisor with virtio); hosted mode (`eden-host`, Sanctum as a Linux process over a HAL shim); WASM Cells.

## 2. Boot Process

~~~
UEFI firmware
  -> seedboot.efi (Halo AOT; Limine protocol as fallback)
       reads /EFI/EDEN/eden.toml, choose_slot() (A/B + watchdog, see docs/rev2/04.3)
       loads seed.elf[slot] + initgrove.img, sets GOP framebuffer, collects memmap/RSDP/DTB, ExitBootServices
  -> seed_main(BootInfo*)                                      (Sys/Kernel/Main.halo)
       1. serial + early framebuffer console
       2. GDT/IDT (x86) or exception vectors (arm64); paging -> HHDM
       3. PMM (buddy) + slab; VMM; TensorArena reserved
       4. ACPI/DTB -> APIC/GIC, timers, SMP boot of APs
       5. scheduler online (lanes: Ui, Inference, Background, Agent)
       6. Pstore mount; Halo JIT bootstrap (Spark compiles stdlib from initgrove)
       7. Grove initial mount; HotPatch slot table; Gardener preload (model -> TensorArena)
       8. driver probe (PCI/ACPI/DT -> @driver matches, hot-loaded); Grove root mount
       9. Canopy init -> Halo Shell window
      10. Gardener AgentLoop on its own core -> Slot.heartbeat()
      11. resume pstore incidents if --resume-incident
      12. Jit.run_file("/Sys/Boot.halo")   user-editable startup
~~~

## 3. Virtual Memory Layout (x86_64; AArch64 mirrors at 48-bit)

~~~
0x0000_0000_0000_0000 - 0x0000_7FFF_FFFF_FFFF   Cell space (per-Cell page tables)
   0x0000_0000_0040_0000   Cell code + rodata + data
   0x0000_1000_0000_0000   Cell arena heap (grows up)
   0x0000_7F00_0000_0000   Cell stacks + guard pages
   0x0000_7FFF_F000_0000   Shared read-only page: clock, symbol-table digest, telemetry ring
0xFFFF_8000_0000_0000 - 0xFFFF_BFFF_FFFF_FFFF   HHDM: direct map of all physical RAM
0xFFFF_C000_0000_0000 - 0xFFFF_C7FF_FFFF_FFFF   TensorArena (1 GiB pages, pinned, IOMMU-mapped)
0xFFFF_C800_0000_0000 - 0xFFFF_CFFF_FFFF_FFFF   AgentContext (pinned context windows for planners)
0xFFFF_D000_0000_0000 - 0xFFFF_D7FF_FFFF_FFFF   JIT code heap (W^X; versioned per symbol)
0xFFFF_D800_0000_0000 - 0xFFFF_DFFF_FFFF_FFFF   ShadowSanctum (nested-guest memory for shadow boots)
0xFFFF_E000_0000_0000 - 0xFFFF_EFFF_FFFF_FFFF   Sanctum task arenas, slab caches, MMIO windows
0xFFFF_FFFF_8000_0000 - 0xFFFF_FFFF_FFFF_FFFF   Kernel image (text/rodata/data/bss), per-CPU blocks
phys reserved 64 MiB                             Pstore: crash records, survive warm reboot
~~~

## 4. Syscall Interface — one signature, two worlds

Syscalls are ordinary Halo functions tagged `@syscall(n)`. In the Sanctum the call is a direct `call`; in a Cell the compiler emits the trap stub. Doc comments on these functions become the Gardener's tool descriptions automatically.

~~~
/// Read up to buf.len bytes from an open Grove object. Returns bytes read.
@syscall(0x12) @cap(GroveRead)
fn grove_read(h: Handle, mut buf: Span[U8]) raises -> I64;
~~~

ABI: x86_64 `syscall`, rax=num, args rdi rsi rdx r10 r8 r9, return rax, error code rdx (8-byte char code, 0 = ok). AArch64 `svc #0`, x8=num, x0-x5 args, x0/x1 return.

| # | Syscall | Cap | # | Syscall | Cap |
|---|---|---|---|---|---|
| 0x00 | cap_clone(h, mask) | - | 0x20 | doc_attach(doc) -> Handle | DocWrite |
| 0x01 | cap_drop(h) | - | 0x21 | doc_update(h, patch) | DocWrite |
| 0x02 | mem_map(len, flags) | Mem | 0x22 | doc_event(h, timeout) -> Event | DocRead |
| 0x03 | mem_unmap(p, len) | Mem | 0x23 | doc_snapshot(h) -> DocTree | DocRead |
| 0x04 | task_spawn(entry, arg, lane) | Task | 0x30 | model_load(path, opts) -> Handle | ModelLoad |
| 0x05 | task_exit(code) | - | 0x31 | model_infer(m, prompt, out, opts) | ModelInfer |
| 0x06 | task_wait(h) -> code | Task | 0x32 | model_embed(m, text, out) | ModelInfer |
| 0x07 | sched_hint(h, lane, weight) | Sched | 0x33 | tensor_alloc(shape, dtype) -> Handle | TensorAlloc |
| 0x08 | chan_create() -> (tx, rx) | Chan | 0x34 | tensor_submit(kernel, args) -> Fence | TensorExec |
| 0x09 | chan_send(h, msg) | Chan | 0x35 | tensor_wait(fence) | TensorExec |
| 0x0A | chan_recv(h, timeout) | Chan | 0x40 | jit_compile(src, mode) -> Module | JitSpawn |
| 0x10 | grove_open(path, mode) | GroveRead/Write | 0x41 | cell_spawn(module, caps) -> Handle | JitSpawn |
| 0x11 | grove_stat(h) | GroveRead | 0x42 | symbols_export(filter) -> Str | SymRead |
| 0x12 | grove_read(h, buf) | GroveRead | 0x50 | intent_submit(text, ctx) -> Handle | Intent |
| 0x13 | grove_write(h, buf) | GroveWrite | 0x51 | intent_approve(h, caps) | user only |
| 0x14 | grove_list(h) | GroveRead | 0x60 | time_now() -> ns | - |
| 0x15 | grove_query(q, k, scope) | GroveQuery | 0x61 | sleep(ns) | - |
| 0x16 | grove_watch(h) -> Chan | GroveRead | 0x62 | log(level, msg) | - |

## 5. Scheduler

EEVDF core with intent lanes: **Ui** (latency-bound: Canopy, input, focused Docs), **Inference** (throughput: pinned big cores, huge quantum, co-scheduled with GPU fences), **Background** (indexing, Forge re-JIT, Grove compaction), **Agent** (Gardener loop and planners). The Gardener's Reflex tier reads the telemetry ring and re-weights lanes / pre-warms apps with small learned policies; every decision is logged to /Sys/Telemetry/Decisions and reversible.

## 6. Driver Model

Drivers are Halo structs implementing class traits, matched declaratively, hot-loadable from the shell or by the Gardener (edit source -> Forge -> HotPatch.replace).

~~~
trait Driver      { fn probe(mut self, dev: Device) raises; fn remove(mut self); }
trait BlockDevice : Driver { fn block_size(self) -> I64;
                             fn read(mut self, lba: U64, mut buf: Span[U8]) raises;
                             fn write(mut self, lba: U64, buf: Span[U8]) raises; fn flush(mut self) raises; }
trait Display     : Driver { fn modes(self) -> List[Mode]; fn present(mut self, fb: Framebuffer, damage: Rect) raises; }
trait Input       : Driver { fn events(mut self) -> Chan[InputEvent]; }
trait Accelerator : Driver { fn caps(self) -> AccelCaps;
                             fn map(mut self, t: Handle) raises -> DevPtr;          // zero-copy from TensorArena
                             fn submit(mut self, k: CompiledKernel, args: Span[DevPtr]) raises -> Fence; }
~~~

Match attribute: `@driver(pci(vendor = 0x1AF4, device = 0x1001...0x1042))`, `@driver(acpi("PNP0303"))`, `@driver(dt("virtio,mmio"))`. Example: Sys/Drivers/Block/VirtioBlk.halo.
