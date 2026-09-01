# Local Move testing example

This consumer package demonstrates the supported local testing boundary. Its
[application module](sources/application.move) stores Nexus values and tests
application behavior without calling an existing Nexus function.

The test directory adds extensions for
[Nexus data](tests/data_extension.move) and
[task status](tests/task_extension.move). These extensions construct and
inspect only the values that the application test needs. The
[application tests](tests/application_tests.move) also verify that an existing
Nexus function aborts with the documented local execution error.

Run the example from the repository root:

```sh
sui move test --path examples/local_testing --warnings-are-errors
```

Use Testnet when a test must execute published Nexus behavior.
