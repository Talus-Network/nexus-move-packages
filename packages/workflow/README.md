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
Sui. They support dependency resolution and compilation. Local tests that
invoke native Nexus functions cannot execute. Use the Testnet deployment for
integration tests.

Nexus Kernel is resolved transitively and should not be added directly. This
package is a dependency only. Do not publish it. Source verification against
the onchain bytecode is expected to report differences because this repository
does not contain the implementation source.
