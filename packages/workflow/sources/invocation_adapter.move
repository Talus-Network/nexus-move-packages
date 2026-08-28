module nexus_workflow::invocation_adapter;

//! Interface for [`nexus_workflow::invocation_adapter`].
//!
//! Calls resolve to the published package.

/// Creates the canonical policy request for one active runtime vertex.
///
/// The cashier is borrowed immutably and is not part of the conflict domain.
public native fun new_request(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    dag: &nexus_interface::dag::DAG,
    execution: &nexus_workflow::execution::DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
    clock: &sui::clock::Clock,
): nexus_interface::payment::InvocationRequest;

/// Returns whether the execution payment holds the exact runtime vertex lock.
public native fun is_locked(
    execution: &nexus_workflow::execution::DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
    tool_fqn: std::ascii::String,
): bool;
