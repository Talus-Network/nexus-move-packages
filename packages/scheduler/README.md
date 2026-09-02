# Nexus Scheduler

Public interfaces for creating and scheduling Tasks, executing workflows,
submitting results, settling executions, and managing Task lifecycle.

> **Important:** This is an interface package for compilation. Its local
> function bodies are deliberate aborting stubs, not the published Nexus
> implementation and not a local mock.

## When to use this package

Add `nexus_scheduler` when application code needs the main authorized
runtime facade. It exposes these interface modules:

- `era`
- `execution_entries`
- `execution_settlement`
- `execution_submission`
- `invocation_adapter`
- `schedule`
- `scheduler`
- `task`

## Add the dependency

```toml
[dependencies]
nexus_scheduler = { r.mvr = "@talus/nexus-scheduler" }
```

The complete Nexus dependency graph, including the internal kernel, is
resolved transitively. Build for the selected network:

```sh
sui move build --build-env testnet
# Use --build-env mainnet only for a Mainnet production build.
```

## What happens at runtime

- `sui move build` reads these declarations and links the consumer to the
  selected network's published `nexus_scheduler` address.
- `sui move test` runs the local interface stubs. A direct Nexus call aborts
  with `ELocalExecutionUnavailable`.
- `nexus tap test` replaces the stubs in the test VM with the selected
  published Nexus bytecode.
- A submitted Testnet or Mainnet transaction executes the Nexus bytecode at
  the published address, not the local aborting body.

## Local and integration tests

Run TAP suites that call Nexus with `nexus tap test --path tap`. Use
`#[test_only]` module extensions for Task, schedule, and status setup or
inspection when public constructors are not enough. Extensions require
`edition = "2024.alpha"` and cannot replace existing functions.

Test live shared objects, transaction effects, gas, leader selection, and
network routing on Testnet. Require successful effects, assert lifecycle
events, and read back Task and execution state.

Read the complete
[TAP development and testing guide](https://github.com/Talus-Network/nexus-move-packages/blob/main/docs/tap_development.md)
and run the
[executable example](https://github.com/Talus-Network/nexus-move-packages/tree/main/examples/local_testing).

## Documentation

- [Onchain development setup](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
- [Nexus Scheduler Move reference](https://docs.talus.network/reference/move/nexus_scheduler)

## Safety

Do not publish this package or use it to upgrade Nexus. Source verification
against published Nexus bytecode is expected to report a mismatch because this
repository contains interfaces rather than implementation source.
