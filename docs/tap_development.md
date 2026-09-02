# TAP development and testing

This guide takes a TAP from an empty project to local unit tests and then to a
Testnet integration run. It also explains exactly what each check proves, so a
passing test is never mistaken for stronger evidence than it provides.

## What a TAP contains

A Talus Agent Package, or TAP, defines application logic and an agent skill
that uses Nexus. In the Nexus CLI project layout, one TAP project contains:

<!-- markdownlint-disable MD013 -->

| Path | Role |
| --- | --- |
| `tap/Move.toml` | Move package manifest and Nexus dependencies |
| `tap/sources/` | TAP owned Move modules |
| `tap/tests/` | Unit tests and test module extensions |
| `dag.json` | Nexus DAG and Tool bindings |
| `skill.tap.json` | Skill requirements, payment policy, schedule policy, and DAG path |

<!-- markdownlint-enable MD013 -->

The Move package is where a TAP author owns behavior and state. The DAG tells
Nexus which Tools form the workflow. The skill configuration binds that DAG to
the rules used when the skill is registered for an agent.

## Fast path

Create a project:

```sh
nexus tap scaffold --name content-review
cd content-review
```

Run its Move unit tests with the Nexus Testnet implementation:

```sh
nexus tap test --path tap
```

Validate the local package, DAG, and skill configuration:

```sh
nexus tap validate-skill --config skill.tap.json
```

These commands do not publish anything. `nexus tap test` needs network access
to resolve package records and download Nexus bytecode, but it does not need a
wallet, private key, or gas.

Before publication, replace the example Tool name in `dag.json` with a Tool
that is registered on the selected network. Check it with:

```sh
nexus tool inspect --tool-fqn example.publisher.tool@1
```

## Choose direct Nexus dependencies

Declare every Nexus package imported by TAP source or test source. MVR resolves
the remaining graph.

```toml
[package]
name = "content_review"
version = "1.0.0"
edition = "2024.alpha"

[dependencies]
nexus_interface = { r.mvr = "@talus/nexus-interface" }
nexus_primitives = { r.mvr = "@talus/nexus-primitives" }
nexus_scheduler = { r.mvr = "@talus/nexus-scheduler" }
```

Use `edition = "2024.alpha"` when a test uses `extend module`. Module
extensions are currently gated by that edition. A package without extensions
can use `edition = "2024"`.

The packages in this repository are source interfaces. They expose type
layouts and supported function signatures so a TAP can compile. They do not
contain the private Nexus implementation.

## The local test model

The four common commands answer different questions:

<!-- markdownlint-disable MD013 -->

| Command | Implementation that runs | Main question answered |
| --- | --- | --- |
| `sui move build --build-env testnet` | No function execution | Does the TAP compile against Testnet addresses and interfaces? |
| `sui move test --build-env testnet` | Local interface stub bodies | Does code that never calls Nexus work with the source interfaces? |
| `nexus tap test --path tap` | Published Nexus Testnet bytecode | Does the TAP work with the current Testnet Nexus implementation in a local VM? |
| Testnet transaction | Published packages and live Testnet objects | Does the real transaction work with network state, routing, gas, and services? |

<!-- markdownlint-enable MD013 -->

For TAP tests that call Nexus, use `nexus tap test`. A direct `sui move test`
command executes the interface stub bodies, so those calls intentionally
abort.

### What `nexus tap test` does

The command performs this sequence in memory:

```text
MVR records and Move.toml
            |
            v
compile TAP source, tests, and public Nexus interfaces
            |
            +---- identify functions declared in test module extensions
            |
Sui RPC ----+---- download the resolved published Nexus modules
            |
            v
append only the developer test functions to matching published modules
            |
            v
verify the resulting modules and run the Sui Move unit test VM
```

Existing Nexus function definitions are never replaced. Their bytecode is the
bytecode fetched from the package selected by MVR for the requested
environment. The added test functions exist only for this process, and the
resulting modules are marked as not publishable.

For every declaration used by an extension, the linker checks module identity,
function signatures, type abilities, struct layouts, and enum layouts. It then
verifies each complete bytecode module. A stale interface or a fixture that
attempts to redefine Nexus behavior fails before the suite runs.

## Write a complete unit test flow

A useful TAP test should cover a behavior boundary, not only one getter. The
complete example in [`examples/local_testing`](../examples/local_testing)
follows this sequence:

