/// Interface for the published [`nexus_primitives::tagged_output`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_primitives::tagged_output;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Structured Tool output with ordered named canonical payloads.
public struct TaggedOutput has drop {
    tag: vector<u8>,
    named_payload: sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>,
}

/// Creates an empty tagged output.
public fun new(tag: vector<u8>): TaggedOutput {
    abort ELocalExecutionUnavailable
}

/// Adds one checked value under the supplied name.
public fun with_named_payload(
    self: TaggedOutput,
    name: vector<u8>,
    value: nexus_primitives::data::NexusValue,
): TaggedOutput {
    abort ELocalExecutionUnavailable
}

/// Adds checked Many values under the supplied name.
public fun with_named_payload_many(
    self: TaggedOutput,
    name: vector<u8>,
    values: vector<nexus_primitives::data::NexusValue>,
): TaggedOutput {
    abort ELocalExecutionUnavailable
}

/// Reconstructs trusted output already admitted through typed boundaries.
public fun from_parts(
    tag: vector<u8>,
    named_payload: sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>,
): TaggedOutput {
    abort ELocalExecutionUnavailable
}

public fun tag(self: &TaggedOutput): &vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun named_payload(
    self: &TaggedOutput,
): &sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData> {
    abort ELocalExecutionUnavailable
}

public fun into_parts(
    self: TaggedOutput,
): (vector<u8>, sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>) {
    abort ELocalExecutionUnavailable
}
