module nexus_primitives::data;

//! Interface for [`nexus_primitives::data`].
//!
//! Calls resolve to the published package.

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
public native fun object_value(id: sui::object::ID): NexusValue;

/// Creates checked inline Data.
public native fun inline_data_value(bytes: vector<u8>): NexusValue;

/// Creates checked digest bound Walrus Data.
public native fun walrus_data_value(blob_id: vector<u8>, content_digest: vector<u8>): NexusValue;

/// Creates one checked canonical value.
public native fun one(value: NexusValue): NexusData;

/// Creates a checked non empty homogeneous ordered value collection.
public native fun many(values: vector<NexusValue>): NexusData;

/// Splits Many into one canonical One per ordered value.
public native fun split_many(data: NexusData): vector<NexusData>;

/// Collects canonical One values into one canonical Many while preserving order.
public native fun collect_ones(values: vector<NexusData>): NexusData;

/// Returns whether the enum is Many.
public native fun is_many(self: &NexusData): bool;

/// Copies the ordered values while preserving One versus Many on the source value.
public native fun values(self: &NexusData): vector<NexusValue>;

/// Consumes the canonical value and returns its ordered values.
public native fun into_values(self: NexusData): vector<NexusValue>;

/// Returns inline bytes for One InlineData, or none for other value shapes.
public native fun inline_data_bytes(self: &NexusData): std::option::Option<vector<u8>>;

/// Returns ordered Object IDs, or none when any stored value is not Object.
public native fun object_ids(self: &NexusData): std::option::Option<vector<sui::object::ID>>;

/// Returns true when the value is Object.
public native fun value_is_object(value: &NexusValue): bool;

/// Returns true when the value is InlineData.
public native fun value_is_inline_data(value: &NexusValue): bool;

/// Returns true when every value is Object.
public native fun values_are_object(values: &vector<NexusValue>): bool;

/// Returns true when every value is inline or Walrus backed Data.
public native fun values_are_data(values: &vector<NexusValue>): bool;

/// Returns the Tool visible content commitment of one checked value.
public native fun value_content_commitment(value: &NexusValue): vector<u8>;
