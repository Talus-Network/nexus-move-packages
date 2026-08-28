module nexus_interface::graph;

//! Interface for [`nexus_interface::graph`].
//!
//! Calls resolve to the published package.

/// Identifies a DAG vertex at runtime, with optional loop iteration state.
/// Iterator state is attached at runtime because the static DAG stores each vertex once.
public enum RuntimeVertex has copy, drop, store {
    WithIterator {
        vertex: Vertex,
        /// Zero based iteration currently being evaluated.
        iteration: u64,
        /// Total number of iterations in this runtime expansion.
        out_of: u64,
    },
    Plain {
        vertex: Vertex,
    },
}

/// A named node in the DAG, identified by its ASCII name.
public struct Vertex has copy, drop, store {
    name: std::ascii::String,
}

/// Distinguishes whether a vertex is executed on chain or off chain.
public enum VertexKind has copy, drop, store {
    /// Executes through the on chain Tool result flow, whose UID proof requirements bind participation.
    OnChain {
        tool_fqn: std::ascii::String,
    },
    /// Delegates execution to an off chain Tool and receives its result in a later transaction.
    OffChain {
        tool_fqn: std::ascii::String,
    },
}

/// DAGs can group several [Vertex]s into a single entry point.
public struct EntryGroup has copy, drop, store {
    name: std::ascii::String,
}

/// Action applied when a vertex resolves to failure evidence with no matching outgoing edge.
/// `Terminate` aborts the execution; `TransientContinue` lets unrelated walks continue.
public enum PostFailureAction has copy, drop, store {
    Terminate,
    TransientContinue,
}

/// Names one mutually exclusive output variant of a Tool evaluation, such as `ok` or `err`.
/// Together with [`OutputPort`], variants model an algebraic sum whose selected case carries named fields.
public struct OutputVariant has copy, drop, store {
    name: std::ascii::String,
}

/// Defines how data moves across an edge, including loop and collection semantics.
public enum EdgeKind has copy, drop, store {
    Normal,
    /// Can loop over each element in [`nexus_primitives::data::NexusData::Many`].
    ForEach,
    /// Can collect multiple elements of the same type into a single
    /// [`nexus_primitives::data::NexusData::Many`].
    Collect,
    /// Can create a pseudo loop in the DAG.
    DoWhile,
    /// Exits a do while loop.
    Break,
    /// Static edges provide values to looped vertices from outside the loop.
    Static,
}

/// Names one payload port within an output variant.
/// This models algebraic enumeration type of first degree.
///
/// # Example
/// Let's model computation that can fail, or it can succeed with some image
/// data and some JSON metadata.
///
/// There would be a [Vertex] which with two [OutputVariant]s: "ok" and "err".
/// The "err" [OutputVariant] has one [OutputPort]: "reason".
/// The "ok" [OutputVariant] has two [OutputPort]s: "img" and "metadata".
public struct OutputPort has copy, drop, store {
    name: std::ascii::String,
}

/// Runtime input data for a single input port, either a single value or one
/// keyed per loop iteration.
public enum PortData has copy, drop, store {
    Single {
        data: nexus_primitives::data::NexusData,
        is_static: bool,
    },
    Many {
        data: sui::vec_map::VecMap<u64, nexus_primitives::data::NexusData>,
        total_iterations: u64,
    },
}

/// An input port is a named input to a vertex.
public struct InputPort has copy, drop, store {
    name: std::ascii::String,
}

/// Runtime input data collected for a vertex evaluation.
public struct VertexEvaluations has key, store {
    id: sui::object::UID,
}

/// Version one stored layout for [`VertexEvaluations`].
///
/// The stable [`VertexEvaluations`] cannot contain this map because its
/// published layout must remain unchanged while stored data evolves.
public struct VertexEvaluationsInnerV1 has store {
    ports_to_data: sui::vec_map::VecMap<InputPort, PortData>,
}

/// Describes a vertex and its one explicit offchain verifier selection.
public struct VertexInfo has copy, drop, store {
    kind: VertexKind,
    /// Input ports that must be evaluated by tools before this vertex can run.
    input_ports: sui::vec_set::VecSet<InputPort>,
    /// Vertex level post failure action override.
    post_failure_action: std::option::Option<PostFailureAction>,
    /// Stable Tool object ID, bound while constructing the DAG.
    tool_id: sui::object::ID,
    /// Immutable Tool schema. None exists only before registry binding.
    meta_schema: std::option::Option<nexus_interface::meta_schema::MetaSchema>,
    /// Offchain verification mode; ignored for onchain vertices.
    verifier_mode: nexus_interface::verifier::ToolVerifierMode,
}

