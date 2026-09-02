/// Interface for the published [`nexus_scheduler::invocation_adapter`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_scheduler::invocation_adapter;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Locks one [Invocation], reimburses its leader, and requests Tool work.
///
/// The [CloneableOwnerCap] permits only the current active leader.
public fun lock_and_request(
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
) {
    abort ELocalExecutionUnavailable
}

/// Applies one pending Invocation outcome through the current runtime.
public fun settle(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
    receiving: sui::transfer::Receiving<nexus_tool::invocation::Invocation>,
) {
    abort ELocalExecutionUnavailable
}

/// Refunds one expired Invocation through the current runtime.
public fun abort_expired(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
    receiving: sui::transfer::Receiving<nexus_tool::invocation::Invocation>,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}
