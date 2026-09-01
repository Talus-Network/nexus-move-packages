/// Interface for the published [`nexus_interface::meta_schema`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_interface::meta_schema;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Execution relevant class of one typed value.
public enum ValueKind has copy, drop, store {
    Object,
    Data,
}

/// One directional Tool port contract.
public struct PortSchema has copy, drop, store {
    port_name: vector<u8>,
    is_many: bool,
    value_kind: ValueKind,
}

/// Transient serialization only commitment for one immutable schema port.
public enum PortCommitment has copy, drop, store {
    One {
        kind: ValueKind,
        commitment: vector<u8>,
    },
    Many {
        kind: ValueKind,
        commitments: vector<vector<u8>>,
    },
}

/// One mutually exclusive Tool output alternative.
public struct OutputVariantSchema has copy, drop, store {
    variant_name: vector<u8>,
    ports: vector<PortSchema>,
}

/// Immutable execution contract registered for one Tool.
public struct MetaSchema has copy, drop, store {
    input_ports: vector<PortSchema>,
    output_variants: vector<OutputVariantSchema>,
}

/// Transient serialization only binding between one immutable port name and its value commitment.
public struct PortInputCommitment has copy, drop, store {
    port_name: vector<u8>,
    commitment: PortCommitment,
}

public fun value_kind_object(): ValueKind {
    abort ELocalExecutionUnavailable
}

public fun value_kind_data(): ValueKind {
    abort ELocalExecutionUnavailable
}

public fun port_schema(port_name: vector<u8>, is_many: bool, value_kind: ValueKind): PortSchema {
    abort ELocalExecutionUnavailable
}

public fun output_variant_schema(
    variant_name: vector<u8>,
    ports: vector<PortSchema>,
): OutputVariantSchema {
    abort ELocalExecutionUnavailable
}

public fun new(
    input_ports: vector<PortSchema>,
    output_variants: vector<OutputVariantSchema>,
): MetaSchema {
    abort ELocalExecutionUnavailable
}

public fun assert_valid_for_tool(self: &MetaSchema, is_offchain: bool) {
    abort ELocalExecutionUnavailable
}

/// Checks whether the One/Many variant matches the schema cardinality.
public fun conforms_input_cardinality(
    schema: &PortSchema,
    value: &nexus_primitives::data::NexusData,
): bool {
    abort ELocalExecutionUnavailable
}

/// Validates untrusted typed values against one port schema and constructs canonical data.
public fun store_input(
    schema: &PortSchema,
    values: vector<nexus_primitives::data::NexusValue>,
): nexus_primitives::data::NexusData {
    abort ELocalExecutionUnavailable
}

/// Checks canonical cardinality and semantic kind directly from stored values.
public fun conforms_input_port(
    schema: &PortSchema,
    value: &nexus_primitives::data::NexusData,
): bool {
    abort ELocalExecutionUnavailable
}

/// Checks complete canonical inputs in immutable schema order.
public fun conforms_complete_input(
    self: &MetaSchema,
    values: &vector<nexus_primitives::data::NexusData>,
): bool {
    abort ELocalExecutionUnavailable
}

/// Checks an exact ordered canonical output envelope.
public fun conforms_raw_output(
    self: &MetaSchema,
    output: &nexus_primitives::tagged_output::TaggedOutput,
): bool {
    abort ELocalExecutionUnavailable
}

/// Builds the canonical schema mismatch output through the typed active builder.
public fun canonical_schema_mismatch_failure(): nexus_primitives::tagged_output::TaggedOutput {
    abort ELocalExecutionUnavailable
}

public fun port_commitment_one(value: &nexus_primitives::data::NexusValue): PortCommitment {
    abort ELocalExecutionUnavailable
}

public fun port_commitment_many(
    values: &vector<nexus_primitives::data::NexusValue>,
): PortCommitment {
    abort ELocalExecutionUnavailable
}

/// Hashes canonical schema ordered name/commitment pairs shared by Nexus and on chain Tools.
public fun input_hash(
    port_names: vector<vector<u8>>,
    commitments: vector<PortCommitment>,
): vector<u8> {
    abort ELocalExecutionUnavailable
}

/// Validates complete persisted canonical inputs and derives the shared input hash.
public fun input_hash_for_stored(
    self: &MetaSchema,
    values: &vector<nexus_primitives::data::NexusData>,
): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun input_ports(self: &MetaSchema): &vector<PortSchema> {
    abort ELocalExecutionUnavailable
}

public fun port_name(self: &PortSchema): &vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun port_is_many(self: &PortSchema): bool {
    abort ELocalExecutionUnavailable
}

public fun find_input_port(self: &MetaSchema, name: &vector<u8>): std::option::Option<PortSchema> {
    abort ELocalExecutionUnavailable
}

public fun find_variant_port(
    self: &MetaSchema,
    variant_name: &vector<u8>,
    port_name: &vector<u8>,
): std::option::Option<PortSchema> {
    abort ELocalExecutionUnavailable
}

public fun value_kinds_compatible(from: &PortSchema, to: &PortSchema): bool {
    abort ELocalExecutionUnavailable
}

public fun failure_variant(): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun failure_port(): vector<u8> {
    abort ELocalExecutionUnavailable
}
