/// Interface for the published [`nexus_interface::dag`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_interface::dag;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Capability witness for migration and identity replacement of one [`DAG`].
public struct OverDAG has drop {}

/// A directed acyclic graph (DAG) is a collection of [Vertex]s and [Edge]s
/// that describe how to walk the graph.
public struct DAG has key, store {
    id: sui::object::UID,
}

/// Version one stored layout for [`DAG`].
///
/// The stable [`DAG`] cannot contain these fields because its published layout
/// must remain unchanged while stored data evolves.
public struct DAGInnerV1 has store {
    /// True after construction authority is consumed. Production finalization
    /// also freezes the outer object, making this promise independent of code.
    finalized: bool,
    /// Lists all vertices in insertion order and maps them to their bound [`VertexInfo`].
    vertices: sui::linked_table::LinkedTable<
        nexus_interface::graph::Vertex,
        nexus_interface::graph::VertexInfo,
    >,
    /// Defines entry points to the DAG.
    ///
    /// The outer map is a list of groups.
    /// Only one group can be used to start the execution.
    /// Those DAGs that don't care about entry groups can use the default one
    /// defined in [default_entry_group].
    ///
    /// Within a group, all vertex port pairs are entry and must all be provided
    /// with a value when beginning an execution.
    /// For each vertex in the group the DAG will spawn a walk if all vertex
    /// input ports defined in the `vertices` map have a value.
    /// It is possible to provide entry values for vertices that will be
    /// executed at a later point and not when the execution begins.
    ///
    /// Default values cannot be overridden.
    entry_groups: sui::vec_map::VecMap<
        nexus_interface::graph::EntryGroup,
        sui::vec_map::VecMap<
            nexus_interface::graph::Vertex,
            sui::vec_set::VecSet<nexus_interface::graph::InputPort>,
        >,
    >,
    /// Maps the outputs of vertices to the inputs of other vertices.
    /// The value is never an empty vector.
    edges: sui::table::Table<nexus_interface::graph::Vertex, vector<nexus_interface::graph::Edge>>,
    /// Marks output ports on vertices that are meant to be shared as execution
    /// results.
    outputs: sui::table::Table<
        nexus_interface::graph::Vertex,
        vector<nexus_interface::graph::OutputVariantPort>,
    >,
    /// Maps [`VertexInputPort`]s to default values.
    /// A port with a default cannot also receive input from an [`Edge`] or an [`EntryGroup`].
    ///
    /// Useful for configurations such as LLM system prompts.
    defaults_to_input_ports: sui::table::Table<
        nexus_interface::graph::VertexInputPort,
        nexus_primitives::data::NexusData,
    >,
    /// Optional DAG wide default post failure action.
    post_failure_action: std::option::Option<nexus_interface::graph::PostFailureAction>,
}

/// Emitted when a new DAG is created.
public struct DAGCreatedEvent has copy, drop {
    dag: sui::object::ID,
}

/// Emitted when a vertex is added to a DAG.
public struct DAGVertexAddedEvent has copy, drop {
    dag: sui::object::ID,
    vertex: nexus_interface::graph::Vertex,
    kind: nexus_interface::graph::VertexKind,
}

/// Emitted when an entry input port is added to a vertex within an entry group.
public struct DAGEntryVertexInputPortAddedEvent has copy, drop {
    dag: sui::object::ID,
    vertex: nexus_interface::graph::Vertex,
    entry_port: nexus_interface::graph::InputPort,
    entry_group: nexus_interface::graph::EntryGroup,
}

/// Emitted when an edge is added to a DAG.
public struct DAGEdgeAddedEvent has copy, drop {
    dag: sui::object::ID,
    from_vertex: nexus_interface::graph::Vertex,
    edge: nexus_interface::graph::Edge,
}

/// Emitted when an output is added to a vertex in a DAG.
public struct DAGOutputAddedEvent has copy, drop {
    dag: sui::object::ID,
    vertex: nexus_interface::graph::Vertex,
    output: nexus_interface::graph::OutputVariantPort,
}

/// Emitted when a default value is added to a vertex input port in a DAG.
public struct DAGDefaultValueAddedEvent has copy, drop {
    dag: sui::object::ID,
    vertex: nexus_interface::graph::Vertex,
    port: nexus_interface::graph::InputPort,
    value: nexus_primitives::data::NexusData,
}

/// Emitted when a DAG becomes an immutable execution contract.
public struct DAGFinalizedEvent has copy, drop {
    dag: sui::object::ID,
}

