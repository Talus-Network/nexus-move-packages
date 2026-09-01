# Nexus Move packages

Move interfaces used to compile against the published Nexus protocol packages.

These packages contain the data types and function signatures needed for
composition. Calls resolve to the packages published on Sui. These interface
packages are dependencies only and must not be published.

> These packages provide interfaces for compiling against the published Nexus
> packages. Local Move tests can load the interfaces and add test extensions
> that construct and inspect Nexus values. A call to an existing Nexus function
> aborts locally. Use Testnet when a test must execute published Nexus behavior.

Every interface function has an ordinary Move body that aborts with a clear
local execution error. The body is not a Nexus implementation. It allows the
Move test runner to load dependency modules while preserving an explicit
failure when a test crosses the Nexus boundary.

## MVR dependencies

For Testnet development, run these commands from your Move package:

```sh
mvr add @talus/nexus-scheduler --network testnet
sui move build --build-env testnet
```

For Mainnet, use the Mainnet registry and build environment:

```sh
mvr add @talus/nexus-scheduler --network mainnet
sui move build --build-env mainnet
```

Replace `nexus-scheduler` with another listed MVR package when your application
needs only that package. The package manager resolves its transitive
dependencies.

## Networks

Use Testnet while developing integrations that call Nexus. Use Mainnet for
production transactions. Every package includes a `Published.toml` file that
records its Testnet and Mainnet deployment.

Local Move tests may cover application logic that does not call Nexus. Tests
that execute Nexus functions must run against the Testnet deployment.

## Local Move tests

Module extensions let test code construct and inspect Nexus values without
adding public test helpers to an application module. An extension shares the
target module scope, so it can access fields and variants that application code
cannot access directly. Extensions are additive. An extension cannot replace
an existing Nexus function, and it does not reproduce published Nexus behavior.

Module extensions currently require the alpha form of the Move 2024 edition.
Set this edition in the consumer package:

```toml
[package]
edition = "2024.alpha"
```

Place an extension in the consumer package test directory. The
`#[test_only]` attribute keeps its helpers out of production bytecode:

```move
#[test_only]
extend module nexus_primitives::data;

/// Creates an inline [NexusValue] wrapped in one [NexusData] value.
///
/// This helper constructs the value directly because [inline_data_value] and
/// [one] represent published Nexus behavior and abort during local execution.
public fun inline_for_testing(bytes: vector<u8>): NexusData {
    NexusData::One {
        value: NexusValue::InlineData { bytes },
    }
}

/// Returns the byte length of an inline [NexusValue] wrapped in one
/// [NexusData] value.
///
/// Returns zero for every other [NexusData] shape.
public fun inline_length_for_testing(self: &NexusData): u64 {
    match (self) {
        NexusData::One {
            value: NexusValue::InlineData { bytes },
        } => bytes.length(),
        _ => 0,
    }
}
```

A test calls these helpers through the module it extends:

```move
let value = data::inline_for_testing(b"hello");
assert_eq!(value.inline_length_for_testing(), 5);
```

Run consumer tests with the network build environment used to resolve the MVR
dependency:

```sh
sui move test --build-env testnet
```

Use extensions for the Nexus values and observations that application logic
needs. Keep calls to existing Nexus functions at a small application boundary,
then use Testnet to test that boundary against published behavior. See the
[local testing example](examples/local_testing) for an executable consumer
package.

## Workflow interface

`nexus_workflow` exposes only the workflow declarations intended for direct
composition:

- `execution::DAGExecution` and its public read and validation helpers
- `invocation_adapter::new_request` and `invocation_adapter::is_locked`

Workflow mutations are exposed through `nexus_scheduler`, which is the
authorized runtime facade. Functions requiring `RuntimePermit`, internal
storage and version types, values used only during settlement, and workflow
event layouts are intentionally omitted. Their omission does not alter the
packages already published onchain; it defines the supported interface surface
of this repository.

## Packages

| Package | Intended MVR name | Use |
| --- | --- | --- |
| `nexus_primitives` | `@talus/nexus-primitives` | Direct dependency |
| `nexus_interface` | `@talus/nexus-interface` | Direct dependency |
| `nexus_tool` | `@talus/nexus-tool` | Direct dependency |
| `nexus_registry` | `@talus/nexus-registry` | Direct dependency |
| `nexus_workflow` | `@talus/nexus-workflow` | Direct dependency |
| `nexus_scheduler` | `@talus/nexus-scheduler` | Direct dependency |
| `nexus_kernel` | None | Transitive dependency only |

`nexus_kernel` supports the package graph but is not intended for direct use.
Applications should not add it as a direct dependency.

## Source verification

This repository contains interface declarations, not the implementation source
used to build the published bytecode. `sui client verify-source` is therefore
expected to report bytecode mismatches. The interfaces support compilation
against the published package addresses, not exact source verification.

Do not publish these interface packages.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
