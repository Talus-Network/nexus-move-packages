# Nexus Move packages

Public Move interfaces for applications that use the Nexus protocol packages
published on Sui.

> **Important:** This repository contains source interfaces, not the private
> Nexus implementation. Use the packages as dependencies. Do not publish them,
> upgrade Nexus from them, or treat their stub bodies as protocol mocks.

The interfaces preserve public type layouts and supported function signatures.
TAP unit tests can execute the exact Nexus bytecode published on Testnet or
Mainnet through `nexus tap test` without access to Nexus source.

## Start a TAP

Create the complete project layout:

```sh
nexus tap scaffold --name content-review
cd content-review
```

Run the generated Move suite with published Testnet Nexus bytecode:

```sh
nexus tap test --path tap
```

Then validate the Move package, DAG, and skill configuration:

```sh
nexus tap validate-skill --config skill.tap.json
```

Read the [TAP development and testing guide](docs/tap_development.md) for the
complete application example, fixture patterns, unit test limits, Testnet
publication, execution, and release checklist.

## How the interfaces are used

<!-- markdownlint-disable MD013 -->

| Context | Behavior |
| --- | --- |
| `sui move build` | The compiler reads these interfaces and links the TAP to the Nexus addresses selected by the build environment. |
| `sui move test` | The local VM sees interface stub bodies. A direct Nexus function call intentionally aborts. |
| `nexus tap test` | The CLI fetches the selected published Nexus modules, adds developer test extension functions in memory, and runs the Move suite locally. |
| Testnet or Mainnet transaction | Sui executes the Nexus package and TAP package published on that network with live objects and transaction effects. |

<!-- markdownlint-enable MD013 -->

`nexus tap test` does not need a wallet, private key, gas, or Nexus source. It
does need network access to resolve MVR packages and read published bytecode.

## Choose packages

Add every package imported directly by TAP source or tests. MVR resolves the
remaining dependency graph.

<!-- markdownlint-disable MD013 -->

| Move package | MVR name | Main purpose |
| --- | --- | --- |
| `nexus_primitives` | `@talus/nexus-primitives` | Data, authorization primitives, ownership helpers, events, proofs, shared object references, and tagged output |
| `nexus_interface` | `@talus/nexus-interface` | Agents, DAGs, graphs, payments, schemas, results, and verifiers |
| `nexus_tool` | `@talus/nexus-tool` | Tool registration, invocation, pricing, entitlements, cashiers, and migration |
| `nexus_registry` | `@talus/nexus-registry` | Agent and Leader registries, network keys, verification, and priority fees |
| `nexus_workflow` | `@talus/nexus-workflow` | Supported workflow execution reads, validation, and invocation requests |
| `nexus_scheduler` | `@talus/nexus-scheduler` | Tasks, schedules, execution, result submission, and settlement |

<!-- markdownlint-enable MD013 -->

`nexus_kernel` is protocol support code and has no public MVR name. Do not add
it directly.

Example manifest:

```toml
[package]
name = "my_tap"
version = "1.0.0"
edition = "2024.alpha"

[dependencies]
nexus_interface = { r.mvr = "@talus/nexus-interface" }
nexus_primitives = { r.mvr = "@talus/nexus-primitives" }
```

Use `edition = "2024.alpha"` when tests contain module extensions. Use the
plain `2024` edition when they do not.

Build for the target environment:

```sh
sui move build --build-env testnet
sui move build --build-env mainnet
```

The build environment selects addresses and package records. It does not make
`sui move test` communicate with a network.

## Unit test private Nexus shapes

Use public Nexus constructors first. When a test needs a private field, enum
variant, invalid value, or focused view, add one developer owned extension:

```move
#[test_only]
extend module nexus_primitives::data;

/// Creates invalid data for a TAP rejection test.
public fun unchecked_many_for_testing(values: vector<NexusValue>): NexusData {
    NexusData::Many { values }
}
```

The extension has module scope, so it can use the private layout described by
the interface. It cannot replace an existing Nexus function. The CLI appends
only new extension functions to the published module and rejects ABI or layout
mismatches.

Run the suite:

```sh
nexus tap test --path tap
```

Useful variants:

```sh
nexus tap test --path tap --list
nexus tap test --path tap complete_flow
nexus tap test --path tap --threads 1
nexus tap test --path tap --build-env mainnet
```

The [complete executable example](examples/local_testing) tests a TAP owned
success path, rejection path, state updates, published Nexus validation,
expected failure, private value fixture, and extensions across Nexus packages.

## Testing boundary

<!-- markdownlint-disable MD013 -->

| Evidence | Use it for | It does not prove |
| --- | --- | --- |
| Build | Types, imports, addresses, and package graph | Runtime behavior |
| Local TAP unit tests | TAP behavior and reachable published Nexus behavior with constructed state | Live shared state, gas, RPC, consensus, or external services |
| Testnet integration | Publication, transaction effects, current protocol objects, events, Tool access, and complete workflow execution | Mainnet configuration |
| Mainnet compatibility check | Compilation and unit behavior against Mainnet Nexus bytecode | A safe Mainnet transaction with live production state |

<!-- markdownlint-enable MD013 -->

Unit test the whole deterministic TAP flow whenever its state can be
constructed locally. Move to Testnet when the next assertion depends on live
objects, network routing, gas, leaders, an offchain Tool, or a submitted
transaction.

## Package guides

Each package directory explains its supported consumer surface:

1. [`nexus_primitives`](packages/primitives)
2. [`nexus_interface`](packages/interface)
3. [`nexus_tool`](packages/tool)
4. [`nexus_registry`](packages/registry)
5. [`nexus_workflow`](packages/workflow)
6. [`nexus_scheduler`](packages/scheduler)

Move API reference and Nexus setup documentation are available in the
[Talus developer documentation](https://docs.talus.network/).

## Source and publication safety

Each package has a `Published.toml` file that records Testnet and Mainnet
deployments for dependency resolution. These records do not make the interface
source equal to the published implementation.

Do not publish an interface package. Do not use one to upgrade Nexus. Source
verification against Nexus is expected to report a mismatch because the
implementation source is intentionally absent.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
