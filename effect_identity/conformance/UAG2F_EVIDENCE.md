# UAG-2F EffectID Cross-Runtime Conformance — Evidence

- Branch / PR: `uag-2f-effectid-conformance` / PR #8
- Final head: `0f9ff6ec` (evidence commit follows on the same branch)
- Date: 2026-10-03

## Frozen corpus (unchanged)

- `effect_identity/fixtures/effect_id_v1.json`
- sha256 `fc353176e5dc3679e2ff79cf9deee59d1394f161884dc1eb9ff15310c77323f6`
- 117 vectors, 15-category taxonomy verified on every run
- `expected_base_effect_id` `a565edecfc000c7f6be7c3714183b21241f067e80305072fce77b6485a8e2a50`

## Local 4-runtime matrix (Windows workstation)

```
python effect_identity/conformance/run.py --legs python,typescript,rust,elixir
```

| leg | runtime | lines | ERROR vectors | output sha256 (first16) |
|-----|---------|-------|---------------|--------------------------|
| python | 3.14.0 |117|22| `3f158720a430558a` |
| typescript | node 24.11.1 |117|22| `3f158720a430558a` |
| rust | 1.94 (linux container `rust:1.94`)* |117|22| `3f158720a430558a` |
| elixir | 1.18.4 / OTP 28.5 (mise) |117|22| `3f158720a430558a` |

Result: `UAG-2F CROSS-RUNTIME PASS: 4 leg(s), 117 vectors, byte parity`.

\* The local MSVC toolchain cannot link (VS Build Tools installed without the
Windows SDK; no `kernel32.lib`), so the Rust leg runs in a container — the
same OS family used by CI.

Fresh-process determinism (recovery/reconstruction): the Elixir driver was
run in two separate BEAM VMs and the Python runner twice; outputs were
byte-identical in both cases.

## CI (both UAG-2F workflows, head `0f9ff6ec`)

| run | trigger | jobs | conclusion |
|-----|---------|------|------------|
| 37153344951 | push | cross-runtime, elixir | success |
| 37153344950 | push | independent-renderers, elixir | success |
| 37153348758 | pull_request | cross-runtime, elixir | success |
| 37153348822 | pull_request | independent-renderers, elixir | success |

- cross-runtime log: `UAG-2F CROSS-RUNTIME PASS: 4 leg(s), 117 vectors, byte parity`
- evidence JSON uploaded as artifact `uag2f-cross-runtime-matrix`
- independent-renderers job diffs Python/TypeScript/Rust outputs byte-for-byte
  and asserts the fixture taxonomy

## Proof tests — `mix test`:18 tests, 0 failures

- recovery/reconstruction: JSON round-trip, persisted-file round-trip,
  canonical-byte fixed point, distinct recovery targets never collide
- retry/idempotency:32 concurrent computations identical; `attempt`,
  `execution_id`, `request_id` excluded from identity

## Mismatch resolutions (no fixture changes)

1. `expect=different` vectors whose side fails to render
   (E-033/034/035/037/038/039 numeric tokens, E-068 operation padding):
   runner semantics clarified — `different` means "the pair is never equal";
   a rejected side can never equal the other. The spec requires exactly these
   inputs to be rejected, so fixtures and spec stay as written.
2. E-091 (`{"$unsupported":"function"}`, `expect=error`): all four
   implementations now reject reserved `$`-prefixed keys ("unsupported
   runtime-specific values hard-fail").
3. TypeScript `$collection` canonicalization emitted no surrounding braces —
   byte-parity bug, fixed.
4. Rust printed JSON-quoted vector ids in rendered lines — fixed.
5. Elixir rejected nested atom keys (`:invalid_object_key`, its own suite was
   failing7/12) — atom keys now normalize to strings; `$number`/`$collection`
   wrapper keysets tightened to exact shapes.
6. `test_helper.exs` required two never-committed support files, breaking
   `mix test` for the whole project — added under
   `tiannara_runtime/test/support/`.
7. CI infra: `setup-beam` strict OTP28, `cargo metadata` at repo root,
   elixir job working directory, duplicate workflow `name:` entries — fixed.

## Wave-3 invariants (main worktree, branch `local/pr4`)

- HEAD `d6f678bd016278e35efd67f698919d97e00e6119` unchanged
- `stash@{0}: On local/pr3: pr3-emergent-fixes` intact
- porcelain `799` — unchanged during this stage
- 0 commits, 0 pushes on `local/pr4`

## Out of scope (pre-existing on `main`)

Legacy workflows `Tests`, `CI/CD Pipeline`, `Cross-Platform Verification`
fail on `main` as well (e.g. main run 35278443583); they are not part of the
UAG-2F gate.