/// Creates a new empty DAG and returns its bound owner capability.
public fun new(
    ctx: &mut sui::tx_context::TxContext,
): (DAG, nexus_primitives::owner_cap::CloneableOwnerCap<OverDAG>) {
    abort ELocalExecutionUnavailable
}

/// Alias for [`new`] that makes capability custody explicit at call sites.
public fun new_with_owner_cap(
    ctx: &mut sui::tx_context::TxContext,
): (DAG, nexus_primitives::owner_cap::CloneableOwnerCap<OverDAG>) {
    abort ELocalExecutionUnavailable
}

/// Consumes construction authority and freezes this DAG as an immutable promise.
///
/// Any cloned owner capabilities become inert because a frozen object can never
/// be passed by mutable reference. Callers should complete Tool registration and
/// Agent skill binding before this transition.
public fun finalize(self: DAG, owner: nexus_primitives::owner_cap::CloneableOwnerCap<OverDAG>) {
    abort ELocalExecutionUnavailable
}

/// Adds one vertex already bound to its registered Tool ID and immutable schema.
///
/// Tool Registry is the active caller because it owns the authoritative registration mapping.
public fun add_vertex(
    self: &mut DAG,
    owner: &mut nexus_primitives::owner_cap::CloneableOwnerCap<OverDAG>,
    name: nexus_interface::graph::Vertex,
    kind: nexus_interface::graph::VertexKind,
    tool_id: sui::object::ID,
    schema: nexus_interface::meta_schema::MetaSchema,
) {
    abort ELocalExecutionUnavailable
}

/// Configures the DAG wide default post failure action.
///
/// Runtime precedence is vertex override, then DAG default, then implicit
/// `Terminate`.
public fun with_post_failure_action(
    self: DAG,
    action: nexus_interface::graph::PostFailureAction,
): DAG {
    abort ELocalExecutionUnavailable
}

/// Configures the vertex level post failure action override.
///
/// Runtime precedence is vertex override, then DAG default, then implicit
/// `Terminate`.
public fun with_vertex_post_failure_action(
    self: DAG,
    vertex: nexus_interface::graph::Vertex,
    action: nexus_interface::graph::PostFailureAction,
): DAG {
    abort ELocalExecutionUnavailable
}

/// Selects the verifier for one offchain vertex. New vertices default to `None`.
public fun set_vertex_verifier_mode(
    self: &mut DAG,
    owner: &mut nexus_primitives::owner_cap::CloneableOwnerCap<OverDAG>,
    vertex: nexus_interface::graph::Vertex,
    mode: nexus_interface::verifier::ToolVerifierMode,
) {
    abort ELocalExecutionUnavailable
}

/// Add a new input port to the vertex which has to be provided by the client
/// when they begin execution with the default entry group.
public fun with_entry_port(
    self: DAG,
    vertex: nexus_interface::graph::Vertex,
    entry_port: nexus_interface::graph::InputPort,
): DAG {
    abort ELocalExecutionUnavailable
}

/// Add a new input port to the vertex which has to be provided by the client
/// when they begin execution with the provided entry group.
public fun with_entry_port_in_group(
    self: DAG,
    vertex: nexus_interface::graph::Vertex,
    entry_port: nexus_interface::graph::InputPort,
    entry_group: nexus_interface::graph::EntryGroup,
): DAG {
    abort ELocalExecutionUnavailable
}

/// Use this after [add_vertex] to add that vertex to the default entry group.
///
/// See also [with_entry_in_group]
public fun with_entry(self: DAG, vertex: nexus_interface::graph::Vertex): DAG {
    abort ELocalExecutionUnavailable
}

/// Use this after [add_vertex] to add that vertex to the given entry group.
///
/// Special case for vertices that are meant to have no input ports and should
/// be executed as soon as the execution begins.
///
/// [begin_execution] will start execution of this vertex only if it has no
/// input ports.
public fun with_entry_in_group(
    self: DAG,
    vertex: nexus_interface::graph::Vertex,
    entry_group: nexus_interface::graph::EntryGroup,
): DAG {
    abort ELocalExecutionUnavailable
}

