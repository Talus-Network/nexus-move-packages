# Embedded TAP application example

This directory contains a complete small TAP application and its unit suite. It follows the same application form used by a larger embedded TAP:

1. Shared application state owns an embedded Nexus Agent.
2. The application creates a DAG and binds it as an Agent skill.
3. The application schedules an Agent controlled Task.
4. Nexus calls an onchain Tool module through `execute`.
5. The Tool authenticates the grant, mutates application state and finalizes a Nexus result.
6. The application closes the Task and receives its unused payment reserve.

The business rule is deliberately small: content with at least five bytes is accepted, shorter content is rejected. This keeps the Nexus lifecycle visible instead of hiding it behind application detail.

## Architecture

```text
                         Nexus protocol
                 +---------------------------+
                 | AgentRegistry             |
                 | ToolRegistry              |
                 | Scheduler and workflow    |
                 +-------------+-------------+
                               |
                               v
+----------------------+   scheduled grant   +-----------------------+
| ApplicationState     |<------------------->| review_vertex         |
|                      |                     |                       |
| embedded Agent       |                     | public fun execute    |
| DAG and skill IDs    |                     | input commitment      |
| pending Task ID      |                     | authorization check   |
| review counters      |                     | result finalization   |
+----------------------+                     +-----------------------+
```

[`application.move`](sources/application.move) owns the product state and Agent lifecycle. [`review_vertex.move`](sources/review_vertex.move) is the onchain Tool that Nexus invokes. The application module does not need its own `execute` function because it is not registered as the Tool.

## Read the example in this order

1. `ApplicationState` in [`application.move`](sources/application.move) shows how an Agent is embedded in application state.
2. `setup_agent` shows DAG creation, Tool binding, skill registration and DAG finalization.
3. `schedule_review` shows entry values, the authorization recipient, Agent funding and scheduling.
4. `review_vertex::execute` shows the ABI Nexus calls for a workflow authorized onchain Tool.
5. `review_for_tool` shows how application logic consumes the released grant.
6. `cancel_review` and `close_review` show Task cleanup and reserve refund.
7. [`application_tests.move`](tests/application_tests.move) shows how the same paths are tested without private Nexus source.

## The `execute` contract

The callback has this shape:

```move
public fun execute(
    authorization: ProvenValue<AgentVertexAuthorization>,
    requirements: UIDRequirements,
    result: OnchainToolResult,
    state: &mut ApplicationState,
    content: vector<u8>,
    ctx: &mut TxContext,
)
```

Nexus supplies the first three values. The Tool inputs follow in DAG port order. `TxContext` is last. For this Tool:

<!-- markdownlint-disable MD013 -->

| Position | DAG port | Move value | Source |
| --- | --- | --- | --- |
| 0 | `0` | `&mut ApplicationState` | The application state object configured by `schedule_review` |
| 1 | `1` | `vector<u8>` | The content configured by `schedule_review` |

<!-- markdownlint-enable MD013 -->

The `Output` enum is the output schema used during Tool registration. Its variant and field names must match the `TaggedOutput` returned to Nexus.

The callback checks the concrete input commitment before using the grant. It then consumes the grant as the application state recipient, satisfies the Tool witness requirement with the same state UID and calls the published `finalize_and_share` function.

## Run the suite

From this directory:

```sh
nexus tap test
```

From any other directory:

```sh
nexus tap test \
  --path path/to/nexus-move-packages/examples/local_testing
```

The default environment is Testnet. The command needs network access to read published package bytecode. It does not need a wallet, signer, gas or private Nexus source.

Useful focused commands:

```sh
nexus tap test --list
nexus tap test setup_binds
nexus tap test execute_accepts --threads 1
nexus tap test --build-env mainnet
```

Use `sui move build` as a fast compile check:

```sh
sui move build --build-env testnet --warnings-are-errors
```

Do not use `sui move test` for tests that call Nexus. It executes the public interface stub bodies, which intentionally abort. `nexus tap test` supplies the selected published bodies inside the local VM.

## What each test establishes

<!-- markdownlint-disable MD013 -->

