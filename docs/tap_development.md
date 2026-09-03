# Develop and test a TAP application

This guide shows how to build an embedded Talus Agent Package, test its full application controlled lifecycle locally and then verify the network boundary on Testnet. Every command maps to the executable application in [`examples/local_testing`](../examples/local_testing).

## The result

By the end, the application has:

1. Shared Move state that owns an embedded Nexus Agent.
2. A DAG constructed by the application and fixed to one onchain Tool.
3. An Agent skill bound to that DAG.
4. A public function that funds the Agent and another that schedules work.
5. A Tool module with the `execute` ABI called by Nexus.
6. Workflow authorization bound to application state.
7. Unit tests for setup, scheduling, payment, authorization, callback output,
   state changes, input tampering and Task cleanup.
8. A Testnet path for publication, Tool registration, live scheduling and
   result inspection.

## First choose the application form

A TAP is an application or skill that runs work through Nexus. There are two
valid forms, and their deployment flow is different.

<!-- markdownlint-disable MD013 -->

| Question | Standard CLI skill | Embedded application |
| --- | --- | --- |
| Who owns the Agent? | A user address | Application state |
| Where is the DAG declared? | `dag.json` | Move code |
| Where are skill requirements declared? | `skill.tap.json` | Move code |
| Who schedules the Task? | Standard Nexus CLI commands | An application Move function |
| Typical starting point | `nexus tap scaffold` | The complete example in this repository |

<!-- markdownlint-enable MD013 -->

Use the standard form when the CLI should own the entire Agent lifecycle. Use
the embedded form when a product object must control authorization, funds,
state and scheduling as one application.

This guide focuses on the embedded form. It intentionally has no `dag.json` or
`skill.tap.json`; adding those files would create a second source of truth.

## Prerequisites

For local development, install a Sui CLI compatible with the toolchain recorded
in each Nexus `Published.toml` file and a Nexus CLI release that contains
`nexus tap test`. Confirm both commands before writing the TAP:

```sh
sui --version
nexus --version
nexus tap test --help
```

Local unit tests need network access to read public package records and
bytecode. They do not need a wallet, private key, SUI or US collateral.

The Testnet walkthrough additionally needs a funded Sui address, the same
signer configured in the Nexus CLI and an owned `Coin<US>` for Tool collateral.
Those assets are used only after local acceptance passes.

Commands before the first explicit `cd` run from the repository root.

## Understand the module boundary

An embedded TAP normally contains at least two modules:

```text
application.move
    owns ApplicationState and Agent
    creates and binds the DAG
    schedules and closes Tasks
    implements protected business behavior

review_vertex.move
    declares Output
    exposes public fun execute
    verifies the exact Tool inputs
    consumes workflow authorization
    calls the application behavior
    finalizes the Nexus Tool result
```

The application module does not need a universal `execute` function. Nexus
calls `execute` on each module registered as an onchain Tool. A TAP with three
onchain Tool vertices can have three Tool modules and three callback functions,
all operating on the same application state.

The complete local and network flow is:

```text
publish package
      |
      v
init shares ApplicationState with embedded Agent
      |
      v
register review_vertex as a workflow authorized Tool
      |
      v
application::setup_agent creates DAG and registers skill
      |
      v
application::fund_agent deposits SUI
      |
      v
application::schedule_review creates Task and grant
      |
      v
Nexus admits and walks the Task
      |
      v
review_vertex::execute authenticates and finalizes output
      |
      v
application::close_review returns unused reserve
```

## Declare dependencies

Move requires every directly imported package to be declared. An embedded
application that schedules a Task imports the public runtime authority type
from `nexus_kernel` in addition to the MVR packages.

<!-- markdownlint-disable MD013 -->

```toml
[package]
name = "content_review"
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

`nexus_kernel` currently has no public MVR name. Pin the repository revision
that belongs to the Nexus release you consume. The complete example uses local
paths because it lives inside the interface repository.

Use `edition = "2024.alpha"` when unit tests use `extend module`. The extension
syntax is gated by that edition. Production source can still use normal Move
2024 syntax.

Build for the same environment that you plan to use:

```sh
sui move build \
  --path examples/local_testing \
  --build-env testnet \
  --warnings-are-errors
