# Tiannara Pros — Freeze v1.0

This document marks a stable baseline for Tiannara Pros after the 30-day build.

## What “Freeze v1.0” means
- Packet schema and keys are stable: `tiannara.pros.action.v1`
- Pros version is pinned (`tiannara_pros/version.py`)
- Core/Pros boundaries are respected:
  - `tiannara_core`: cognition/memory/decision layers
  - `tiannara_pros`: IO, actuator commands, safety, retry, analytics

## Interfaces that must remain compatible
- `ActionLayer.intent_to_action(intent, confidence, tags, ...) -> {"mode","intent","targets"}`
- `MotorController.send(command)` + `MotorController.read_feedback() -> feedback dict`
- `RetryController.run_retry_loop(...) -> final_cmd, fb_final, retries_used, fb_initial`
- `build_action_packet(...) -> packet dict`

## Safety expectations
- Always validate/clip targets before sending to motors
- Retry logic must never exceed safe bounds
- Fault injection must be strictly opt-in via config/scenario

## Logs & Reproducibility
- Each run writes to `runs/<RUN_FOLDER>/packets.jsonl`
- Replay/report tools operate purely from the jsonl file