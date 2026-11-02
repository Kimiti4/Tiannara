# Checkpoint 18.61 — hardware integration addendum

**Frozen source:** `68d27377d60e17543bc0ec4901a9ee141852a0e0`  
**Scope:** physical deployment, hardware adapter contract, safety verification, telemetry adapters, Meta Hardware subsystem, and tests.  
**Method:** source inspection and targeted caller/path searches only. No hardware was attached; no runtime, compilation, tests, electrical safety checks, or physical actuation was performed.

## Hardware-related source inventory

| Path | What it contains | Evidence classification |
|---|---|---|
| `lib/tiannara/asc/reality/physical_adapter.ex` | Generic adapter callbacks: capabilities, status, execute_action, emergency_stop | Interface contract only |
| `lib/tiannara/asc/reality/physical_deployment_manager.ex` | Deployment lifecycle, approval stage, adapter dispatch, emergency stop/resume | Implemented orchestration, default adapter is simulated |
| `lib/tiannara/asc/reality/adapters/simulated_adapter.ex` | In-memory action recording and simulated E-stop state | Explicit simulation, not hardware |
| `lib/tiannara/asc/reality/safety_verification_engine.ex` | Safety constraint checks | Currently unconditional pass implementation |
| `lib/tiannara/asc/reality/reality_supervisor.ex` | Supervises simulated adapter, safety engine and deployment manager | Runtime wiring for simulation |
| `lib/tiannara/telemetry/adapter.ex` | Generic telemetry behaviour and live BEAM RuntimeAdapter | Runtime metrics only; no hardware adapter found in targeted search |
| `lib/tiannara/meta/hardware/supervisor.ex` | Registry, HorizonScheduler and three EHTC workers | Internal compute subsystem |
| `lib/tiannara/meta/hardware/horizon_scheduler.ex` | Routes payloads to EHTC workers | Internal queue routing |
| `lib/tiannara/meta/hardware/event_horizon_tensor_core.ex` | Queues payloads and spawns compute tasks; comments explicitly describe simulation | Simulated/internal compute, not a device driver |
| `test/tiannara/asc/reality/physical_deployment_manager_test.exs` | Lifecycle tests using SimulatedAdapter | Tests simulation and stage logic only |
| `test/tiannara/asc/reality/physical_deployment_property_test.exs` | Property tests of approval lifecycle using SimulatedAdapter | Tests simulation and stage logic only |

The existing MC-003-A0 architecture assessment independently classifies hardware/robotics execution as absent and the SimulatedAdapter as simulation. The present source inspection is consistent with that assessment.

## Detailed observations

### H-01 — No concrete physical-device adapter established

The PhysicalAdapter behaviour is a useful abstraction, but the inspected implementation is only `Adapters.SimulatedAdapter`. The telemetry behaviour has a live BEAM runtime adapter but no concrete sensor/device telemetry adapter was identified in targeted repository searches. No verified driver integration for GPIO, I2C, SPI, UART/serial, USB, CAN, ROS/ROS 2, microcontroller firmware, or robot control was found in this pass.

This is a bounded finding: the search does not prove that no hardware-related file exists anywhere in the repository. A full path inventory and dependency/caller graph is still needed.

**RL-405 OPEN — Physical hardware integration is not demonstrated by the current deployment adapter path.** The configured default adapter is simulated and records actions in memory; no concrete hardware adapter or verified device I/O path was established.

### H-02 — Safety verification unconditionally passes every constraint

In `SafetyVerificationEngine.check_constraint/3`, every constraint returns `status: :pass` without inspecting the constraint, artifact, or parameters. Thus `verify/2` can report `passed: true` and `critical_safe: true` even though no physical bounds, interlocks, emergency-stop circuit, power limits, collision envelope, watchdog, or device-specific hazards have been measured or validated.

**RL-406 OPEN — Physical safety verification is non-evidentiary.** The safety gate reports pass for all supplied artifacts because the constraint checker is unconditional; it cannot certify a physical deployment.

### H-03 — Physical lifecycle labels exceed the evidence they represent

The manager permits transitions from `:simulated` to `:dry_run` to `:supervised` without recording simulation results, dry-run evidence, a supervisor identity, or supervision observations. The next transition to `:autonomous` checks only whether the adapter's `status/0` returns `%{active: true}`. With the simulated adapter, a single recorded action sets active true. That is not evidence of a completed simulation, supervised operation, or safety case.

