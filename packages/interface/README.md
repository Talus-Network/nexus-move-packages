# Nexus Interface

Public types and function signatures shared by Nexus agents, DAGs, graphs,
payments, authorization, schemas, results, and verifiers.

> **Important:** This is an interface package for compilation. Its local
> function bodies are deliberate aborting stubs, not the published Nexus
> implementation and not a local mock.

## When to use this package

Add `nexus_interface` when application code directly uses the common Nexus
domain model. It exposes these interface modules:

- `agent`
- `authorization`
- `dag`
- `distributed_event`
- `era`
- `graph`
- `meta_schema`
- `onchain_tool_result`
- `payment`
- `verifier`
- `version`

## Add the dependency

```toml
[dependencies]
nexus_interface = { r.mvr = "@talus/nexus-interface" }
```

`nexus_primitives` is resolved transitively. Build for the selected network:

```sh
sui move build --build-env testnet
# Use --build-env mainnet only for a Mainnet production build.
```

## What happens at runtime

- `sui move build` reads these declarations and links the consumer to the
  selected network's published `nexus_interface` address.
- `sui move test` runs locally. Calling an existing interface function aborts
  with `ELocalExecutionUnavailable` because the implementation is not here.
- A submitted Testnet or Mainnet transaction executes the Nexus bytecode at
  the published address, not the local aborting body.

## Local tests

Use a `#[test_only]` module extension under the consumer package's `tests/`
directory when application logic needs a Nexus value that public consumer code
cannot construct or inspect. Module extensions require
`edition = "2024.alpha"`.

An extension shares the scope of the module it extends, so it can add the
smallest constructor or observation needed by the test. It cannot override an
existing function and must not be used as evidence for published validation,
authorization, payment, or verifier behavior.

Read the complete
[stub and testing guide](https://github.com/Talus-Network/nexus-move-packages#local-move-tests)
and run the
[executable example](https://github.com/Talus-Network/nexus-move-packages/tree/main/examples/local_testing).

Use a real Testnet transaction for behavior that crosses into Nexus.
`--build-env testnet` resolves Testnet dependencies; it does not make the local
Move test VM call Testnet.

## Documentation

- [Onchain development setup](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
- [Nexus Interface Move reference](https://docs.talus.network/reference/move/nexus_interface)

## Safety

Do not publish this package or use it to upgrade Nexus. Source verification
against published Nexus bytecode is expected to report a mismatch because this
repository contains interfaces rather than implementation source.
