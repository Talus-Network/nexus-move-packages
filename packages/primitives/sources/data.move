/// Interface for the published [`nexus_primitives::data`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_primitives::data;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// One execution value or a non empty ordered collection of execution values.
public enum NexusData has copy, drop, store {
    One {
        value: NexusValue,
    },
    Many {
        values: vector<NexusValue>,
    },
}

/// One typed execution value. Inline and Walrus backed values both have schema kind Data.
public enum NexusValue has copy, drop, store {
    Object {
        id: sui::object::ID,
    },
    InlineData {
        bytes: vector<u8>,
    },
    WalrusData {
        blob_id: vector<u8>,
        content_digest: vector<u8>,
    },
}

/// Creates a checked Object value.
public fun object_value(id: sui::object::ID): NexusValue {
    abort ELocalExecutionUnavailable
}

/// Creates checked inline Data.
public fun inline_data_value(bytes: vector<u8>): NexusValue {
    abort ELocalExecutionUnavailable
}

/// Creates checked digest bound Walrus Data.
public fun walrus_data_value(blob_id: vector<u8>, content_digest: vector<u8>): NexusValue {
    abort ELocalExecutionUnavailable
}

/// Creates one checked canonical value.
public fun one(value: NexusValue): NexusData {
    abort ELocalExecutionUnavailable
}

/// Creates a checked non empty homogeneous ordered value collection.
public fun many(values: vector<NexusValue>): NexusData {
    abort ELocalExecutionUnavailable
}

/// Splits Many into one canonical One per ordered value.
public fun split_many(data: NexusData): vector<NexusData> {
    abort ELocalExecutionUnavailable
}

/// Collects canonical One values into one canonical Many while preserving order.
public fun collect_ones(values: vector<NexusData>): NexusData {
    abort ELocalExecutionUnavailable
}

/// Returns whether the enum is Many.
public fun is_many(self: &NexusData): bool {
    abort ELocalExecutionUnavailable
}

/// Copies the ordered values while preserving One versus Many on the source value.
public fun values(self: &NexusData): vector<NexusValue> {
    abort ELocalExecutionUnavailable
}

/// Consumes the canonical value and returns its ordered values.
public fun into_values(self: NexusData): vector<NexusValue> {
    abort ELocalExecutionUnavailable
}

/// Returns inline bytes for One InlineData, or none for other value shapes.
public fun inline_data_bytes(self: &NexusData): std::option::Option<vector<u8>> {
    abort ELocalExecutionUnavailable
}

/// Returns ordered Object IDs, or none when any stored value is not Object.
public fun object_ids(self: &NexusData): std::option::Option<vector<sui::object::ID>> {
    abort ELocalExecutionUnavailable
}

/// Returns true when the value is Object.
public fun value_is_object(value: &NexusValue): bool {
    abort ELocalExecutionUnavailable
}

/// Returns true when the value is InlineData.
public fun value_is_inline_data(value: &NexusValue): bool {
    abort ELocalExecutionUnavailable
}

/// Returns true when every value is Object.
public fun values_are_object(values: &vector<NexusValue>): bool {
    abort ELocalExecutionUnavailable
}

/// Returns true when every value is inline or Walrus backed Data.
public fun values_are_data(values: &vector<NexusValue>): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the Tool visible content commitment of one checked value.
public fun value_content_commitment(value: &NexusValue): vector<u8> {
    abort ELocalExecutionUnavailable
}
