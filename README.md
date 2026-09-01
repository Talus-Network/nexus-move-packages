# Nexus Move packages

Public Move interfaces for compiling applications against the Nexus protocol
packages published on Sui.

> **Important:** This repository contains interface stubs, not the Nexus
> implementation. Add these packages as dependencies. Do not publish them,
> upgrade from them, or treat their local function bodies as mocks of Nexus
> behavior.

The stubs preserve the type layouts and public function signatures in the
supported consumer surface. The implementation remains in the Nexus packages
published on Testnet and Mainnet.

## How the stubs work

The same dependency has different roles during compilation, local testing, and
network execution:

<!-- markdownlint-disable MD013 -->

| Context | What happens |
| --- | --- |
| `sui move build` | The compiler reads these interfaces to check types and link the consumer package against the selected network's published Nexus addresses. |
| `sui move test` | The Move test VM loads the interface modules locally. Every existing Nexus function body aborts with `ELocalExecutionUnavailable`; no published Nexus behavior is reproduced. |
| Testnet or Mainnet transaction | The transaction calls the Nexus package at its published address. Sui executes the published bytecode, not the aborting body in this repository. |

<!-- markdownlint-enable MD013 -->

The aborting bodies are deliberate. They make dependency modules loadable by
the local Move test runner and expose accidental crossings of the Nexus
boundary. A successful local call would otherwise suggest behavior that the
stub does not implement.

The common local abort reason is:

```text
Nexus functions require the published Testnet or Mainnet package
```

## Choose a package

Add each package whose modules the application imports directly. MVR resolves
the rest of the dependency graph transitively.

<!-- markdownlint-disable MD013 -->

| Move package | MVR name | Use it for |
| --- | --- | --- |
| `nexus_primitives` | `@talus/nexus-primitives` | Data values, authorization primitives, ownership helpers, events, proofs, and shared object references. |
| `nexus_interface` | `@talus/nexus-interface` | Agent, DAG, graph, payment, schema, result, and verifier types shared across Nexus. |
| `nexus_tool` | `@talus/nexus-tool` | Tool registration, invocation authorization, pricing, entitlements, cashiers, and Tool package migration. |
| `nexus_registry` | `@talus/nexus-registry` | Agent and Leader registries, network keys, registered key verification, and priority fees. |
| `nexus_workflow` | `@talus/nexus-workflow` | Supported workflow execution reads, validation, and invocation requests. |
| `nexus_scheduler` | `@talus/nexus-scheduler` | Task lifecycle, schedules, workflow execution, result submission, and settlement. |

<!-- markdownlint-enable MD013 -->

`nexus_kernel` is an internal support package and has no MVR name. Do not add
it directly.

## Add a dependency

