# Nexus Move packages

Move interfaces used to compile against the published Nexus protocol packages.

These packages contain the data types and function signatures needed for
composition. Calls resolve to the packages published on Sui. These interface
packages are dependencies only and must not be published.

> These packages provide interfaces for compiling against the published Nexus
> packages. Local Move tests may test application logic that does not invoke
> Nexus. Tests executing Nexus functions require the Testnet deployment. Local
> executable mocks are planned for a later release.

The `public native fun` declarations intentionally have no local
implementation. They support compilation, but a local Move test cannot execute
them.

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
