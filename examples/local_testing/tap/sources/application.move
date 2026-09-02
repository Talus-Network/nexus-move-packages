module nexus_local_testing::application;

use nexus_interface::meta_schema::{Self as meta_schema, MetaSchema};
use nexus_primitives::data::{Self as data, NexusData};
use nexus_primitives::tagged_output::{Self as tagged_output, TaggedOutput};

const CONTENT_PORT: vector<u8> = b"content";
const ACCEPTED_TAG: vector<u8> = b"accepted";
const REJECTED_TAG: vector<u8> = b"rejected";
const REASON_PORT: vector<u8> = b"reason";
const TOO_SHORT_REASON: vector<u8> = b"content is too short";

/// TAP owned state for the complete review flow.
public struct ReviewState has key, store {
    id: UID,
    minimum_length: u64,
    accepted_count: u64,
    rejected_count: u64,
}

/// Returns the immutable Nexus input and output contract for this TAP.
public fun schema(): MetaSchema {
    let data_kind = meta_schema::value_kind_data();
    meta_schema::new(
        vector[meta_schema::port_schema(copy CONTENT_PORT, false, data_kind)],
        vector[
            meta_schema::output_variant_schema(
                copy ACCEPTED_TAG,
                vector[meta_schema::port_schema(copy CONTENT_PORT, false, data_kind)],
            ),
            meta_schema::output_variant_schema(
                copy REJECTED_TAG,
                vector[meta_schema::port_schema(copy REASON_PORT, false, data_kind)],
            ),
        ],
    )
}

/// Creates TAP owned state with the supplied acceptance threshold.
public fun new(minimum_length: u64, ctx: &mut TxContext): ReviewState {
    ReviewState {
        id: object::new(ctx),
        minimum_length,
        accepted_count: 0,
        rejected_count: 0,
    }
}

/// Converts untrusted bytes into the canonical Nexus input for this TAP.
public fun prepare_input(schema: &MetaSchema, bytes: vector<u8>): NexusData {
    let port_name = copy CONTENT_PORT;
    let port = schema.find_input_port(&port_name).destroy_some();
    meta_schema::store_input(&port, vector[data::inline_data_value(bytes)])
}

/// Runs the complete TAP owned decision and returns canonical Nexus output.
public fun review(state: &mut ReviewState, input: &NexusData): TaggedOutput {
    let bytes = input.inline_data_bytes();
    if (bytes.is_none()) {
        state.rejected_count = state.rejected_count + 1;
        return rejection()
    };
    let bytes = bytes.destroy_some();
    if (bytes.length() < state.minimum_length) {
        state.rejected_count = state.rejected_count + 1;
        return rejection()
    };

    state.accepted_count = state.accepted_count + 1;
    tagged_output::new(copy ACCEPTED_TAG).with_named_payload(
        copy CONTENT_PORT,
        data::inline_data_value(bytes),
    )
}

/// Returns the number of accepted inputs.
public fun accepted_count(state: &ReviewState): u64 {
    state.accepted_count
}

/// Returns the number of rejected inputs.
public fun rejected_count(state: &ReviewState): u64 {
    state.rejected_count
}

/// Deletes test state after every resource assertion is complete.
#[test_only]
public fun destroy_for_testing(state: ReviewState) {
    let ReviewState {
        id,
        minimum_length: _,
        accepted_count: _,
        rejected_count: _,
    } = state;
    id.delete();
}

fun rejection(): TaggedOutput {
    tagged_output::new(copy REJECTED_TAG).with_named_payload(
        copy REASON_PORT,
        data::inline_data_value(copy TOO_SHORT_REASON),
    )
}
