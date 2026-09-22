8. Updated Boot Sequence
seedboot: choose_slot() → load seed.elf[slot] + initgrove → ExitBootServices
seed_main:
  1–5   as Rev 1 (tables, PMM/VMM, ACPI, SMP, Sched)
  6     Pstore.mount(); Grove.mount_root()
  7     Jit.bootstrap()                      — compiler
  8     HotPatch.init()                      — slot table for all @hot symbols
  9     Gardener.preload()                   — mmap active model into TensorArena, load Memory index
 10     Drivers.probe_all()                  — faults here are already Incidents, not panics
 11     Canopy.init(); Shell window
 12     Gardener.AgentLoop.run() on its own core   ← Slot.heartbeat() fires here
 13     if (--resume-incident) pstore incidents pushed at .Critical priority
 14     Jit.run_file("/Sys/Boot.halo")