/// A union of [OutputVariant], and [OutputPort] identifies an output port of a [Vertex].
public struct OutputVariantPort has copy, drop, store {
    variant: OutputVariant,
    port: OutputPort,
}

/// A union of [Vertex] and [InputPort] uniquely identifies an input port within a DAG graph.
public struct VertexInputPort has copy, drop, store {
    vertex: Vertex,
    port: InputPort,
}

/// Maps output from a unique output port to an input of another vertex.
public struct Edge has copy, drop, store {
    from: OutputVariantPort,
    to: VertexInputPort,
    kind: EdgeKind,
}

/// Creates an on chain vertex kind for the given tool fully qualified name.
public native fun vertex_on_chain(tool_fqn: std::ascii::String): VertexKind;

/// Creates an off chain vertex kind for the given tool fully qualified name.
public native fun vertex_off_chain(tool_fqn: std::ascii::String): VertexKind;

/// Creates a vertex from its ASCII name.
public native fun vertex_from_string(name: std::ascii::String): Vertex;

/// Returns the vertex's ASCII name.
public native fun vertex_into_string(vertex: Vertex): std::ascii::String;

/// Creates a plain runtime vertex (without iterator state) from a vertex.
public native fun runtime_vertex_plain_from_vertex(vertex: Vertex): RuntimeVertex;

/// Creates a plain runtime vertex (without iterator state) from an ASCII name.
public native fun runtime_vertex_plain_from_string(name: std::ascii::String): RuntimeVertex;

/// Creates a runtime vertex carrying iterator position and bound from a vertex.
public native fun runtime_vertex_with_iterator_from_vertex(
    vertex: Vertex,
    iteration: u64,
    out_of: u64,
): RuntimeVertex;

/// Creates a runtime vertex carrying iterator position and bound from an ASCII name.
public native fun runtime_vertex_with_iterator_from_string(
    name: std::ascii::String,
    iteration: u64,
    out_of: u64,
): RuntimeVertex;

/// Returns the `Normal` edge kind.
public native fun edge_kind_normal(): EdgeKind;

/// Returns the `ForEach` edge kind.
public native fun edge_kind_for_each(): EdgeKind;

/// Returns the `Collect` edge kind.
public native fun edge_kind_collect(): EdgeKind;

/// Returns the `DoWhile` edge kind.
public native fun edge_kind_do_while(): EdgeKind;

/// Returns the `Break` edge kind.
public native fun edge_kind_break(): EdgeKind;

/// Returns the `Static` edge kind.
public native fun edge_kind_static(): EdgeKind;

/// Returns the `Terminate` post failure action value.
public native fun post_failure_action_terminate(): PostFailureAction;

/// Returns the `TransientContinue` post failure action value.
public native fun post_failure_action_transient_continue(): PostFailureAction;

/// Creates an output variant from its ASCII name.
public native fun output_variant_from_string(name: std::ascii::String): OutputVariant;

/// Returns the output variant's ASCII name.
public native fun output_variant_into_string(variant: OutputVariant): std::ascii::String;

/// Creates an output port from its ASCII name.
public native fun output_port_from_string(name: std::ascii::String): OutputPort;

/// Builds the port from raw.
public native fun output_port_from_raw(name: vector<u8>): OutputPort;

/// Returns the output port's ASCII name.
public native fun output_port_into_string(port: OutputPort): std::ascii::String;

/// Creates an input port from its ASCII name.
public native fun input_port_from_string(name: std::ascii::String): InputPort;

/// Returns the input port's ASCII name.
public native fun input_port_into_string(port: InputPort): std::ascii::String;

/// Creates single valued, non static port data.
public native fun port_data_single(data: nexus_primitives::data::NexusData): PortData;

/// Creates single valued port data marked as originating from a static edge.
public native fun port_data_single_static(data: nexus_primitives::data::NexusData): PortData;

