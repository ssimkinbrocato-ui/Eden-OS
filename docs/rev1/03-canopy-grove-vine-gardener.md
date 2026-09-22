# Canopy, Grove, Vine, and the Gardener (Rev 1)

## 1. Canopy — the GUI

Every window is a **Doc**: a retained tree of nodes (Text, Button, Image, Code, Link, Input, Tensor, Canvas, Layout). One tree gives three things at once:

1. **Rendering** — Canopy diffs the tree and repaints damaged rects (GOP framebuffer first, then GPU via Display/Accelerator drivers; text via an SDF glyph atlas).
2. **Accessibility** — the tree *is* the accessibility API; no second one.
3. **AI addressability** — the Gardener calls `doc_snapshot` and sees exactly what the user sees, and can `doc_update` any node.

The **Intent Bar** (Super+Space) is a Canopy widget that calls `intent_submit(text, ctx = focused_window)`. Apps declare UI with `doc { $TITLE ... $BT "Save" -> { ... } }` (see Apps/Notes/Main.halo). Widget tags descend from DolDoc: `$H1 $TX $BT $LK $CODE $INPUT $ROW $IMG $TENSOR`.

## 2. Grove — the filesystem

- **On disk:** superblock -> copy-on-write B-tree of objects -> content-addressed extents (BLAKE3) -> metadata journal -> **vector index segment** (HNSW, maintained by the Gardener via `grove_watch`).
- **Object classes:** Blob, Doc (live document), Halo (source the JIT can run), Model (GGUF/safetensors, mmap-able straight into TensorArena), Dir.
- Every write is a snapshot; `Grove.history(path)` is free and `Grove.revert` is the Gardener's undo.
- Paths: `/Sys` (kernel + stdlib source, editable), `/Home`, `/Apps`, `/Models`, `/Sys/Telemetry`, `/Sys/Gardener/Memory`.
- Semantic queries: `grove_query("photos taken last week", k = 200, scope = "/Home/Photos")`.

## 3. Vine — the tensor runtime

`Tensor[T, dims...]` is a language type; kernels are Halo `fn`s tagged `@kernel`. Forge lowers them through the tensor and simd dialects; the same source targets CPU (AVX-512/AMX/SVE via `SIMD`), GPU (Accelerator driver backend: SPIR-V/PTX) and NPUs. `@autotune` searches tile sizes per machine and caches the winner in Grove.

Formats: F32/F16/BF16, Q8_0, Q4_K, Q4_0; loaders for GGUF and safetensors. Weights are mmapped from Grove into TensorArena (huge pages -> zero-copy DMA). Example: Sys/Vine/Kernels/MatmulQ4.halo. Planned: `Vine.train` (autograd + LoRA) so the Gardener can fine-tune its own model on its episodes.

## 4. The Gardener (Rev 1 design; superseded by docs/rev2)

Rev 1 ran the Gardener as a privileged Cell with an approval gate:

~~~
intent text + focused Doc snapshot
  -> tool schema = symbols_export(public & has_doc)          (the kernel symbol table)
  -> local LLM (3-8B Q4_K) emits a Halo def program + required caps
  -> capability prompt in Canopy: "This will read /Home/Photos and use Net.Smtp. Allow?"
  -> jit_compile -> cell_spawn(module, approved caps) -> run -> result Doc
  -> audit: source + caps + Grove snapshot id -> /Sys/Telemetry/Intents/<id>
~~~

Tool schemas are generated from signatures and `///` doc comments, never hand-written:

~~~
/// Compress images under `dir` (recursively) to JPEG at `quality`, writing to `out_dir`. Returns count.
fn Images.compress_dir(dir: StrRef, out_dir: StrRef, quality: I64 = 82) raises -> I64;

{"name":"Images.compress_dir","params":{"dir":"StrRef","out_dir":"StrRef","quality":{"type":"I64","default":82}},
 "returns":"I64","raises":true,"caps":["GroveRead","GroveWrite"]}
~~~

Rev 2 moved the Gardener into the Sanctum as a sovereign kernel subsystem with recursive self-correction and self-authored updates. The Cell path remains available as the Gardener's optional probation space. See docs/rev2/.