/// Adds a new edge to the DAG.
/// The caller must ensure all constraints required by the workflow engine are
/// upheld.
public fun with_edge(
    self: DAG,
    from_vertex: nexus_interface::graph::Vertex,
    from_variant: nexus_interface::graph::OutputVariant,
    from_port: nexus_interface::graph::OutputPort,
    to_vertex: nexus_interface::graph::Vertex,
    to_port: nexus_interface::graph::InputPort,
    kind: nexus_interface::graph::EdgeKind,
): DAG {
    abort ELocalExecutionUnavailable
}

/// Adds a new output to the DAG.
public fun with_output(
    self: DAG,
    vertex: nexus_interface::graph::Vertex,
    variant: nexus_interface::graph::OutputVariant,
    port: nexus_interface::graph::OutputPort,
): DAG {
    abort ELocalExecutionUnavailable
}

/// The input port must not have a dynamic input source.
public fun with_default_value(
    self: DAG,
    vertex: nexus_interface::graph::Vertex,
    port: nexus_interface::graph::InputPort,
    value: nexus_primitives::data::NexusData,
): DAG {
    abort ELocalExecutionUnavailable
}

/// Consumes the input [DAG] and returns a copy of it with a new ID.
///
/// This is useful if you want to build a [DAG] over multiple txs or ahead of
/// time.
///
/// The [DAG] can be an owned object only to be rebuilt and shared at a more
/// convenient time.
///
/// (On Sui an object can be shared only in the tx that created it.)
public fun rebuild(
    self: DAG,
    owner: nexus_primitives::owner_cap::CloneableOwnerCap<OverDAG>,
    ctx: &mut sui::tx_context::TxContext,
): (DAG, nexus_primitives::owner_cap::CloneableOwnerCap<OverDAG>) {
    abort ELocalExecutionUnavailable
}

/// Returns whether construction authority has been closed for this DAG.
public fun is_finalized(self: &DAG): bool {
    abort ELocalExecutionUnavailable
}

/// Requires the DAG to be an immutable execution contract.
public fun assert_finalized(self: &DAG) {
    abort ELocalExecutionUnavailable
}

/// Assert that `owner` controls this [`DAG`].
public fun assert_dag_owner(
    self: &DAG,
    owner: &mut nexus_primitives::owner_cap::CloneableOwnerCap<OverDAG>,
) {
    abort ELocalExecutionUnavailable
}

/// Returns the fully qualified tool name of the given vertex.
///
/// Aborts with `EVertexNotFound` if the vertex does not exist in the DAG.
public fun dag_vertex_tool_fqn(
    self: &DAG,
    vertex: nexus_interface::graph::Vertex,
): std::ascii::String {
    abort ELocalExecutionUnavailable
}

/// Returns the number of vertices in the DAG.
public fun vertex_count(self: &DAG): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns true if the DAG contains the given vertex.
public fun has_vertex(self: &DAG, vertex: nexus_interface::graph::Vertex): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether the vertex uses an on chain Tool.
public fun is_vertex_onchain_tool(self: &DAG, vertex: nexus_interface::graph::Vertex): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the fully qualified tool name of the given runtime vertex.
///
/// Aborts with `EVertexNotFound` if the vertex does not exist in the DAG.
public fun dag_runtime_vertex_tool_fqn(
    self: &DAG,
    vertex: nexus_interface::graph::RuntimeVertex,
): std::ascii::String {
    abort ELocalExecutionUnavailable
}

/// Returns the stable Tool object ID pinned to a DAG vertex.
public fun dag_vertex_tool_id(self: &DAG, vertex: nexus_interface::graph::Vertex): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the immutable Tool interface bound to a DAG vertex.
public fun dag_vertex_meta_schema(
    self: &DAG,
    vertex: nexus_interface::graph::Vertex,
): &nexus_interface::meta_schema::MetaSchema {
    abort ELocalExecutionUnavailable
}

/// Returns the verifier selected for an offchain vertex.
public fun dag_vertex_verifier_mode(
    self: &DAG,
    vertex: nexus_interface::graph::Vertex,
): nexus_interface::verifier::ToolVerifierMode {
    abort ELocalExecutionUnavailable
}

/// Returns the post failure action configured for a DAG vertex.
public fun dag_vertex_post_failure_action(
    self: &DAG,
    vertex: nexus_interface::graph::Vertex,
    evidence_kind: nexus_interface::verifier::FailureEvidenceKind,
): nexus_interface::graph::PostFailureAction {
    abort ELocalExecutionUnavailable
}

