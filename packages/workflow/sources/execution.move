module nexus_workflow::execution;

//! Interface for [`nexus_workflow::execution`].
//!
//! Calls resolve to the published package.

/// Runtime execution of [DAG] comprises walking the graph by evaluating
/// vertices and following the edges.
public struct DAGExecution has key {
    id: sui::object::UID,
}

/// Whether an agent vertex authorization grant is stored for the given runtime vertex.
public native fun has_vertex_authorization_grant(
    execution: &DAGExecution,
    vertex: nexus_interface::graph::RuntimeVertex,
): bool;

/// Verifies that authorization bindings exactly cover the vertices that need them.
///
/// A binding is required for every [`Vertex`] whose onchain [`ToolRegistry`]
/// definition requires workflow authorization. Bindings for any other vertex
/// are rejected, including names that are absent from the [`DAG`]. Exact
/// coverage makes missing authorization unreachable after execution admission.
public native fun assert_complete_authorization_bindings(
    dag: &nexus_interface::dag::DAG,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    bindings: &sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
);

/// Interface version pinned when [`DAGExecution`] was created.
public native fun interface_version(
    self: &DAGExecution,
): nexus_interface::version::InterfaceVersion;

/// Returns the Task that produced this execution.
public native fun task_id(self: &DAGExecution): sui::object::ID;

/// Returns the scheduled occurrence identity.
public native fun occurrence_id(self: &DAGExecution): u64;
