/// Interface for the published [`nexus_scheduler::execution_entries`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_scheduler::execution_entries;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Starts an admitted execution through the currently authorized Scheduler runtime.
public fun start_execution(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Starts and shares an admitted execution through the currently authorized Scheduler runtime.
public fun start_and_share(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: nexus_workflow::execution::DAGExecution,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}
