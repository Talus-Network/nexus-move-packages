# Complete TAP unit test example

This project shows a complete TAP owned flow running beside the exact Nexus
bytecode published on Sui Testnet. It uses the same project layout created by
`nexus tap scaffold`.

The TAP defines a content review schema, converts raw bytes to canonical Nexus
data, accepts or rejects the input, creates canonical tagged output, updates
TAP owned state, and checks the complete result contract. The suite also shows
how a developer can recreate a missing Nexus test fixture with a test module
extension.

## What the suite proves

<!-- markdownlint-disable MD013 -->

| Test | Evidence |
| --- | --- |
| `complete_flow_accepts_and_rejects_canonical_inputs` | The complete TAP owned success and rejection paths work with published Nexus constructors, schema checks, views, and output builders. |
| `extension_fixture_exercises_invalid_input_path` | A developer extension can create a private Nexus value shape and drive a TAP error path. |
| `state_persists_across_transaction_boundaries` | `sui::test_scenario` preserves TAP shared object state across transaction boundaries. |
| `extension_calls_published_nexus_functions` | A function added by an extension can call an existing published Nexus function. |
| `extensions_compose_across_nexus_packages` | Test helpers added to separate Nexus packages can call each other. |
| `published_constructor_rejects_an_empty_collection` | Expected failure assertions observe the published Nexus abort location. |

<!-- markdownlint-enable MD013 -->

## Files

| File | Purpose |
| --- | --- |
| [`skill.tap.json`](skill.tap.json) | Defines the skill requirements and points to the DAG. |
| [`dag.json`](dag.json) | Defines one review vertex and its input port. |
| [`tap/Move.toml`](tap/Move.toml) | Selects the interface packages used by the TAP. |
| [`tap/sources/application.move`](tap/sources/application.move) | Implements the complete TAP owned review flow. |
| [`tap/tests/application_tests.move`](tap/tests/application_tests.move) | Arranges inputs, runs the flow, asserts output and state, and cleans up resources. |
| [`tap/tests/data_extension.move`](tap/tests/data_extension.move) | Adds constructors and views inside `nexus_primitives::data` for tests only. |
| [`tap/tests/tagged_output_extension.move`](tap/tests/tagged_output_extension.move) | Adds one focused output assertion helper. |
| [`tap/tests/task_extension.move`](tap/tests/task_extension.move) | Demonstrates extensions that compose across Nexus packages. |

The example uses local dependencies so it always checks the interfaces in the
current repository checkout. A developer package should use MVR dependencies:

```toml
[dependencies]
nexus_interface = { r.mvr = "@talus/nexus-interface" }
nexus_primitives = { r.mvr = "@talus/nexus-primitives" }
nexus_scheduler = { r.mvr = "@talus/nexus-scheduler" }
```

## Run the suite

From any directory:

```sh
nexus tap test \
  --path path/to/nexus-move-packages/examples/local_testing/tap
nexus tap validate-skill \
  --config path/to/nexus-move-packages/examples/local_testing/skill.tap.json
```

The command needs network access to resolve MVR records and fetch published
Nexus bytecode. It does not need a wallet, private key, gas, or Nexus source.

Useful focused commands:

```sh
nexus tap test --path path/to/package --list
nexus tap test --path path/to/package complete_flow
nexus tap test --path path/to/package --build-env mainnet
```

`dag.json` uses the illustrative Tool name
`xyz.example.content_review@1`. Replace it with a Tool registered in the target
environment before publication.

Do not run this example with `sui move test` when the assertion requires Nexus
behavior. That command sees only the interface stub bodies. `nexus tap test`
replaces those bodies with the selected published bytecode inside the local
test VM.

Read the [complete TAP development and testing guide](../../docs/tap_development.md)
before adapting the fixture pattern to protocol objects or shared state.