```

The build environment selects package records and addresses. It does not make
the compiler execute network code.

## Define application state

The example stores the Agent inside the shared product object:

```move
public struct ApplicationState has key, store {
    id: UID,
    dag_id: ID,
    skill_id: option::Option<u64>,
    agent: Agent,
    pending_task_id: option::Option<ID>,
    accepted_count: u64,
    rejected_count: u64,
}
```

This structure encodes the important invariants:

1. The application has one Agent identity.
2. Setup records one immutable DAG and one registered skill.
3. Only one review Task may be pending.
4. The same state UID is the Tool witness and authorization recipient.
5. The Tool callback is the only package function that changes review counts.

`init` creates and shares this state when the TAP package is published. The
embedded Agent becomes registered later because Tool registration must happen
first.

## Create the Agent, DAG and skill

`application::setup_agent` performs one atomic setup path:

1. Attach the embedded Agent to the live `AgentRegistry`.
2. Create a DAG with one vertex named `review`.
3. Bind that vertex to `example.taluslabs.content_review@1`.
4. Declare ports `0` and `1` as DAG entry ports.
5. Register an Agent funded, schedule once skill with a fixed Tool.
6. Record the DAG and skill identities in application state.
7. Finalize the DAG so runtime behavior cannot change after registration.

The FQN is part of the application contract. Replace the example value with a
unique FQN before publishing and use that exact value during Tool registration.

Keeping DAG construction in Move has one major benefit: the application code,
skill binding and state transition are reviewed and tested together. It also
means `nexus tap validate-skill` is not applicable to this form because there
is no JSON skill configuration to validate.

## Schedule application work

`application::schedule_review` creates the runtime input and schedules a Task
from the embedded Agent vault.

The execution config contains:

<!-- markdownlint-disable MD013 -->

| Field | Example value | Why it matters |
| --- | --- | --- |
| Agent ID | Embedded Agent object ID | Selects the registered skill owner |
| Network ID | Current Nexus network | Selects the execution network |
| Entry group | Default group | Selects the DAG entry set |
| Port `0` | `ApplicationState` object value | Gives `execute` mutable product state |
| Port `1` | One data value per content byte | Gives `execute` the review content |
| Skill ID | ID saved during setup | Selects the registered DAG and policies |
| Authorization binding | `review` to application state ID | Makes the state UID the only grant recipient |

<!-- markdownlint-enable MD013 -->

The production function calls published Nexus code to create the Agent Task,
reserve funds, advertise the occurrence and share the Task. It returns an owned
`TaskPointer` so the caller can discover the shared Task.

The example uses a 0.7 SUI occurrence reserve and an Agent policy maximum of
1.5 SUI. Treat those as example Testnet values. Choose real budgets from
measured execution cost and the Tool invocation policy.

## Implement the Tool callback

The registered Tool module exposes:

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

The argument groups have different owners:

<!-- markdownlint-disable MD013 -->

| Arguments | Supplied by | Responsibility |
| --- | --- | --- |
| `authorization`, `requirements`, `result` | Nexus workflow | Prove this exact execution may invoke the Tool and track required object stamps |
| `state`, `content` | DAG input ports in position order | Carry the concrete application input |
| `ctx` | Sui transaction | Create and share the final result |

<!-- markdownlint-enable MD013 -->

The callback performs four checks and effects in order:

1. Recompute the canonical input commitment from `state` and `content`.
2. Require it to equal the commitment carried by the Nexus result.
3. Consume the Agent grant as the application state recipient and update state.
4. Satisfy the state witness and let Nexus finalize and share the result.

Do not skip the first check. Authorization for one committed input must not be
usable with a different concrete value.

The public `Output` enum declares the Tool output schema:

```move
public enum Output {
    Accepted { length: u64 },
    Rejected { minimum_length: u64 },
}
```

The callback returns `TaggedOutput` variants named `accepted` and `rejected`
with matching fields. The Nexus CLI reads both `execute` and `Output` from the
published module when registering the Tool.

## Run local unit tests with published bytecode

Run the complete suite:

```sh
cd examples/local_testing
nexus tap test
```

The command does the following in memory:

```text
Move.toml and package records
            |
            v
compile TAP source, tests and public Nexus interfaces
            |
            +--> identify functions in test module extensions
            |
Sui RPC ----+--> download resolved published Nexus modules
            |
            v
append only new developer test functions
            |
            v