1. Create the TAP schema with published Nexus functions.
2. Validate the schema with the published Nexus validator.
3. Create TAP owned state with a test transaction context.
4. Convert raw input to canonical `NexusData` with published constructors.
5. Run the complete TAP owned decision.
6. Validate the resulting `TaggedOutput` with published Nexus code.
7. Assert the output payload and every relevant TAP state change.
8. Destroy the TAP test state so resource leaks fail visibly.

The central test looks like this:

```move
#[test]
fun complete_flow_accepts_and_rejects_canonical_inputs() {
    let ctx = &mut tx_context::dummy();
    let schema = application::schema();
    schema.assert_valid_for_tool(false);
    let mut state = application::new(5, ctx);

    let input = application::prepare_input(&schema, b"hello Nexus");
    assert!(schema.conforms_complete_input(&vector[copy input]));

    let output = application::review(&mut state, &input);
    assert!(schema.conforms_raw_output(&output));
    assert_eq!(*tagged_output::tag(&output), b"accepted");
    assert_eq!(application::accepted_count(&state), 1);

    application::destroy_for_testing(state);
}
```

This is a real local execution of the TAP and the called Nexus functions. It
does not approximate those Nexus functions with mocks.

## Create only the fixtures a test needs

Start with public Nexus constructors. Add a fixture only when normal TAP code
cannot create or inspect the required value. Common reasons are private
fields, private enum variants, object identity, or deliberately invalid state
needed for an error path.

A test module extension shares the scope of the module it extends. For
example, Nexus has an internal test helper that creates an unchecked
`NexusData::Many`. That helper is absent from published bytecode because it is
test code. A TAP author can recreate the same small fixture:

```move
#[test_only]
extend module nexus_primitives::data;

/// Creates invalid data so a TAP can verify its rejection path.
public fun unchecked_many_for_testing(values: vector<NexusValue>): NexusData {
    NexusData::Many { values }
}
```

Use it from the TAP test through the original module name:

```move
#[test]
fun extension_fixture_exercises_invalid_input_path() {
    let schema = application::schema();
    let malformed = data::unchecked_many_for_testing(vector[]);

    assert!(!schema.conforms_complete_input(&vector[malformed]));
}
```

The fixture constructs state. The assertion still calls the exact published
Nexus implementation.

### Fixture rules

1. Put extensions under `tests/` and annotate each one with `#[test_only]`.
2. Keep one extension per Nexus module and collect that module's helpers in one
   file.
3. Name helpers with `_for_testing`.
4. Prefer direct construction, focused observation, and cleanup helpers.
5. Call published Nexus functions for behavior. Do not copy protocol behavior
   into a fixture.
6. Construct the smallest valid state that reaches the behavior under test.
7. Also construct deliberately invalid state when a rejection path matters.
8. Never redefine an existing Nexus function. The CLI rejects this.

Extensions can call published Nexus functions and can call extensions added to
other Nexus modules. The example demonstrates both cases.

### Why Nexus does not ship every fixture

Fixture needs are application specific. A protocol fixture library would need
to predict every object state, capability arrangement, and failure case that a
TAP author may need. It would also become a second API that Nexus must maintain.

Developer owned extensions avoid that problem. The public interfaces describe
the available shapes. Each TAP creates only the setup, inspection, and cleanup
needed by its own tests.

Published Nexus `#[test_only]` functions are not available because Sui removes
them before package publication. Bytecode download cannot recover code that
was never published. Recreate the outcome of a small setup helper through an
extension. If a private helper contains protocol behavior, arrange its inputs
with an extension and exercise a supported published function instead.

## Reproduce the structure of an internal test

TAP tests can use the same arrange, act, assert, and cleanup structure as Nexus
internal examples. The source of each piece changes as follows:

<!-- markdownlint-disable MD013 -->

| Internal test element | TAP developer equivalent |
| --- | --- |
| TAP module function | Call the developer owned function directly. The TAP source is available. |
| Public Nexus function | Call it directly. `nexus tap test` supplies its published body. |
| Nexus helper that only constructs private state | Recreate the required value in a test module extension. |
| Nexus helper that only reads private state | Add a focused view in a test module extension. |
| Nexus helper that destroys fixture state | Add a focused cleanup function in a test module extension. |
| Nexus helper that performs protocol behavior | Arrange its input state, then call the supported published behavior instead of copying it. |
| TAP object used across transactions | Use `sui::test_scenario` and the same ownership mode as production. |
| Current shared protocol object from a live deployment | Exercise it on Testnet, unless the unit suite deliberately constructs the complete equivalent state. |

<!-- markdownlint-enable MD013 -->

A full local protocol flow is possible when the test constructs every object
and capability that the called functions require. This is the same principle
used by internal Move tests. The extension mechanism removes the private field
barrier, but it does not invent state. The TAP author remains responsible for
arranging a coherent fixture.