/// Returns true if the DAG contains the given entry group.
public fun has_entry_group(self: &DAG, entry_group: &nexus_interface::graph::EntryGroup): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the number of vertices in an entry group.
public fun entry_group_vertex_count(
    self: &DAG,
    entry_group: &nexus_interface::graph::EntryGroup,
): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns whether an entry group contains a vertex.
public fun is_entry_group_vertex(
    self: &DAG,
    entry_group: &nexus_interface::graph::EntryGroup,
    vertex: &nexus_interface::graph::Vertex,
): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the number of required ports for one entry vertex.
public fun entry_group_vertex_port_count(
    self: &DAG,
    entry_group: &nexus_interface::graph::EntryGroup,
    vertex: &nexus_interface::graph::Vertex,
): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns whether an entry vertex requires a port.
public fun is_entry_group_vertex_port(
    self: &DAG,
    entry_group: &nexus_interface::graph::EntryGroup,
    vertex: &nexus_interface::graph::Vertex,
    port: &nexus_interface::graph::InputPort,
): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the default value configured for a vertex input port, or none if there is none.
public fun default_value_for_input(
    self: &DAG,
    vertex_input: nexus_interface::graph::VertexInputPort,
): std::option::Option<nexus_primitives::data::NexusData> {
    abort ELocalExecutionUnavailable
}

/// Returns the SHA 256 hash of a vertex's effective input payload, or an empty vector if any input port has no value.
public fun effective_input_payload_sha256(
    self: &DAG,
    expected_vertex: nexus_interface::graph::RuntimeVertex,
    evaluations: &sui::vec_map::VecMap<
        nexus_interface::graph::InputPort,
        nexus_interface::graph::PortData,
    >,
): vector<u8> {
    abort ELocalExecutionUnavailable
}

/// Returns the number of input ports on the given vertex.
///
/// Aborts with `EVertexNotFound` if the vertex does not exist in the DAG.
public fun vertex_input_ports_len(self: &DAG, vertex: nexus_interface::graph::Vertex): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns the input ports of the given vertex in sorted order.
///
/// Aborts with `EVertexNotFound` if the vertex does not exist in the DAG.
public fun sorted_input_ports_for_vertex(
    self: &DAG,
    vertex: nexus_interface::graph::Vertex,
): vector<nexus_interface::graph::InputPort> {
    abort ELocalExecutionUnavailable
}

/// Returns whether the vertex uses an off chain Tool.
///
/// Aborts with `EVertexNotFound` if the vertex does not exist in the DAG.
public fun is_vertex_offchain_tool(self: &DAG, vertex: nexus_interface::graph::Vertex): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the fully qualified tool names of all vertices in the DAG.
public fun vertex_tool_fqns(self: &DAG): vector<std::ascii::String> {
    abort ELocalExecutionUnavailable
}

/// Returns the names of all vertices in linked table order.
public fun vertex_names(self: &DAG): vector<nexus_interface::graph::Vertex> {
    abort ELocalExecutionUnavailable
}

/// Returns true if the vertex has any outgoing edges.
public fun has_edges_from(self: &DAG, vertex: nexus_interface::graph::Vertex): bool {
    abort ELocalExecutionUnavailable
}

/// Returns true if the vertex has an outgoing edge originating from the given output variant.
public fun has_outgoing_edges_for_variant(
    self: &DAG,
    vertex: nexus_interface::graph::Vertex,
    variant: nexus_interface::graph::OutputVariant,
): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the outgoing edges of the given vertex.
///
/// Aborts if the vertex has no outgoing edges.
public fun edges_from(
    self: &DAG,
    vertex: nexus_interface::graph::Vertex,
): &vector<nexus_interface::graph::Edge> {
    abort ELocalExecutionUnavailable
}

/// Resolve `_err_eval` failure policy from DAG policy and evidence kind.
public fun resolve_err_eval_failure_policy(
    self: &DAG,
    evaluated_vertex: nexus_interface::graph::RuntimeVertex,
    failure_evidence_kind: nexus_interface::verifier::FailureEvidenceKind,
): nexus_interface::graph::PostFailureAction {
    abort ELocalExecutionUnavailable
}

/// Return the `_err_eval` outcome that matches the current output variant.
public fun err_eval_record_outcome_for_variant(
    self: &DAG,
    evaluated_vertex: nexus_interface::graph::RuntimeVertex,
    failure_evidence_kind: nexus_interface::verifier::FailureEvidenceKind,
    variant: nexus_interface::graph::OutputVariant,
): nexus_interface::graph::PostFailureAction {
    abort ELocalExecutionUnavailable
}