verify every linked module and run the Sui Move unit VM
```

Existing Nexus functions are never replaced. For every interface item linked
into the test suite, the CLI checks module identity, function signatures, type
abilities, struct layouts and enum layouts. It then runs the bytecode verifier
on every complete module. An extension targeting a wrong release or redefining
a published function fails before any test runs.

No wallet, signer or gas is needed. Network access is needed to resolve package
records and read public chain bytecode.

Useful development commands:

```sh
nexus tap test --list
nexus tap test setup_binds
nexus tap test execute_accepts --threads 1
nexus tap test --build-env mainnet
```

Use a filter to shorten a feedback loop, then run the unfiltered suite before
commit. Use `--threads 1` when failure ordering or event output matters.

### Why direct `sui move test` is different

The source packages in this repository contain interface bodies that abort
when called locally. Therefore:

```sh
sui move test --build-env testnet
```

is suitable only for TAP tests that never call Nexus. It is not a substitute
for `nexus tap test`.

## Construct test state without Nexus source

Published packages do not contain Nexus `#[test_only]` functions because Sui
removes them before publication. Downloading bytecode cannot recover code that
was never published.

Use this order when arranging a unit test:

1. Call a public constructor when one exists.
2. Add a small module extension when a private field or variant blocks fixture
   construction.
3. Recreate only the state outcome of a removed setup helper.
4. Call the exact published Nexus function for every behavior under test.
5. Add a focused view or cleanup helper only when the public interface has no
   equivalent.

For example:

```move
#[test_only]
extend module nexus_registry::era;

/// Constructs the Registry storage witness used by local deployment state.
public fun v1_for_testing(): V1 {
    V1()
}
```

### Fixture rules

1. Put extensions under the TAP `tests/` directory.
2. Mark every extension `#[test_only]`.
3. Keep one extension for each target Nexus module.
4. Give helper names a `_for_testing` suffix.
5. Construct the smallest coherent state that reaches the behavior.
6. Use extensions for state, observation and cleanup, not protocol behavior.
7. Exercise both accepted and rejected inputs where the boundary matters.
8. Never redefine an existing function.

The example extensions create empty Registry roots, version witnesses, a local
runtime authority and a mutable final DAG fixture. Tool registration, Agent
attachment, skill registration, scheduling, authorization, finalization,
cancellation and refund all run from published Nexus bytecode.

## Test the application lifecycle

The example suite uses one deliberate sequence.

### 1. Setup

The test constructs empty local Registry state, calls published Tool
registration, runs the production application setup and checks:

1. The embedded Agent was attached.
2. The saved DAG ID matches the created DAG.
3. The DAG is final.
4. The skill uses schedule once policy.
5. The skill is fixed to the intended Tool registry and FQN.

### 2. Schedule and payment

The test funds the embedded Agent and calls the production schedule path. It
checks:

1. The Task controller is the embedded Agent.
2. The pointer and application state name the same Task.
3. Exactly one vertex authorization grant exists.
4. An occurrence is advertised.
5. The expected reserve left the Agent vault.
6. Cancel and close finalize the Task, clear application state and refund the
   unused reserve.

### 3. Callback and result

The callback tests use the grant produced by that actual scheduled Task. They
do not invent an unrelated authorization value.

The fixture copies the Task grant, reads its Agent, skill, interface, DAG,
vertex and Task identities, creates the execution worksheet and commits the
concrete input. It then calls the production `review_vertex::execute` function.

The assertions consume the shared `OnchainToolResult` through published Nexus
code and verify:

1. Execution, Leader, Tool witness and result stamps are all present.
2. The output tag and payload match the public `Output` schema.
3. The output digest is present.
4. The intended sender receives the consumed output.
5. Application counters changed exactly once.

### 4. Authorization isolation

The authorization negative test schedules a real Task for one application
state, then calls the callback with a second state and a commitment that exactly
matches that second state. The application rejects the call because the grant
recipient remains bound to the original state UID. This separates recipient
authorization from input integrity and proves both checks matter.

### 5. Tampering

The negative test commits one content value and calls `execute` with another.
It expects the exact Tool module error. This proves the callback does not treat
the grant alone as permission for arbitrary input.

## Understand the deliberate runtime seam

The local suite proves the full flow controlled by the TAP on both sides of the
workflow runtime. It does not build a fake Leader network to admit and walk the
Task.

<!-- markdownlint-disable MD013 -->

