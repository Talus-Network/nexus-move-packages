module nexus_interface::meta_schema;

//! Interface for [`nexus_interface::meta_schema`].
//!
//! Calls resolve to the published package.

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

public native fun value_kind_object(): ValueKind;

public native fun value_kind_data(): ValueKind;

public native fun port_schema(
    port_name: vector<u8>,
    is_many: bool,
    value_kind: ValueKind,
): PortSchema;

public native fun output_variant_schema(
    variant_name: vector<u8>,
    ports: vector<PortSchema>,
): OutputVariantSchema;

public native fun new(
    input_ports: vector<PortSchema>,
    output_variants: vector<OutputVariantSchema>,
): MetaSchema;

public native fun assert_valid_for_tool(self: &MetaSchema, is_offchain: bool);

/// Checks whether the One/Many variant matches the schema cardinality.
public native fun conforms_input_cardinality(
    schema: &PortSchema,
    value: &nexus_primitives::data::NexusData,
): bool;

/// Validates untrusted typed values against one port schema and constructs canonical data.
public native fun store_input(
    schema: &PortSchema,
    values: vector<nexus_primitives::data::NexusValue>,
): nexus_primitives::data::NexusData;

/// Checks canonical cardinality and semantic kind directly from stored values.
public native fun conforms_input_port(
    schema: &PortSchema,
    value: &nexus_primitives::data::NexusData,
): bool;

/// Checks complete canonical inputs in immutable schema order.
public native fun conforms_complete_input(
    self: &MetaSchema,
    values: &vector<nexus_primitives::data::NexusData>,
): bool;

/// Checks an exact ordered canonical output envelope.
public native fun conforms_raw_output(
    self: &MetaSchema,
    output: &nexus_primitives::tagged_output::TaggedOutput,
): bool;

/// Builds the canonical schema mismatch output through the typed active builder.
public native fun canonical_schema_mismatch_failure(): nexus_primitives::tagged_output::TaggedOutput;

public native fun port_commitment_one(value: &nexus_primitives::data::NexusValue): PortCommitment;

public native fun port_commitment_many(
    values: &vector<nexus_primitives::data::NexusValue>,
): PortCommitment;

/// Hashes canonical schema ordered name/commitment pairs shared by Nexus and on chain Tools.
public native fun input_hash(
    port_names: vector<vector<u8>>,
    commitments: vector<PortCommitment>,
): vector<u8>;

/// Validates complete persisted canonical inputs and derives the shared input hash.
public native fun input_hash_for_stored(
    self: &MetaSchema,
    values: &vector<nexus_primitives::data::NexusData>,
): vector<u8>;

public native fun input_ports(self: &MetaSchema): &vector<PortSchema>;

public native fun port_name(self: &PortSchema): &vector<u8>;

public native fun port_is_many(self: &PortSchema): bool;

public native fun find_input_port(
    self: &MetaSchema,
    name: &vector<u8>,
): std::option::Option<PortSchema>;

public native fun find_variant_port(
    self: &MetaSchema,
    variant_name: &vector<u8>,
    port_name: &vector<u8>,
): std::option::Option<PortSchema>;

public native fun value_kinds_compatible(from: &PortSchema, to: &PortSchema): bool;

public native fun failure_variant(): vector<u8>;

public native fun failure_port(): vector<u8>;
