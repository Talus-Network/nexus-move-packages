module nexus_scheduler::invocation_adapter;

//! Interface for [`nexus_scheduler::invocation_adapter`].
//!
//! Calls resolve to the published package.

/// Locks one [Invocation], reimburses its leader, and requests Tool work.
///
/// The [CloneableOwnerCap] permits only the current active leader.
public native fun lock_and_request(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    walk_index: u64,
    vertex: nexus_interface::graph::RuntimeVertex,
    authorized: nexus_tool::invocation::Invocation,
    submission_gas_charge: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);

/// Applies one pending Invocation outcome through the current runtime.
public native fun settle(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
    receiving: sui::transfer::Receiving<nexus_tool::invocation::Invocation>,
);

/// Refunds one expired Invocation through the current runtime.
public native fun abort_expired(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
    receiving: sui::transfer::Receiving<nexus_tool::invocation::Invocation>,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);
