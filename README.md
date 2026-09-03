# Nexus Move packages

Public Move interfaces and executable TAP examples for applications that use the Nexus protocol packages published on Sui.

> **Important:** This repository describes the public Nexus surface. It does not contain the private Nexus implementation. Use these packages as dependencies. Do not publish them or use them to upgrade Nexus.

The interfaces preserve public types and function signatures. The Nexus CLI can combine them with the exact Nexus bytecode published on Testnet or Mainnet, so TAP developers can run meaningful Move unit tests without Nexus source.

## Choose the TAP form

Nexus supports two useful application forms. Choose one deliberately.

<!-- markdownlint-disable MD013 -->

| Form | Where the Agent and DAG are defined | Best fit |
| --- | --- | --- |
| Standard CLI skill | The CLI creates an address owned Agent from `skill.tap.json` and `dag.json` | A skill whose lifecycle should be managed with standard Nexus commands |
| Embedded application | Move application state owns the Agent; Move code creates the DAG, binds the skill, schedules Tasks and handles Tool callbacks | A product whose onchain state and Agent lifecycle belong together |

<!-- markdownlint-enable MD013 -->

Create the standard form with:

```sh
nexus tap scaffold --name content_review
cd content_review
nexus tap test --path tap
nexus tap validate-skill --config skill.tap.json
```

Run the complete embedded application in this repository with:

```sh
git clone https://github.com/Talus-Network/nexus-move-packages.git
cd nexus-move-packages/examples/local_testing
nexus tap test
```

The embedded example does not use `skill.tap.json` or `dag.json`. Its application module creates and binds both structures onchain.

Read the [TAP development and testing guide](docs/tap_development.md) for the complete architecture, test fixture pattern, Testnet walkthrough and release checklist.

## What the embedded example proves

The example is a small application, not an isolated schema demonstration:

```text
ApplicationState owns Agent
        |
        +--> setup_agent creates DAG and registers the Agent skill
        |
        +--> schedule_review creates an Agent controlled Task and grant
        |
        +--> review_vertex::execute authenticates the released grant
                                      updates application state
                                      finalizes the Nexus Tool result
        |
        +--> close_review refunds the Task reserve and clears local state
```

The application module itself does not need a function named `execute`. Every module registered as an onchain Tool does. In the example, [`review_vertex::execute`](examples/local_testing/sources/review_vertex.move) is the function Nexus calls, while [`application.move`](examples/local_testing/sources/application.move) owns the Agent and application lifecycle.

## How local execution works

<!-- markdownlint-disable MD013 -->

| Command | What runs | What it establishes |
| --- | --- | --- |
| `sui move build --build-env testnet` | The compiler and public interfaces | Types, imports, addresses and package graph are valid |
| `sui move test --build-env testnet` | Local interface stub bodies | TAP code that does not call Nexus can run; direct Nexus calls intentionally abort |
| `nexus tap test --path examples/local_testing` | Exact published Testnet Nexus bytecode in a local Sui VM | TAP behavior and reachable Nexus behavior work with locally constructed state |
| `nexus tap test --path examples/local_testing --build-env mainnet` | Exact published Mainnet Nexus bytecode | The same unit suite is compatible with the selected Mainnet package graph |
| Testnet transaction | Published TAP and Nexus packages with live objects | Publication, object access, gas, routing, leaders and external services work together |

<!-- markdownlint-enable MD013 -->

`nexus tap test` resolves the package records, reads published modules from Sui, adds developer `#[test_only]` extension functions in memory, verifies the complete modules, then runs the standard Move unit test VM. Existing Nexus functions retain their published bytecode.

The command needs network access. It does not need a wallet, private key, gas or Nexus source.

## Declare direct dependencies

Declare every Nexus package imported directly by the TAP source or tests. MVR resolves the remaining graph.

<!-- markdownlint-disable MD013 -->

