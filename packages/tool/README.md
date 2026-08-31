# Nexus Tool

Move interfaces for registering, pricing, authorizing, and invoking onchain
and offchain tools in Nexus.

## Add the package

For Testnet:

```sh
mvr add @talus/nexus-tool --network testnet
sui move build --build-env testnet
```

For Mainnet:

```sh
mvr add @talus/nexus-tool --network mainnet
sui move build --build-env mainnet
```

## Documentation

See the [Nexus Tool Move reference](https://docs.talus.network/reference/move/nexus_tool).

## Local development

These sources are interface declarations for the Nexus package published on
Sui. They support dependency resolution and compilation. Local tests that
invoke native Nexus functions cannot execute. Use the Testnet deployment for
integration tests.

This package is a dependency only. Do not publish it. Source verification
against the onchain bytecode is expected to report differences because this
repository does not contain the implementation source.