**RL-407 OPEN — Deployment stage transitions can assert dry-run, supervised and autonomous states without corresponding evidence.** The stage names are not bound to verifiable stage artifacts or independent acceptance checks.

### H-04 — Adapter contract and manager disagree on E-stop reset

The PhysicalAdapter behaviour declares `emergency_stop/0` but does not declare `clear_estop/0`. The manager's `resume/1` unconditionally calls `deployment.adapter.clear_estop()`. This works for the current SimulatedAdapter because it defines an extra function, but a conforming future hardware adapter need not implement it. The manager also does not inspect or independently verify the return from the emergency-stop callback before updating its own `estop_active` flag.

**RL-408 OPEN — E-stop lifecycle is not fully specified or verified by the adapter contract.** A conforming adapter may not implement the manager's reset call, and the manager treats the stop callback as successful without independent confirmation of the physical safe state.

### H-05 — Approval identity is caller-supplied data, not authenticated authority

`approve/3` accepts an arbitrary `approver` value and records it in the deployment struct. The inspected path does not authenticate that identity, bind approval to a user/session/credential, require a Council authorization, or bind the approval cryptographically to the exact design/plan/safety evidence hash. The test uses the literal string `"tiannara-admin"`; this demonstrates data recording, not authentication.

**RL-409 OPEN — Physical deployment approval is not bound to authenticated human authority or immutable approved artifact identity.** A caller-supplied approver string can populate the approval field without proof of identity or evidence that the exact plan being executed was approved.

### H-06 — Action dispatch has no adapter capability or action-schema enforcement at the manager boundary

The adapter exposes `capabilities/0`, but `PhysicalDeploymentManager.execute/2` does not consult it before forwarding an arbitrary action map to `execute_action/1`. It checks deployment stage and the manager's E-stop flag only. The simulated adapter accepts and records arbitrary action maps. No device-specific range checks, typed command schema, units, interlocks, rate limits, authorization token, command expiry, replay protection, or feedback-confirmation contract is visible here.

**RL-410 OPEN — Physical action dispatch is not bound to declared adapter capabilities or validated device-specific command constraints.** The manager forwards arbitrary action maps to the selected adapter once the lifecycle stage permits execution.

## Hardware subsystem distinction

The `Tiannara.Meta.Hardware` tree is not evidence of robotics/device integration. Its supervisor starts a Registry, a HorizonScheduler and three EventHorizonTensorCore workers. The EHTC module describes itself as simulating tensor-core work; it drains queued payloads and spawns tasks that apply internal transforms and parity validation. No GPU driver, CUDA/OpenCL/Vulkan device enumeration, PCIe access, accelerator telemetry, or external hardware device protocol is established by these inspected files. Treat the GPU execution bridge claims in the Phase 5F.11 report separately and verify the actual source/callers before classifying them as hardware execution.

## Test evidence and limits

The physical deployment unit and property tests exercise the staged lifecycle with SimulatedAdapter. They establish behavior of the in-memory simulator and approval-stage transition logic under test conditions. They do not demonstrate physical device discovery, electrical I/O, real actuator control, sensor feedback, fail-safe behavior on a real controller, loss-of-connection handling, watchdog expiry, hardware-in-loop tests, or independent safety certification. Tests were not run in this audit pass.

## Disposition

- RL-405 through RL-410: **OPEN**.
- No existing findings closed.
- No source code modified.
- No hardware attached; no physical actuation attempted.
- No runtime/build/test verification performed.

## Required next investigation

1. Perform a complete tree inventory for hardware, robotics, embedded, device, sensor, actuator, firmware, ROS, GPIO, I2C, SPI, UART, USB, CAN, CUDA, ROCm, OpenCL and Vulkan references, including ignored/excluded paths and dependency manifests.
2. Trace every caller of PhysicalDeploymentManager and every configured adapter, including configuration paths and feature flags.
3. Inspect the GPU bridge source and prove whether it reaches an actual accelerator API or only schedules CPU-side/simulated work.
4. Inspect the robotics/control modules for sensor ingestion, state estimation, control loops, actuator command generation, feedback, watchdogs and emergency-stop wiring.
5. Define a hardware-in-loop verification plan with simulated, bench, fault-injection and independently reviewed safety stages. Do not connect or actuate real equipment until safety gates and human authorization are demonstrated.