When fixture setup becomes larger than the TAP behavior being tested, keep the
TAP decision and transformation tests local and move the live object lifecycle
to Testnet. That split keeps unit tests fast and readable without weakening the
network acceptance check.

## Test stateful object flows

Use `tx_context::dummy()` when one transaction context is enough. This keeps a
test compact and is appropriate for owned values and direct function calls.

Use `sui::test_scenario` when sender changes, ownership changes, shared objects,
or several transaction boundaries are part of TAP behavior. A scenario test
should follow the same structure as a normal transaction sequence:

1. Begin with the first sender.
2. Create and transfer or share TAP objects.
3. Advance with `next_tx`.
4. Take each object with the ownership mode used by production code.
5. Run the TAP action and return objects that remain live.
6. Advance again and assert durable state.
7. Consume or delete every owned test resource.
8. End the scenario.

The scenario simulates Sui object ownership inside the unit VM. It still does
not reproduce validators, consensus, live shared object versions, or gas
selection.

## Test success, rejection, and invariants

For every material TAP action, cover:

| Case | Suggested assertion |
| --- | --- |
| Valid input | Result payload, TAP state, and Nexus output conformance |
| Boundary input | Minimum and maximum accepted values |
| Invalid shape | Rejection result or expected abort |
| Wrong authority | Expected abort at the responsible module |
| Repeated action | Idempotence or explicit duplicate rejection |
| Resource exit | All owned resources consumed, returned, or deleted |

Use an exact error constant when the interface exposes it:

```move
#[test, expected_failure(
    abort_code = my_tap::application::EInvalidInput,
    location = my_tap::application,
)]
fun invalid_input_is_rejected() {
    application::submit_invalid_input();
}
```

Some Nexus error constants are private. In that case, assert the Move abort
status and module location:

```move
#[test, expected_failure(
    major_status = 4016,
    location = nexus_primitives::data,
)]
fun empty_collection_is_rejected() {
    data::many(vector[]);
}
```

The second form proves that a Move abort came from the expected Nexus module.
It does not distinguish two private abort reasons in that module.

## Run and focus a suite

Run all tests against Testnet Nexus bytecode:

```sh
nexus tap test --path tap
```

List discovered tests without running them:

```sh
nexus tap test --path tap --list
```

Run tests whose full name contains a value:

```sh
nexus tap test --path tap complete_flow
```

Set the number of test threads:

```sh
nexus tap test --path tap --threads 1
```

Check Mainnet compatibility before a Mainnet release:

```sh
nexus tap test --path tap --build-env mainnet
```

Testnet and Mainnet can contain different package versions. Run the suite for
the same environment that will receive the TAP.

## What local unit tests can prove

With suitable developer fixtures, a local suite can prove:

1. TAP owned functions, branching, errors, state changes, and cleanup.
2. Calls to public Nexus functions using the selected published bytecode.
3. Nexus type construction and validation that does not require unavailable
   live state.
4. TAP object flows modeled with `tx_context` or `test_scenario`.
5. Interactions among several Nexus packages in one local VM.
6. Expected Move aborts and module locations.
7. Compatibility with the current Testnet or Mainnet Nexus package graph.

A local suite cannot by itself prove:

1. The contents or current versions of live Nexus shared objects.
2. Package publication, upgrade, or dependency routing in a submitted
   transaction.
3. Gas budget, coin selection, validator execution, consensus, or congestion.
4. Leader selection and other behavior that depends on current network state.
5. Offchain Tool availability, HTTP behavior, signatures, or timeouts.
6. Indexer, event subscription, RPC, or client serialization behavior.
7. A complete workflow that depends on state the test did not construct.

The practical rule is simple: unit test all deterministic TAP behavior and all
reachable Nexus behavior locally. Use Testnet for the first assertion that
depends on live state or a submitted transaction.

## Testnet integration path

Testnet is the next evidence layer, not a replacement for unit tests.

### 1. Build and validate

```sh
sui move build --path tap --build-env testnet
nexus tap test --path tap
nexus tap validate-skill --config skill.tap.json
```

Confirm every Tool referenced by `dag.json` is registered on Testnet:

```sh
nexus tool inspect --tool-fqn example.publisher.tool@1
```

### 2. Check Nexus CLI configuration

Configure a Testnet RPC URL, signer, and the current Nexus object map by
following the public Nexus setup documentation. Then inspect the active
configuration:

```sh
nexus conf get --json
```

Do not publish until the RPC and Nexus object map both target Testnet.

