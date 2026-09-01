# Nexus Primitives

Foundational Move data types, authorization primitives, ownership helpers, and
object utilities used across Nexus.

## Add the package

For Testnet:

```sh
mvr add @talus/nexus-primitives --network testnet
sui move build --build-env testnet
```

For Mainnet:

```sh
mvr add @talus/nexus-primitives --network mainnet
sui move build --build-env mainnet
```

## Documentation

See the [Nexus Primitives Move reference](https://docs.talus.network/reference/move/nexus_primitives).

## Local development

These sources are interface declarations for the Nexus package published on
Sui. They support dependency resolution, compilation, and local module
extensions. Existing Nexus functions abort during local execution. Use
extensions to construct and inspect values needed by application tests. Use the
Testnet deployment when a test must execute published Nexus behavior. See
[Local Move tests](../../README.md#local-move-tests).

This package is a dependency only. Do not publish it. Source verification
against the onchain bytecode is expected to report differences because this
repository does not contain the implementation source.