/// Creates port data keyed by iteration number for a looped vertex.
public native fun port_data_many(
    data: sui::vec_map::VecMap<u64, nexus_primitives::data::NexusData>,
    total_iterations: u64,
): PortData;

/// Creates an empty `VertexEvaluations` object with a fresh UID.
public native fun new_vertex_evaluations(ctx: &mut sui::tx_context::TxContext): VertexEvaluations;

/// Returns a reference to the map from input port to its collected port data.
public native fun vertex_evaluations_ports_to_data(
    self: &VertexEvaluations,
): &sui::vec_map::VecMap<InputPort, PortData>;

/// Returns a mutable reference to the map from input port to its port data.
public native fun vertex_evaluations_ports_to_data_mut(
    self: &mut VertexEvaluations,
): &mut sui::vec_map::VecMap<InputPort, PortData>;

/// Returns the port data value applicable to the given runtime vertex.
/// For single data the value is always returned; for iteration keyed data the
/// value for the vertex's current iteration is returned, or none if the vertex
/// has no iterator or no value is stored for that iteration.
public native fun port_data_runtime_vertex_input(
    self: &PortData,
    expected_vertex: &RuntimeVertex,
): std::option::Option<nexus_primitives::data::NexusData>;

/// Returns true if the port data is a single value rather than iteration keyed.
public native fun port_data_is_single(self: &PortData): bool;

/// Returns true if this is single port data whose value and static flag both
/// equal the given arguments.
public native fun port_data_single_matches(
    self: &PortData,
    data: nexus_primitives::data::NexusData,
    is_static: bool,
): bool;

/// Returns true if this is single port data that came from a static edge.
public native fun port_data_single_is_static(self: &PortData): bool;

/// Returns the iteration keys for iteration keyed port data, or none if single.
public native fun port_data_many_keys(self: &PortData): std::option::Option<vector<u64>>;

/// Returns the total iteration count for iteration keyed port data, or none if single.
public native fun port_data_many_total_iterations(self: &PortData): std::option::Option<u64>;

/// Returns the number of stored iteration entries, or none if single port data.
public native fun port_data_many_len(self: &PortData): std::option::Option<u64>;

/// Returns true if iteration keyed port data holds a value for the given iteration.
public native fun port_data_many_contains(self: &PortData, iteration: u64): bool;

/// Returns the value stored for the given iteration, or none if single port
/// data or no value exists for that iteration.
public native fun port_data_many_value(
    self: &PortData,
    iteration: u64,
): std::option::Option<nexus_primitives::data::NexusData>;

/// Inserts a value for the given iteration into iteration keyed port data,
/// returning true on success, or false if this is single port data.
public native fun port_data_many_insert(
    self: &mut PortData,
    iteration: u64,
    data: nexus_primitives::data::NexusData,
): bool;

/// Removes and returns the value for the given iteration, or none if single
/// port data or no value exists for that iteration.
public native fun port_data_many_remove(
    self: &mut PortData,
    iteration: u64,
): std::option::Option<nexus_primitives::data::NexusData>;

/// Returns the entry group.
public native fun default_entry_group(): EntryGroup;

/// Creates an entry group from its ASCII name.
public native fun entry_group_from_string(name: std::ascii::String): EntryGroup;

/// Returns the entry group's ASCII name.
public native fun entry_group_into_string(group: EntryGroup): std::ascii::String;

/// Returns true if the runtime vertex is plain (has no iterator state).
public native fun runtime_vertex_is_plain(vertex: &RuntimeVertex): bool;

/// Returns true if the runtime vertex carries iterator state.
public native fun runtime_vertex_is_with_iterator(vertex: &RuntimeVertex): bool;

/// Returns the current iteration of the runtime vertex, or zero if plain.
public native fun runtime_vertex_iteration_or_zero(vertex: &RuntimeVertex): u64;

/// Returns the current iteration of the runtime vertex.
/// Aborts with `ERuntimeVertexIterationUnavailable` if the vertex is plain.
public native fun runtime_vertex_iteration(vertex: &RuntimeVertex): u64;

/// Returns the total iteration bound of the runtime vertex.
/// Aborts with `ERuntimeVertexOutOfUnavailable` if the vertex is plain.
public native fun runtime_vertex_out_of(vertex: &RuntimeVertex): u64;

/// Returns true if the vertex kind is on chain.
public native fun vertex_kind_is_on_chain(kind: &VertexKind): bool;