### 3. Publish the TAP package and DAG

```sh
nexus tap publish-skill \
  --config skill.tap.json \
  --out tap.publish.json \
  --json
```

This is a real network write and spends gas. Preserve `tap.publish.json`; it
contains the published DAG identity and the skill requirements needed for the
next step.

### 4. Create an agent and bind the skill

For a new agent:

```sh
nexus tap bind --artifact tap.publish.json --json
```

For an existing agent:

```sh
nexus tap register-skill \
  --artifact tap.publish.json \
  --agent-id 0xAGENT \
  --json
```

Record the returned agent ID and skill ID. Confirm the live requirements:

```sh
nexus tap requirements \
  --agent-id 0xAGENT \
  --skill-id 0 \
  --json
```

### 5. Schedule one Testnet execution

Use input JSON that matches the entry ports in `dag.json`:

```sh
nexus task schedule \
  --agent-id 0xAGENT \
  --skill-id 0 \
  --input-json '{"entry":{"input":"value"}}' \
  --prepay-amount-mist 500000000 \
  --occurrence-budget-mist 500000000 \
  --now \
  --json
```

The exact input JSON depends on the DAG. Add each required authorization with
`--authorization-binding vertex=0xRECIPIENT`. Use `nexus task schedule --help`
for recurrence, deadlines, Agent funding, and priority fees.

### 6. Assert network effects

Use the returned Task ID:

```sh
nexus task inspect --task-id 0xTASK --json
nexus task occurrence list --task-id 0xTASK --json
```

A strong integration check asserts transaction success, relevant event values,
Task and occurrence state, TAP object state, and the expected Tool result. It
should also use isolated Testnet objects so another run cannot corrupt the
result.

## Release checklist

Before Testnet publication:

1. `nexus tap test --path tap` passes.
2. Every important TAP success and rejection path has a unit test.
3. Fixtures arrange state but do not duplicate Nexus behavior.
4. `sui move build --path tap --build-env testnet` passes.
5. `nexus tap validate-skill --config skill.tap.json` passes.
6. Every DAG Tool exists on Testnet and its schema matches the DAG.

Before Mainnet publication:

1. The full Testnet integration path has passed.
2. `nexus tap test --path tap --build-env mainnet` passes.
3. A Mainnet build passes with `--build-env mainnet`.
4. Mainnet Tool registrations and Nexus object configuration are verified.
5. No test fixture or test module is present in published TAP bytecode.

## Troubleshooting

### A direct `sui move test` call reaches `ELocalExecutionUnavailable`

The test executed a source interface stub. Run it with `nexus tap test` when it
needs Nexus behavior.

### An extension is rejected by the parser

Set `edition = "2024.alpha"`, add `#[test_only]`, and place the extension in
the root TAP package. Dependency packages cannot supply extensions for a
consumer test.

### Two extension files conflict

Move permits only one active extension for the same module and mode. Combine
the helpers in one file under `tests/`.

### A fixture cannot find a field, variant, or function

Confirm that the TAP depends on the package containing that declaration and
that the current public interface includes it. Private fields and enum variants
can be used inside an extension. A Nexus test function removed before
publication cannot be called and must be recreated when appropriate.

### The linker reports an ABI or layout mismatch

The source interface and selected published package do not describe the same
module. Update the interface package record, select the intended build
environment, and run again. Do not bypass the check.

### The command cannot fetch bytecode

Confirm network access and retry. The command reads the Sui Testnet or Mainnet
RPC selected by `--build-env`; it does not use wallet credentials for this
read.

### Tests pass locally but Testnet fails

Compare the transaction sender, object IDs and versions, shared object
mutability, Tool registration, authorization bindings, input JSON, gas budget,
and active Nexus object map. These are integration inputs and are outside the
local unit test VM unless the test explicitly constructs an equivalent model.

### A failure inside Nexus has no Nexus source line

Published packages contain bytecode but do not expose the private Nexus source
map. A failure can identify the Nexus module and bytecode location, while TAP
frames still use the TAP source map produced during compilation. Use the module
location and the smallest focused input to isolate the published call, then
confirm any live state assumptions on Testnet.

## Source and publication safety

The interface packages and published bytecode are dependencies, not TAP
publication inputs. Do not publish these interface packages and do not use
them to upgrade Nexus.

The command does not reveal Nexus source. Sui package bytecode is public chain
data and is inherently inspectable. The local overlay adds only developer
owned test functions and exists only in memory for the unit test process.

For the exact executable code behind this guide, read the
[`examples/local_testing`](../examples/local_testing) package.
