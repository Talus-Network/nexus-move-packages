# Nexus Workflow

Public interfaces for reading and validating Nexus workflow and DAG execution state. Authorized workflow mutations are exposed through Nexus Scheduler.

> **Important:** This is an interface package for compilation. Its local function bodies are deliberate aborting stubs, not the published Nexus implementation and not a local mock.

## Supported consumer surface

The package intentionally exposes only declarations intended for direct composition:

- `execution::DAGExecution` and its public read and validation helpers;
- `invocation_adapter::new_request` and `invocation_adapter::is_locked`.

Internal workflow storage, values used only during settlement, event layouts, and functions requiring runtime permits are omitted. Use `nexus_scheduler` for the authorized mutation paths.

## Add the dependency

```toml
[dependencies]
nexus_workflow = { r.mvr = "@talus/nexus-workflow" }
```

The basic Nexus packages, including the internal kernel, are resolved transitively. Build for the selected network:

```sh
sui move build --build-env testnet
# Use --build-env mainnet only for a Mainnet production build.
```

## What happens at runtime

- `sui move build` reads these declarations and links the consumer to the selected network's published `nexus_workflow` address.
- `sui move test` runs the local interface stubs. A direct Nexus call aborts with `ELocalExecutionUnavailable`.
- `nexus tap test` replaces the stubs in the test VM with the selected published Nexus bytecode.
- A submitted Testnet or Mainnet transaction executes the Nexus bytecode at the published address, not the local aborting body.

## Local and integration tests

Run TAP suites that call Nexus with `nexus tap test --path tap`. Use `#[test_only]` module extensions to construct or observe workflow value shapes needed by the TAP. Extensions require `edition = "2024.alpha"` and cannot replace existing functions.

Exercise live workflow objects, transaction effects, gas, leader behavior, and external services on Testnet.

Read the complete [TAP development and testing guide](https://github.com/Talus-Network/nexus-move-packages/blob/main/docs/tap_development.md).

## Documentation

- [Onchain development setup](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
- [Nexus Workflow Move reference](https://docs.talus.network/reference/move/nexus_workflow)

## Safety

Do not publish this package or use it to upgrade Nexus. Source verification against published Nexus bytecode is expected to report a mismatch because this repository contains interfaces rather than implementation source.
