module nexus_scheduler::execution_entries;

//! Interface for [`nexus_scheduler::execution_entries`].
//!
//! Calls resolve to the published package.

/// Starts an admitted execution through the currently authorized Scheduler runtime.
public native fun start_execution(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);

/// Starts and shares an admitted execution through the currently authorized Scheduler runtime.
public native fun start_and_share(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: nexus_workflow::execution::DAGExecution,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);
