# Nexus Workflow

Public Move interfaces for reading and validating Nexus workflow and DAG
execution state. Workflow mutations are available through Nexus Scheduler.

## Add the package

For Testnet:

```sh
mvr add @talus/nexus-workflow --network testnet
sui move build --build-env testnet
```

For Mainnet:

```sh
mvr add @talus/nexus-workflow --network mainnet
sui move build --build-env mainnet
```

## Documentation

See the [Nexus Workflow Move reference](https://docs.talus.network/reference/move/nexus_workflow).

## Local development

These sources are interface declarations for the Nexus package published on
Sui. They support dependency resolution, compilation, and local module
extensions. Existing Nexus functions abort during local execution. Use
extensions to construct and inspect values needed by application tests. Use the
Testnet deployment when a test must execute published Nexus behavior. See
[Local Move tests](../../README.md#local-move-tests).

Nexus Kernel is resolved transitively and should not be added directly. This
package is a dependency only. Do not publish it. Source verification against
the onchain bytecode is expected to report differences because this repository
does not contain the implementation source.