| Proven locally | Proved on Testnet |
| --- | --- |
| Application initialization and invariants | Package publication and dependency routing |
| Tool schema compatible callback code | Live Tool registration and current shared versions |
| Embedded Agent and skill binding | Leader selection and work admission |
| Task creation and authorization grant | Actual workflow walk and settlement |
| Payment reservation, cancel, close and refund | Gas selection, budget and congestion behavior |
| Exact callback authorization and input commitment | RPC, indexer and event delivery |
| Application state changes and final Nexus result | Offchain Tool and service availability |

<!-- markdownlint-enable MD013 -->

This is not a mock behavior compromise. The local column executes selected
published Nexus functions. The Testnet column depends on current external
state and belongs in an integration check.

## Add tests for a real TAP

For each protected application action, cover the cases that can change value,
authority or resource ownership:

<!-- markdownlint-disable MD013 -->

| Case | Minimum assertion |
| --- | --- |
| Valid input | Output payload, all application state changes and result stamps |
| Boundary input | Values immediately below, at and above each limit |
| Different concrete input | Exact input commitment abort |
| Wrong grant recipient | Authorization abort before state mutation |
| Wrong Task or DAG | Application invariant abort |
| Repeated setup | Explicit duplicate setup abort |
| Concurrent pending action | Explicit pending Task abort or documented concurrency behavior |
| Cancel and close | Task final state, local reference cleanup and payment refund |
| Resource exit | Every owned resource consumed, transferred or deleted |

<!-- markdownlint-enable MD013 -->

Use `tx_context::dummy()` for a single transaction unit. Use
`sui::test_scenario` when shared objects, sender changes or transaction
boundaries are part of the assertion.

Prefer exact errors:

```move
#[test, expected_failure(
    abort_code = review_vertex::EInputCommitmentMismatch,
    location = content_review::review_vertex,
)]
fun changed_input_is_rejected() {
    // Arrange one commitment and call execute with different input.
}
```

When an error constant is private, assert the abort status and module location.
That proves which module rejected the call, but not which private error in that
module occurred.

## Run the Testnet integration

Local success is the gate to Testnet, not a replacement for it. The following
steps use placeholders beginning with `0x`. Replace every placeholder with the
value from your environment.

Start from the application package:

```sh
cd examples/local_testing
```

### 1. Prepare both clients

Point the Sui CLI at Testnet and select the funded address that will publish
the package:

```sh
sui client switch --env testnet
sui client active-address
sui client balance
```

Configure the Nexus CLI with the Testnet RPC URL and signer by following the
[Nexus CLI setup guide]. The canonical Testnet RPC lets the CLI load the
current Nexus object map automatically. Verify it before any write:

```sh
nexus conf get --json
```

Record these values from the `nexus` object in the output:

```text
agent_registry.object_id
tool_registry.object_id
runtime_authority.object_id
network_id
us_token.package_id
```

Tool registration locks US collateral. Confirm that the signer owns a
`Coin<US>` and record one coin ID:

```sh
sui client balance \
  --coin-type 0xUS_PACKAGE::us::US \
  --with-coins \
  --json
```

Use that ID as `0xUS_COIN`. You may instead omit `--collateral-coin` during
registration and let the Nexus CLI select the first owned `Coin<US>`.

The Nexus CLI signer that registers the Tool and the Sui CLI signer that owns
the returned capabilities should be the address you intend to operate.

### 2. Repeat local acceptance

```sh
sui move build --build-env testnet --warnings-are-errors
nexus tap test --threads 1
```

Before publication, replace the example Tool FQN in `application.move` with a
unique FQN that you control. Rebuild and rerun the suite after the change.

### 3. Publish the TAP package

```sh
sui client publish . \
  --build-env testnet \
  --skip-dependency-verification \
  --gas-budget 300000000 \
  --json
```

`--skip-dependency-verification` is required because this repository provides
public interface source rather than the private Nexus implementation source.
It does not skip Sui bytecode verification for the TAP package.

Record two created identities from `objectChanges`:

1. The published TAP package ID.
2. The shared `application::ApplicationState` object ID created by `init`.

Inspect the state before continuing:

```sh
sui client object 0xAPPLICATION_STATE --json
```

### 4. Register the onchain Tool

The application state ID is also the Tool witness ID. Register the published
`review_vertex` module:

```sh
nexus tool register onchain \
  --package 0xTAP_PACKAGE \
  --module review_vertex \
  --tool-fqn your.publisher.content_review@1 \
  --description "Reviews content through the embedded TAP application" \
  --tool-witness-id 0xAPPLICATION_STATE \
  --collateral-coin 0xUS_COIN \
  --json
```

