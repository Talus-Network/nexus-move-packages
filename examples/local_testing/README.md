# Local Move testing example

This is an executable consumer package showing how to test application logic
when Nexus is available only as interface stubs.

It demonstrates both sides of the local boundary:

- application logic can use Nexus types without calling Nexus functions;
- test only module extensions can construct and inspect otherwise private
  Nexus value shapes;
- a call to an existing Nexus function aborts with the documented
  `ELocalExecutionUnavailable` error.

## Files

| File | Purpose |
| --- | --- |
| [`Move.toml`](Move.toml) | Uses `edition = "2024.alpha"`, which is currently required for module extensions, and points to this checkout's interface packages. |
| [`sources/application.move`](sources/application.move) | Application logic that stores and reads Nexus values without crossing into Nexus behavior. |
| [`tests/data_extension.move`](tests/data_extension.move) | Extends `nexus_primitives::data` with the smallest constructor and observation needed by the test. |
| [`tests/task_extension.move`](tests/task_extension.move) | Extends `nexus_scheduler::task` with helpers for a private `TaskStatus` variant. |
| [`tests/application_tests.move`](tests/application_tests.move) | Tests application logic and verifies that an existing Nexus constructor aborts locally. |

The example uses local dependencies so it always tests the interfaces in the
current checkout. In an external consumer package, use the corresponding MVR
dependencies instead:

```toml
[dependencies]
nexus_primitives = { r.mvr = "@talus/nexus-primitives" }
nexus_scheduler = { r.mvr = "@talus/nexus-scheduler" }
```

## Run the tests

Run the example from the repository root:

```sh
sui move test --path examples/local_testing --warnings-are-errors
```

Both tests should pass: one exercises the extensions and application logic;
the other succeeds because the stub abort is expected.

## Adapt it to an application

1. Keep code that invokes Nexus behind a small application boundary.
1. Put `#[test_only] extend module ...` files under `tests/`.
1. Add only the constructors and observations that the local test needs.
1. Test application decisions and transformations with those values.
1. Add an expected failure test if the local Nexus boundary should remain
   explicit.
1. Submit real Testnet transactions for Nexus authorization, validation,
   events, shared objects, and state transitions.

Module extensions do not override existing functions and are not a local
implementation of Nexus. See the repository's complete
[stub and testing guide](../../README.md#local-move-tests).