| Test | Evidence |
| --- | --- |
| `setup_binds_an_embedded_agent_to_the_review_tool` | The production setup path attaches the embedded Agent, creates a final DAG and records a fixed Tool skill in the published Agent registry implementation. |
| `scheduling_and_closing_manage_the_complete_task_lifecycle` | Published scheduler code creates an Agent controlled Task with one grant, reserves Agent funds, advertises work, cancels it, closes it and refunds the reserve. |
| `execute_accepts_content_and_finalizes_the_nexus_result` | Content at the exact five byte boundary authenticates through the scheduled Task grant, updates state and produces a consumable published Nexus result with all required stamps. |
| `execute_rejects_authorization_for_another_application_state` | A real grant bound to one application state cannot authorize the same callback against another state. |
| `execute_rejects_short_content_and_finalizes_the_nexus_result` | The application rejection branch updates the correct counter and returns the declared output variant through published result finalization. |
| `execute_rejects_content_that_does_not_match_the_committed_input` | Different concrete input is stopped by the Tool callback before authorization is consumed or state is changed. |

<!-- markdownlint-enable MD013 -->

The callback tests do not create a free standing fake grant. They schedule a real Task, copy the vertex grant created by published Nexus code and bind its exact Agent, skill, DAG, vertex, Task, execution and input commitment into the worksheet used by `execute`.

The authorization isolation test keeps that real grant but supplies a second application state with a matching concrete input commitment. The application rejects it because the grant recipient is the original state UID.

## Why the test extensions exist

Sui removes Nexus `#[test_only]` helpers before package publication. Published bytecode therefore cannot contain the deployment constructors used by internal tests. Small module extensions recreate only the missing state boundary:

<!-- markdownlint-disable MD013 -->

| Extension | Fixture responsibility |
| --- | --- |
| [`agent_registry_extension.move`](tests/agent_registry_extension.move) | Constructs an empty local Agent registry. |
| [`tool_registry_extension.move`](tests/tool_registry_extension.move) | Constructs an empty local Tool registry and test collateral, then calls the published Tool registration function. |
| [`runtime_authority_extension.move`](tests/runtime_authority_extension.move) | Constructs the authority state read by local scheduling. |
| [`dag_extension.move`](tests/dag_extension.move) | Marks a locally held DAG final so the test can inspect and later destroy it. |
| Era extensions | Construct private storage witness values needed by the registry fixtures. |

<!-- markdownlint-enable MD013 -->

The extensions do not implement Agent attachment, skill registration, scheduling, authorization checks, result finalization, cancellation or refund. Those behaviors come from the exact selected Nexus bytecode.

## The deliberate unit boundary

The suite tests the complete application controlled flow on both sides of the workflow runtime boundary. It does not simulate a live Leader admitting and walking the Task. The callback fixture represents the values that the workflow releases after that admission and proves they are consistent with the actual scheduled Task grant.

This is the useful unit boundary:

```text
locally proven                      Testnet integration
-------------------------------     -------------------------------
application setup                   package publication
DAG and skill binding               current shared object versions
Task and grant creation             Leader selection and admission
payment reservation and refund      actual workflow walking
callback authorization              gas and transaction submission
input commitment                    RPC, indexer and external services
application state changes
Nexus result finalization
```

Trying to replace current network objects and Leader behavior with local fixtures would make the test reproduce deployment state rather than test the TAP. Run that last column on Testnet.

## Adapt the application

Before using this example for a real TAP:

1. Replace `example.taluslabs.content_review@1` with a unique FQN that you control. Use the same value in Tool registration.
2. Replace the content rule and `Output` variants with the real application contract.
3. Add one DAG vertex module per onchain Tool callback.
4. Add every Tool input as a positional DAG entry port and commit the exact concrete value in `execute`.
5. Bind authorization only for vertices that mutate protected application state.
6. Store every Task ID whose lifecycle the application must control, then clear it only after successful close.
7. Add focused fixture functions only when public constructors cannot arrange the required unit state.
8. Add a Testnet check for every assumption that depends on live Nexus state.

The full [TAP development and testing guide](../../docs/tap_development.md) continues from this example through Testnet Tool registration, application setup, funding, scheduling, inspection and cleanup.
