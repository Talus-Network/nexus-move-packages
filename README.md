# Nexus Move packages

Move interfaces used to compile against the published Nexus protocol packages.

These packages contain the data types and function signatures needed for
composition. Calls resolve to the packages published on Sui. These interface
packages are dependencies only and must not be published.

> These packages provide interfaces for compiling against the published Nexus
> packages. Local Move tests may test application logic that does not invoke
> Nexus. Tests executing Nexus functions require the Testnet deployment. Local
> executable mocks are planned for a later release.

The `public native fun` declarations intentionally have no local
implementation. They support compilation, but a local Move test cannot execute
them.

## Workflow interface

`nexus_workflow` exposes only the workflow declarations intended for direct
composition:

- `execution::DAGExecution` and its public read and validation helpers
- `invocation_adapter::new_request` and `invocation_adapter::is_locked`

Workflow mutations are exposed through `nexus_scheduler`, which is the
authorized runtime facade. Functions requiring `RuntimePermit`, internal
storage and version types, values used only during settlement, and workflow
event layouts are intentionally omitted. Their omission does not alter the
packages already published onchain; it defines the supported interface surface
of this repository.

## Packages

- `nexus_kernel`
- `nexus_primitives`
- `nexus_interface`
- `nexus_tool`
- `nexus_registry`
- `nexus_workflow`
- `nexus_scheduler`
