/// Interface for the published [`nexus_workflow::invocation_adapter`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_workflow::invocation_adapter;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Creates the canonical policy request for one active runtime vertex.
///
/// The cashier is borrowed immutably and is not part of the conflict domain.
public fun new_request(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    dag: &nexus_interface::dag::DAG,
    execution: &nexus_workflow::execution::DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
    clock: &sui::clock::Clock,
): nexus_interface::payment::InvocationRequest {
    abort ELocalExecutionUnavailable
}

/// Returns whether the execution payment holds the exact runtime vertex lock.
public fun is_locked(
    execution: &nexus_workflow::execution::DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
    tool_fqn: std::ascii::String,
): bool {
    abort ELocalExecutionUnavailable
}
