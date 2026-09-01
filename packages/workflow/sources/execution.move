/// Interface for the published [`nexus_workflow::execution`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_workflow::execution;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Runtime execution of [DAG] comprises walking the graph by evaluating
/// vertices and following the edges.
public struct DAGExecution has key {
    id: sui::object::UID,
}

/// Whether an agent vertex authorization grant is stored for the given runtime vertex.
public fun has_vertex_authorization_grant(
    execution: &DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
): bool {
    abort ELocalExecutionUnavailable
}

/// Verifies that authorization bindings exactly cover the vertices that need them.
///
/// A binding is required for every [`Vertex`] whose onchain [`ToolRegistry`]
/// definition requires workflow authorization. Bindings for any other vertex
/// are rejected, including names that are absent from the [`DAG`]. Exact
/// coverage makes missing authorization unreachable after execution admission.
public fun assert_complete_authorization_bindings(
    dag: &nexus_interface::dag::DAG,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    bindings: &sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
) {
    abort ELocalExecutionUnavailable
}

/// Interface version pinned when [`DAGExecution`] was created.
public fun interface_version(self: &DAGExecution): nexus_interface::version::InterfaceVersion {
    abort ELocalExecutionUnavailable
}

/// Returns the Task that produced this execution.
public fun task_id(self: &DAGExecution): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the scheduled occurrence identity.
public fun occurrence_id(self: &DAGExecution): u64 {
    abort ELocalExecutionUnavailable
}
