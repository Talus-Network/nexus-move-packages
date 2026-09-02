# Nexus Tool

Public interfaces for registering, pricing, authorizing, invoking, settling,
and migrating onchain and offchain Tools in Nexus.

> **Important:** This is an interface package for compilation. Its local
> function bodies are deliberate aborting stubs, not the published Nexus
> implementation and not a local mock.

## When to use this package

Add `nexus_tool` when application code directly interacts with Tool identity,
registration, invocation policy, entitlements, cashiers, or Tool package
pointers. It exposes these interface modules:

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

The basic Nexus packages are resolved transitively. Build for the selected
network:

```sh
sui move build --build-env testnet
# Use --build-env mainnet only for a Mainnet production build.
```

## What happens at runtime

- `sui move build` reads these declarations and links the consumer to the
  selected network's published `nexus_tool` address.
- `sui move test` runs locally. Calling an existing interface function aborts
  with `ELocalExecutionUnavailable` because the implementation is not here.
- A submitted Testnet or Mainnet transaction executes the Nexus bytecode at
  the published address, not the local aborting body.

## Local and integration tests

Use `#[test_only]` module extensions for local tests that need specific Tool
value shapes. Extensions require `edition = "2024.alpha"`, can add minimal test
helpers, and cannot replace Tool registration, pricing, authorization,
accounting, or settlement behavior.

Test those behaviors with real Testnet transactions and assert successful
effects, emitted events, and object readback. `--build-env testnet` selects the
dependency graph; `sui move test` still executes only in the local VM.

Read the complete
[stub and testing guide](https://github.com/Talus-Network/nexus-move-packages#local-move-tests)
and the
[onchain Tool guide](https://docs.talus.network/guides/tool-development/build-onchain-tool).

## Documentation

- [Onchain development setup](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
- [Nexus Tool Move reference](https://docs.talus.network/reference/move/nexus_tool)

## Safety

Do not publish this package or use it to upgrade Nexus. Source verification
against published Nexus bytecode is expected to report a mismatch because this
repository contains interfaces rather than implementation source.