The CLI reads `execute` and `Output` from the published module, generates the
schema and detects the workflow authorization argument automatically. It saves
the returned Tool owner capabilities unless `--no-save` is used.

Confirm the live record:

```sh
nexus tool inspect \
  --tool-fqn your.publisher.content_review@1 \
  --json
```

Stop if the FQN, package, module, witness, input schema, output schema or
authorization mode differs from the application source.

### 5. Attach the Agent and create the DAG

Call the application setup function once:

```sh
sui client ptb \
  --assign tap @0xTAP_PACKAGE \
  --assign agent_registry @0xAGENT_REGISTRY \
  --assign application_state @0xAPPLICATION_STATE \
  --assign tool_registry @0xTOOL_REGISTRY \
  --move-call "tap::application::setup_agent" \
    agent_registry application_state tool_registry \
  --gas-budget 300000000 \
  --json
```

Record the `ApplicationConfiguredEvent` values:

```text
state_id
agent_id
dag_id
skill_id
```

Also inspect the updated application state. The stored DAG and skill values
must match the event.

### 6. Fund the Agent and schedule a review

The following PTB deposits 2.1 SUI into the embedded Agent, converts the
network address to a Move `ID`, schedules the content `hello Nexus` and sends
the owned Task pointer to the operator:

```sh
sui client ptb \
  --assign tap @0xTAP_PACKAGE \
  --assign runtime_authority @0xRUNTIME_AUTHORITY \
  --assign agent_registry @0xAGENT_REGISTRY \
  --assign dag @0xDAG \
  --assign tool_registry @0xTOOL_REGISTRY \
  --assign application_state @0xAPPLICATION_STATE \
  --split-coins gas "[2100000000]" \
  --assign funding \
  --move-call "tap::application::fund_agent" application_state funding.0 \
  --move-call "0x2::object::id_from_address" @0xNETWORK \
  --assign network \
  --move-call "tap::application::schedule_review" \
    runtime_authority agent_registry dag tool_registry application_state \
    "vector[104,101,108,108,111,32,78,101,120,117,115]" network @0x6 \
  --assign scheduled \
  --transfer-objects "[scheduled.1]" @0xOPERATOR \
  --gas-budget 300000000 \
  --json
```

The decimal byte vector is UTF8 for `hello Nexus`. For arbitrary text, encode
the exact bytes used by the application client. Do not change the port order:
the state object is port `0` and content is port `1`.

Record the created shared `nexus_scheduler::task::Task` ID from
`objectChanges`.

### 7. Observe execution

Inspect the Task and its occurrences:

```sh
nexus task inspect --task-id 0xTASK --json
nexus task occurrence list --task-id 0xTASK --json
```

Inspect the application state after the workflow completes:

```sh
sui client object 0xAPPLICATION_STATE --json
```

A strong integration assertion checks:

1. The scheduling transaction succeeded.
2. The Task reached the expected terminal state.
3. The execution used the intended DAG and Tool FQN.
4. The Nexus Tool result has the expected variant and payload.
5. Exactly one application counter changed.
6. Relevant events name the expected Task, Agent, DAG and execution.
7. Gas and Tool charges remain inside the intended budget.

### 8. Close or cancel the Task

After a terminal execution, refund the unused reserve and clear the pending ID:

```sh
sui client ptb \
  --assign tap @0xTAP_PACKAGE \
  --assign application_state @0xAPPLICATION_STATE \
  --assign task @0xTASK \
  --move-call "tap::application::close_review" application_state task \
  --gas-budget 100000000 \
  --json
```

If the occurrence has not entered execution and should not run, cancel it
first:

```sh
sui client ptb \
  --assign tap @0xTAP_PACKAGE \
  --assign application_state @0xAPPLICATION_STATE \
  --assign task @0xTASK \
  --move-call "tap::application::cancel_review" application_state task \
  --move-call "tap::application::close_review" application_state task \
  --gas-budget 100000000 \
  --json
```

If work is already in flight, cancellation stops future work but close must
wait for the current execution to settle.

## What unit tests can and cannot prove

With focused extensions, local tests can prove:

1. TAP branching, errors, state changes and object cleanup.
2. Calls to public Nexus functions using the selected published bodies.
3. Agent, DAG, skill, Task and authorization relationships built from complete
   local state.
