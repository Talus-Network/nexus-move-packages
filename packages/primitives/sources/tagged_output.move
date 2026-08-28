module nexus_primitives::tagged_output;

//! Interface for [`nexus_primitives::tagged_output`].
//!
//! Calls resolve to the published package.

/// Structured Tool output with ordered named canonical payloads.
public struct TaggedOutput has drop {
    tag: vector<u8>,
    named_payload: sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>,
}

/// Creates an empty tagged output.
public native fun new(tag: vector<u8>): TaggedOutput;

/// Adds one checked value under the supplied name.
public native fun with_named_payload(
    self: TaggedOutput,
    name: vector<u8>,
    value: nexus_primitives::data::NexusValue,
): TaggedOutput;

/// Adds checked Many values under the supplied name.
public native fun with_named_payload_many(
    self: TaggedOutput,
    name: vector<u8>,
    values: vector<nexus_primitives::data::NexusValue>,
): TaggedOutput;

/// Reconstructs trusted output already admitted through typed boundaries.
public native fun from_parts(
    tag: vector<u8>,
    named_payload: sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>,
): TaggedOutput;

public native fun tag(self: &TaggedOutput): &vector<u8>;

public native fun named_payload(
    self: &TaggedOutput,
): &sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>;

public native fun into_parts(
    self: TaggedOutput,
): (vector<u8>, sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>);
