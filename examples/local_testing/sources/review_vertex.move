module nexus_local_testing::review_vertex;

use nexus_interface::{
    authorization::AgentVertexAuthorization,
    meta_schema,
    onchain_tool_result::{Self as onchain_tool_result, OnchainToolResult}
};
use nexus_local_testing::application::{Self as application, ApplicationState};
use nexus_primitives::{authorization::ProvenValue, data, proof_of_uid::UIDRequirements};
use std::ascii::String as AsciiString;

//! The Nexus callback for the content review vertex.

#[error]
const EInputCommitmentMismatch: vector<u8> =
    b"The concrete review inputs do not match the Nexus input commitment";

/// One time witness for the onchain Tool module.
public struct REVIEW_VERTEX has drop {}

/// Declares the result schema generated during Tool registration.
public enum Output {
    Accepted {
        length: u64,
    },
    Rejected {
        minimum_length: u64,
    },
}

/// Returns the FQN registered for this onchain Tool.
public fun fqn(): AsciiString {
    application::review_vertex_fqn()
}

/// Returns the module name used during Tool registration.
public fun module_name(): AsciiString {
    b"review_vertex".to_ascii_string()
}

/// Executes the review vertex after Nexus releases its Agent authorization.
///
/// The first three arguments are injected by Nexus. The remaining arguments
/// are the ordered Tool inputs represented by DAG ports `0` and `1`.
public fun execute(
    authorization: ProvenValue<AgentVertexAuthorization>,
    requirements: UIDRequirements,
    result: OnchainToolResult,
    state: &mut ApplicationState,
    content: vector<u8>,
    ctx: &mut TxContext,
) {
    let mut requirements = requirements;
    let expected = onchain_tool_result::input_commitment(&result);
    let actual = input_commitment(state, &content);
    assert!(expected == actual, EInputCommitmentMismatch);

    let output = application::review_for_tool(
        state,
        authorization,
        requirements.proof(),
        expected,
        &content,
    );
    application::satisfy_review_requirement(state, &mut requirements);
    onchain_tool_result::finalize_and_share(result, requirements, output, ctx);
}

fun input_commitment(state: &ApplicationState, content: &vector<u8>): vector<u8> {
    let state_value = data::object_value(object::id(state));
    let content_values = application::byte_data_values(content);
    meta_schema::input_hash(
        vector[b"0", b"1"],
        vector[
            meta_schema::port_commitment_one(&state_value),
            meta_schema::port_commitment_many(&content_values),
        ],
    )
}

/// Computes the exact Tool input commitment for a callback fixture.
#[test_only]
public fun input_commitment_for_testing(
    state: &ApplicationState,
    content: &vector<u8>,
): vector<u8> {
    input_commitment(state, content)
}