| Move package | MVR name | Main purpose |
| --- | --- | --- |
| `nexus_primitives` | `@talus/nexus-primitives` | Data, authorization, ownership helpers, proofs and tagged output |
| `nexus_interface` | `@talus/nexus-interface` | Agents, DAGs, graphs, payments, schemas and Tool results |
| `nexus_tool` | `@talus/nexus-tool` | Tool registration, pricing, entitlements and cashiers |
| `nexus_registry` | `@talus/nexus-registry` | Agent and Leader registries, networks and verification |
| `nexus_workflow` | `@talus/nexus-workflow` | Workflow execution, validation and invocation requests |
| `nexus_scheduler` | `@talus/nexus-scheduler` | Tasks, schedules, execution submission and settlement |
| `nexus_kernel` | Public repository only | Runtime authority types needed when Move code schedules a Task |

<!-- markdownlint-enable MD013 -->

An embedded application that schedules its own Tasks imports the kernel directly. The kernel currently has no MVR name, so pin its public interface from this repository:

<!-- markdownlint-disable MD013 -->

```toml
[package]
name = "my_embedded_tap"
version = "1.0.0"
edition = "2024.alpha"

[dependencies]
nexus_interface = { r.mvr = "@talus/nexus-interface" }
nexus_kernel = { git = "https://github.com/Talus-Network/nexus-move-packages", subdir = "packages/kernel", rev = "testnet/v1" }
nexus_primitives = { r.mvr = "@talus/nexus-primitives" }
nexus_registry = { r.mvr = "@talus/nexus-registry" }
nexus_scheduler = { r.mvr = "@talus/nexus-scheduler" }
nexus_tool = { r.mvr = "@talus/nexus-tool" }
```

<!-- markdownlint-enable MD013 -->

The example uses local paths instead, which makes repository changes and its tests use the same interface checkout. Pin a repository revision in an independent project so builds remain reproducible.

Use `edition = "2024.alpha"` when tests contain module extensions. A package without extensions can use the stable `2024` edition.

## Write focused fixtures

Start with public Nexus constructors. When a unit test needs private deployment state or a helper that was removed before publication, define the smallest developer owned extension under `tests/`:

```move
#[test_only]
extend module nexus_registry::era;

/// Constructs the storage witness needed by local registry state.
public fun v1_for_testing(): V1 {
    V1()
}
```

An extension has the scope needed to construct private layouts described by the interface. It may add functions only. It cannot replace an existing Nexus function. The CLI rejects function redefinition and any ABI or layout mismatch encountered while linking the test suite before running tests.

Use extensions to arrange and inspect state. Call published Nexus functions for behavior. The complete example follows that boundary for Tool registration, Agent attachment, skill binding, Task scheduling, authorization, Tool result finalization, cancellation and refund.

## Know the testing boundary

Unit test every deterministic TAP path and every Nexus path whose complete state can be constructed locally. Use Testnet once an assertion depends on a live shared object, leader selection, submitted transaction, gas, RPC, indexer or offchain Tool.

Passing local tests is strong evidence about application logic and published bytecode compatibility. It is not evidence that current Testnet objects or services are configured correctly. The guide shows how to preserve that distinction without leaving important TAP logic untested.

## Package guides

1. [`nexus_primitives`](packages/primitives)
2. [`nexus_interface`](packages/interface)
3. [`nexus_kernel`](packages/kernel)
4. [`nexus_tool`](packages/tool)
5. [`nexus_registry`](packages/registry)
6. [`nexus_workflow`](packages/workflow)
7. [`nexus_scheduler`](packages/scheduler)

Move API reference and Nexus setup documentation are available in the [Talus developer documentation](https://docs.talus.network/).

## Source and publication safety

Each package has a `Published.toml` file with Testnet and Mainnet deployment records. These records select published dependencies; they do not make the interface source equal to the private implementation source.

Do not publish an interface package. Do not use one to upgrade Nexus. Source verification against Nexus is expected to report a mismatch because the implementation source is intentionally absent.

Sui package bytecode is public chain data and is inherently inspectable. The test command downloads that bytecode but does not expose Nexus source.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
