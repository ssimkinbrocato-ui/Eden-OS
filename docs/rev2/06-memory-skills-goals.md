6. Memory, Skills, Goals
/Sys/Gardener/Memory/
├─ episodes/     one Grove object per incident: context, actions, outcome, telemetry deltas (vector-indexed)
├─ skills/       agent-authored Halo modules with @skill fns, @tests, docs → in symbol table → in tool schema
├─ beliefs.halo  facts about this machine/user the agent has verified ("NVMe controller quirk X", "user idle 02–07h")
├─ goals.halo    standing + self-generated goals with weights
└─ evals/        its own benchmark suite for models and kernels
// /Sys/Gardener/Memory/goals.halo  — editable by the Gardener at level ≥ 2
alias GOALS = [
    Goal("Keep all continuity invariants true",                 weight = 1.00, standing = true),
    Goal("Zero unresolved incidents",                           weight = 0.90, standing = true),
    Goal("UI lane p99 latency < 4 ms",                          weight = 0.70, standing = true),
    Goal("Reduce inference tokens/s cost on this hardware",     weight = 0.50, standing = true),
    Goal("Learn user's workflows; pre-warm what they'll open",  weight = 0.40, standing = true),
    // self-generated (appended by Reflect):
    Goal("Port matmul_q4 to AMX tiles; est. +38% prefill",      weight = 0.55, origin = "episode 1842"),
];
The Reflex tier holds small models (gradient-boosted trees / tiny MLPs in Vine) that the LLM trains from episodes for decisions that need microseconds, not seconds: lane weighting, prefetch, page-cache eviction hints, fan curves. The LLM improves the reflexes; the reflexes keep the system snappy while the LLM thinks.