/// Returns true if the vertex kind is off chain.
public native fun vertex_kind_is_off_chain(kind: &VertexKind): bool;

/// Returns the tool fully qualified name of the vertex kind.
public native fun vertex_kind_tool_fqn(kind: &VertexKind): std::ascii::String;

/// Returns true if the output variant is the reserved `_err_eval` variant.
public native fun output_variant_is_err_eval(variant: &OutputVariant): bool;

/// Derives the input port.
public native fun vertex_input_port(vertex: Vertex, port: InputPort): VertexInputPort;

/// Builds a vertex input port from the vertex and port ASCII names.
public native fun vertex_input_port_from_string(
    vertex: std::ascii::String,
    port: std::ascii::String,
): VertexInputPort;

/// Returns the vertex component of the vertex input port.
public native fun vertex_input_port_vertex(port: &VertexInputPort): Vertex;

/// Returns the input port component of the vertex input port.
public native fun vertex_input_port_port(port: &VertexInputPort): InputPort;

/// Combines an output variant and output port into an output variant port.
public native fun output_variant_port(variant: OutputVariant, port: OutputPort): OutputVariantPort;

/// Returns the output variant component of the output variant port.
public native fun output_variant_port_variant(port: &OutputVariantPort): OutputVariant;

/// Returns the output port component of the output variant port.
public native fun output_variant_port_port(port: &OutputVariantPort): OutputPort;

/// Creates an edge from an output variant port to a vertex input port with the given kind.
public native fun edge(from: OutputVariantPort, to: VertexInputPort, kind: EdgeKind): Edge;

/// Returns the edge's source output variant port.
public native fun edge_from(edge: &Edge): OutputVariantPort;

/// Returns the edge's destination vertex input port.
public native fun edge_to(edge: &Edge): VertexInputPort;

/// Returns the edge's kind.
public native fun edge_kind(edge: &Edge): EdgeKind;

/// Returns the output variant of the edge's source port.
public native fun edge_from_variant(edge: &Edge): OutputVariant;

/// Returns the output port of the edge's source port.
public native fun edge_from_port(edge: &Edge): OutputPort;

/// Returns the destination vertex of the edge.
public native fun edge_to_vertex(edge: &Edge): Vertex;

/// Returns the destination input port of the edge.
public native fun edge_to_port(edge: &Edge): InputPort;

/// Helper to construct inputs for [execution_entries::begin_execution].
/// Creates a map from a row based input (ie. repeat vertex name for each row).
public native fun inputs_to_begin_execution(
    vertices: vector<Vertex>,
    ports: vector<InputPort>,
    data: vector<nexus_primitives::data::NexusData>,
): sui::vec_map::VecMap<Vertex, sui::vec_map::VecMap<InputPort, nexus_primitives::data::NexusData>>;

/// Converts a tagged output into its DAG output variant and per port data map.
public native fun tagged_output_to_dag_types(
    tagged_output: nexus_primitives::tagged_output::TaggedOutput,
): (OutputVariant, sui::vec_map::VecMap<OutputPort, nexus_primitives::data::NexusData>);

/// Converts raw tagged output parts into a DAG output variant and per port data map.
public native fun tagged_output_parts_to_dag_types(
    variant_bytes: vector<u8>,
    ports: sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>,
): (OutputVariant, sui::vec_map::VecMap<OutputPort, nexus_primitives::data::NexusData>);

/// Returns the vertex name.
public native fun vertex_name(vertex: &RuntimeVertex): Vertex;

/// Returns the map's output ports sorted ascending by their name bytes.
public native fun sorted_output_ports(
    variant_ports_to_data: &sui::vec_map::VecMap<OutputPort, nexus_primitives::data::NexusData>,
): vector<OutputPort>;

/// Computes a deterministic SHA 256 digest over the output variant name and its
/// ports and data, sorted by port name for a stable ordering.
public native fun submitted_output_payload_sha256(
    variant: OutputVariant,
    variant_ports_to_data: &sui::vec_map::VecMap<OutputPort, nexus_primitives::data::NexusData>,
): vector<u8>;

/// Returns the input ports sorted ascending by their name bytes.
public native fun sorted_input_ports(
    input_ports: &sui::vec_set::VecSet<InputPort>,
): vector<InputPort>;