4. Workflow callback authorization and exact input commitments.
5. Result construction and consumption across transaction boundaries.
6. Expected abort codes and module locations.
7. Testnet or Mainnet bytecode compatibility for the resolved package graph.

They cannot alone prove:

1. Current contents or versions of live shared objects.
2. Real package publication and transaction dependency routing.
3. Leader selection, consensus, congestion or runtime service availability.
4. Gas coin selection or actual transaction cost.
5. Offchain Tool HTTP behavior, signatures or timeouts.
6. RPC, indexer or event subscription behavior.
7. Any state that the local suite did not construct.

The rule is precise: unit test all deterministic application behavior and all
reachable published Nexus behavior locally. Move to Testnet at the first
assertion that depends on current external state.

## Troubleshooting

### `nexus tap test` is not a recognized command

Install a Nexus CLI release that includes TAP unit testing. Confirm the active
binary with `nexus --version` and `nexus tap test --help` before continuing.

### Nexus calls abort with `ELocalExecutionUnavailable`

The suite was run with `sui move test`, so it reached interface stub bodies.
Run `nexus tap test` from the package directory.

### An extension is rejected by the parser

Use `edition = "2024.alpha"`, place the file in the root TAP `tests/`
directory and add `#[test_only]` above `extend module`.

### Two files extend the same module

Only one active extension is allowed for a module and mode. Combine the helper
functions in one file.

### A private field or variant is missing

Confirm that the TAP directly depends on the package containing that type and
that the checked out interface matches the selected release. An extension can
use only layouts present in the public interface.

### The linker reports an ABI or layout mismatch

The interface and selected published package do not describe the same module.
Use the interface revision and build environment belonging to that deployment.
Do not bypass the check.

### The command cannot read published bytecode

Confirm network access and the value passed to `--build-env`. Unit testing is a
read only network operation, but it still needs Testnet or Mainnet RPC access.

### `nexus_kernel` is an unbound address

The application imports `RuntimeAuthority` directly but does not declare the
kernel dependency. Add the pinned Git dependency shown earlier, or a local
path when developing inside this repository.

### Tool registration finds the wrong callback shape

Confirm that the published module exposes one public `execute` with Nexus
injected arguments first, business inputs next and `TxContext` last. Confirm
that the module also declares a public `Output` enum.

### Setup says the Tool is not registered

The FQN in `application::review_vertex_fqn` differs from the FQN registered in
the selected Tool registry, or registration used another network. Inspect the
Tool record and current Nexus configuration.

### Local tests pass but Testnet fails

Compare sender, object IDs, shared object mutability, package environment, Tool
FQN, Tool witness, authorization binding, port order, network ID, Agent funds,
gas budget and current Nexus object map. These are Testnet inputs, not local
application logic.

### A Nexus failure has no source line

Published packages expose bytecode, not private Nexus source maps. TAP frames
still show local source. Use the Nexus module and bytecode location, reduce the
input to the smallest failing call and verify every live object assumption on
Testnet.

## Release checklist

Before Testnet:

1. The Tool FQN is unique and identical in code and deployment input.
2. `sui move build --build-env testnet --warnings-are-errors` passes.
3. Unfiltered `nexus tap test` passes.
4. Every protected state change has success, rejection and wrong authority
   coverage where material.
5. Every Tool callback checks its exact concrete input commitment.
6. Fixtures arrange state but do not copy Nexus behavior.
7. Task cancel, terminal close and reserve ownership are tested.
8. No test module or fixture is included in production bytecode.

Before Mainnet:

1. The entire isolated Testnet flow has passed.
2. Testnet assertions include final application and Task state, not only a
   successful transaction digest.
3. `nexus tap test --build-env mainnet` passes.
4. `sui move build --build-env mainnet --warnings-are-errors` passes.
5. Mainnet Tool records, schemas, witnesses and Nexus object configuration are
   verified independently.
6. Budgets come from measured Testnet cost with an explicit safety margin.

## Source and publication safety

Public interfaces and downloaded bytecode are dependencies, not TAP modules.
Do not publish the interface packages or use them to upgrade Nexus.

Sui bytecode is public chain data. `nexus tap test` reads it, overlays only
developer test functions in memory and marks the result as not publishable. It
does not recover or expose private Nexus source.

[Nexus CLI setup guide]: https://docs.talus.network/talus-documentation/developer-docs/index-1/cli
