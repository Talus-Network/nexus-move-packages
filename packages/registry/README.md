# Nexus Registry

Public interfaces for Nexus agent and Leader registries, network keys, registered key verification, and priority fee administration.

> **Important:** This is an interface package for compilation. Its local function bodies are deliberate aborting stubs, not the published Nexus implementation and not a local mock.

## When to use this package

Add `nexus_registry` when application code directly reads or changes Nexus registry state. It exposes these interface modules:

- `agent_registry`
- `era`
- `leader`
- `leader_cap`
- `leader_slashing`
- `main`
- `network_auth`
- `priority_fee_vault`
- `registered_key_verifier`

## Add the dependency

```toml
[dependencies]
nexus_registry = { r.mvr = "@talus/nexus-registry" }
```

The basic Nexus packages, including the internal kernel, are resolved transitively. Build for the selected network:

```sh
sui move build --build-env testnet
# Use --build-env mainnet only for a Mainnet production build.
```

## What happens at runtime

- `sui move build` reads these declarations and links the consumer to the selected network's published `nexus_registry` address.
- `sui move test` runs the local interface stubs. A direct Nexus call aborts with `ELocalExecutionUnavailable`.
- `nexus tap test` replaces the stubs in the test VM with the selected published Nexus bytecode.
- A submitted Testnet or Mainnet transaction executes the Nexus bytecode at the published address, not the local aborting body.

## Local and integration tests

Run TAP suites that call Nexus with `nexus tap test --path tap`. Use `#[test_only]` module extensions for the registry setup, inspection, and cleanup that a test needs. Extensions require `edition = "2024.alpha"` and cannot replace existing functions.

Exercise live registry objects, transaction effects, gas, and network routing on Testnet.

Read the complete [TAP development and testing guide](https://github.com/Talus-Network/nexus-move-packages/blob/main/docs/tap_development.md).

## Documentation

- [Onchain development setup](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
- [Nexus Registry Move reference](https://docs.talus.network/reference/move/nexus_registry)

## Safety

Do not publish this package or use it to upgrade Nexus. Source verification against published Nexus bytecode is expected to report a mismatch because this repository contains interfaces rather than implementation source.
