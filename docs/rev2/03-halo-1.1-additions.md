3. Language Additions for Agency (Halo 1.1)
#act { ... }              // Agent action block: streamed out of the LLM, JIT-compiled and executed
                          // the moment the closing brace arrives; result spliced back into context.

@hot                      // Function routed through the indirection table → live-replaceable (default
                          // for all non-inlined Sanctum fns). @pinned opts out (fault entry, patcher).
@core                     // Fault here = crash record + reboot. Fault elsewhere = task unwind + Incident.
@invariant(expr)          // Checked after every hot-patch of this fn and in shadow boots.
@test fn name() raises;   // Discovered by the Verify stage; Gardener writes these for its own code.
@migrate(from: TypeV1)    // Layout-migration fn the agent supplies when changing a live struct.
@skill(doc: Str)          // Marks an agent-authored fn as a reusable tool; auto-exported to schema.

throw Incident(...)       // First-class fault type: code, symbol, backtrace, arena snapshot, context.
