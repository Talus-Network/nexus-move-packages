# Nexus Tool

Public interfaces for registering, pricing, authorizing, invoking, settling, and migrating onchain and offchain Tools in Nexus.

> **Important:** This is an interface package for compilation. Its local function bodies are deliberate aborting stubs, not the published Nexus implementation and not a local mock.

## When to use this package

Add `nexus_tool` when application code directly interacts with Tool identity, registration, invocation policy, entitlements, cashiers, or Tool package pointers. It exposes these interface modules:

- `era`
- `external_verifier`
- `finite_credits`
- `fixed_price`
- `invocation`
- `main`
- `time_pass`
- `tool_authority`
- `tool_cashier`
- `tool_registry`

## Add the dependency

```toml
[dependencies]
nexus_tool = { r.mvr = "@talus/nexus-tool" }
```

The basic Nexus packages are resolved transitively. Build for the selected network:

```sh
sui move build --build-env testnet
# Use --build-env mainnet only for a Mainnet production build.
```

## What happens at runtime

- `sui move build` reads these declarations and links the consumer to the selected network's published `nexus_tool` address.
- `sui move test` runs the local interface stubs. A direct Nexus call aborts with `ELocalExecutionUnavailable`.
- `nexus tap test` replaces the stubs in the test VM with the selected published Nexus bytecode.
- A submitted Testnet or Mainnet transaction executes the Nexus bytecode at the published address, not the local aborting body.

## Local and integration tests

Run TAP suites that call Nexus with `nexus tap test --path tap`. Use `#[test_only]` module extensions for Tool setup, inspection, and cleanup when public constructors are not enough. Extensions require `edition = "2024.alpha"` and cannot replace existing functions.

Test live Tool registration, external service access, transaction effects, gas, and network routing on Testnet.

Read the complete [TAP development and testing guide](https://github.com/Talus-Network/nexus-move-packages/blob/main/docs/tap_development.md) and the [onchain Tool guide](https://docs.talus.network/guides/tool-development/build-onchain-tool).

## Documentation

- [Onchain development setup](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
- [Nexus Tool Move reference](https://docs.talus.network/reference/move/nexus_tool)

## Safety

Do not publish this package or use it to upgrade Nexus. Source verification against published Nexus bytecode is expected to report a mismatch because this repository contains interfaces rather than implementation source.
