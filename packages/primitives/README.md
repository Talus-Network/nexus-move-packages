# Nexus Primitives

Public interfaces for the basic values and capabilities shared across the Nexus protocol.

> **Important:** This is an interface package for compilation. Its local function bodies are deliberate aborting stubs, not the published Nexus implementation and not a local mock.

## When to use this package

Add `nexus_primitives` when application code directly uses Nexus data values, authorization proofs, ownership capabilities, object state helpers, shared object references, events, or tagged outputs.

The package exposes these interface modules:

- `authorization`
- `data`
- `event`
- `object_state`
- `owner_cap`
- `proof_of_uid`
- `shared_object`
- `tagged_output`

## Add the dependency

```toml
[dependencies]
nexus_primitives = { r.mvr = "@talus/nexus-primitives" }
```

Build for the selected network:

```sh
sui move build --build-env testnet
# Use --build-env mainnet only for a Mainnet production build.
```

## What happens at runtime

- `sui move build` reads these declarations and links the consumer to the selected network's published `nexus_primitives` address.
- `sui move test` runs the local interface stubs. A direct Nexus call aborts with `ELocalExecutionUnavailable`.
- `nexus tap test` replaces the stubs in the test VM with the selected published Nexus bytecode.
- A submitted Testnet or Mainnet transaction executes the Nexus bytecode at the published address, not the local aborting body.

## Local tests

Run TAP suites that call Nexus with:

```sh
nexus tap test --path tap
```

Use a `#[test_only]` module extension under the TAP package's `tests/` directory when a test needs to construct or inspect a private Nexus value shape. Module extensions require `edition = "2024.alpha"`. They can add helpers but cannot replace an existing Nexus function.

For example, an extension of `nexus_primitives::data` can construct the exact `NexusData` variant needed by an application test. Keep the helper minimal and name it with a `_for_testing` suffix.

Read the complete [TAP development and testing guide](https://github.com/Talus-Network/nexus-move-packages/blob/main/docs/tap_development.md) and run the [executable example](https://github.com/Talus-Network/nexus-move-packages/tree/main/examples/local_testing).

Use a real Testnet transaction for live shared state, publication, transaction effects, gas, network routing, and external services.

## Documentation

- [Onchain development setup](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
- [Nexus Primitives Move reference](https://docs.talus.network/reference/move/nexus_primitives)

## Safety

Do not publish this package or use it to upgrade Nexus. Source verification against published Nexus bytecode is expected to report a mismatch because this repository contains interfaces rather than implementation source.