Install the
[MVR resolver](https://github.com/MystenLabs/mvr/tree/main/crates/mvr-cli),
then add the required package to the consumer's `Move.toml`. For example:

```toml
[package]
name = "my_nexus_app"
edition = "2024"

[dependencies]
nexus_scheduler = { r.mvr = "@talus/nexus-scheduler" }

[addresses]
my_nexus_app = "0x0"
```

Build against Testnet while developing:

```sh
sui move build --build-env testnet
```

Use Mainnet only for a production build intended for Mainnet:

```sh
sui move build --build-env mainnet
```

`--build-env` selects the published package addresses and source record. It
does not make `sui move test` execute against that network.

## Testing strategy

Use three layers of evidence. Each layer answers a different question:

<!-- markdownlint-disable MD013 -->

| Check | What it proves | What it does not prove |
| --- | --- | --- |
| `sui move build --build-env testnet` | The consumer compiles against the Testnet interface and dependency graph. | That a transaction succeeds or that the selected shared objects are valid. |
| `sui move test --build-env testnet` | Local application logic works with the Nexus value shapes supplied by test extensions, and accidental stub calls abort. | Published Nexus state transitions, events, authorization, payment, scheduling, or shared object behavior. |
| Testnet integration transaction | The real published Nexus packages accept the transaction and produce the expected effects, events, and state. | Mainnet configuration unless it is verified separately. |

<!-- markdownlint-enable MD013 -->

Keep the boundary small: test application logic locally, and test calls that
cross into Nexus on Testnet.

## Local Move tests

### Why module extensions are needed

Consumer code cannot construct every Nexus value directly because many fields
and enum variants are intentionally private to their defining module. Calling
an existing constructor is also not a local substitute: its stub body aborts.

A test only module extension shares the scope of the Nexus module it extends.
It can construct and inspect private value shapes for a local test without
adding production helpers to Nexus or to the consumer application.

Extensions are additive:

- They can add test helper functions to a dependency module.
- They cannot replace an existing Nexus function.
- They do not reproduce validation, authorization, events, or state changes
  from the published package.
- A `#[test_only]` extension under `tests/` is excluded from production
  bytecode.

Module extensions currently require the alpha form of the Move 2024 edition.
Use it only when the consumer has tests that use extensions:

```toml
[package]
name = "my_nexus_app"
edition = "2024.alpha"
```

### 1. Keep application logic outside the Nexus call

This application function stores Nexus values but does not invoke Nexus:

```move
module my_nexus_app::application;

use nexus_primitives::data::NexusData;

public struct Observation has copy, drop {
    value: NexusData,
    accepted: bool,
}

public fun observe(value: NexusData, accepted: bool): Observation {
    Observation { value, accepted }
}

public fun is_accepted(self: &Observation): bool {
    self.accepted
}

public fun value(self: &Observation): &NexusData {
    &self.value
}
```

### 2. Add the smallest test extension you need

Place the extension in the consumer's `tests/` directory:

```move
#[test_only]
extend module nexus_primitives::data;

/// Creates one inline value for local application tests.
public fun inline_for_testing(bytes: vector<u8>): NexusData {
    NexusData::One {
        value: NexusValue::InlineData { bytes },
    }
}

/// Reads the inline byte length without calling a Nexus stub.
public fun inline_length_for_testing(self: &NexusData): u64 {
    match (self) {
        NexusData::One {
            value: NexusValue::InlineData { bytes },
        } => bytes.length(),
        _ => 0,
    }
}
```

Use `_for_testing` names so the source makes the helper's role obvious. Add
only constructors and observations required by the application test.

### 3. Test the application behavior

The helper is called through the module it extends:

```move
#[test_only]
module my_nexus_app::application_tests;

use my_nexus_app::application;
use nexus_primitives::data;
use std::unit_test::assert_eq;

#[test]
fun records_inline_data() {
    let value = data::inline_for_testing(b"hello");
    let observation = application::observe(value, true);

    assert!(observation.is_accepted());
    assert_eq!(observation.value().inline_length_for_testing(), 5);
}
```

### 4. Test the boundary explicitly

An expected failure test documents that an existing Nexus function is not
available in the local VM:

```move
/// Expected local error from every existing Nexus interface function.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

#[test, expected_failure(
    abort_code = ELocalExecutionUnavailable,
    location = nexus_primitives::data,
)]
fun published_constructor_is_not_a_local_mock() {
    nexus_primitives::data::inline_data_value(b"hello");
}
```

Run the local suite with the same build environment used for dependency
resolution:

```sh
sui move test --build-env testnet
```

See the complete executable
[local testing example](https://github.com/Talus-Network/nexus-move-packages/tree/main/examples/local_testing).

## Testnet integration tests

Anything that depends on published Nexus behavior must be exercised by a real
Testnet transaction. This includes:

- creating or mutating Nexus objects;
- calling Nexus constructors, validators, adapters, or entry functions;
- checking authorization and capability rules;
- emitting or consuming Nexus events;
- using shared protocol objects;
- executing, scheduling, charging, verifying, or settling work.

A Testnet integration test should:

1. Build the consumer with `--build-env testnet`.
1. Load the matching Nexus Testnet configuration and shared object IDs.
1. Construct and submit the transaction with the Nexus SDK, CLI, or a Sui PTB.
1. Require successful transaction effects.
1. Assert the expected events and read back the affected objects.
1. Use isolated owned test objects or deterministic fixtures so the test can be
   repeated safely.

The local Move test runner never submits a transaction. A Testnet build
environment resolves Testnet dependencies, but only a client submission tests
the published implementation.

Start with the
[onchain development guide](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
for network setup, package records, and package ID verification.

## Common failures

### A local test aborts with `ELocalExecutionUnavailable`

The test called published Nexus behavior. If the test only needs a value shape,
add a minimal test extension. If it needs Nexus behavior, move that assertion
to a Testnet integration test.

### An extension cannot access a field or variant

Extend the module that defines the type, keep the extension under `tests/`, add
`#[test_only]`, and set the consumer edition to `2024.alpha`.

### An MVR dependency does not resolve

Confirm that the MVR resolver is installed, the dependency uses the exact
`r.mvr` name, and the build command specifies `--build-env testnet` or
`--build-env mainnet`.

### Source verification reports a mismatch

That is expected. These files are interfaces, not the implementation source
used to build the published Nexus bytecode.

## Supported workflow surface

`nexus_workflow` intentionally exposes only the workflow declarations intended
for direct composition:

- `execution::DAGExecution` and its public read and validation helpers;
- `invocation_adapter::new_request` and `invocation_adapter::is_locked`.

Workflow mutations are exposed through `nexus_scheduler`, the authorized
runtime facade. Functions requiring `RuntimePermit`, internal storage and
version types, values used only during settlement, and internal event layouts
are omitted from the consumer interface.

## Documentation

- [Prepare for onchain development](https://docs.talus.network/guides/getting-started/prepare-onchain-development)
- [Nexus Move reference](https://docs.talus.network/reference/move)
- [Local testing example](https://github.com/Talus-Network/nexus-move-packages/tree/main/examples/local_testing)

## Source and publication safety

Every package includes a `Published.toml` that records its Testnet and Mainnet
deployment. The files support dependency resolution and compilation against
those deployments; they do not establish bytecode equivalence.

Do not publish these interface packages. Do not use them to upgrade Nexus.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
