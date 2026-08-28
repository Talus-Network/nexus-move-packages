module nexus_interface::onchain_tool_result;

//! Interface for [`nexus_interface::onchain_tool_result`].
//!
//! Calls resolve to the published package.

/// Durable result layout for a canonical on chain Tool invocation.
public struct OnchainToolResult has key {
    id: sui::object::UID,
}

/// Version one stored layout for [`OnchainToolResult`].
///
/// The stable [`OnchainToolResult`] cannot contain these fields because its
/// published layout must remain unchanged while stored data evolves.
public struct OnchainToolResultInnerV1 has store {
    execution_id: sui::object::ID,
    finalized: bool,
    stamps: std::option::Option<sui::vec_map::VecMap<sui::object::ID, vector<u8>>>,
    tag: std::option::Option<vector<u8>>,
    named_payload: std::option::Option<
        sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>,
    >,
    finalize_tx_digest: std::option::Option<vector<u8>>,
    finalize_recipient: std::option::Option<address>,
}

/// Private construction key for the result's canonical input commitment dynamic field.
public struct InputCommitmentKey has copy, drop, store {}

/// Private construction value for the result's canonical input commitment dynamic field.
public struct InputCommitment has store {
    bytes: vector<u8>,
}

/// Creates an owned empty result bound to the execution UID that created the worksheet.
public native fun new(
    execution_uid: &sui::object::UID,
    worksheet: &nexus_primitives::proof_of_uid::ProofOfUID,
    stamp: &nexus_interface::authorization::AgentVertexAuthorizationStamp,
    ctx: &mut sui::tx_context::TxContext,
): OnchainToolResult;

/// Finalizes and shares the result after every required UID has participated.
///
/// The result satisfies its own requirement before completing
/// [UIDRequirements]. This verifies that no requirements remain and binds them
/// to this exact result without restricting which caller may complete the operation.
public native fun finalize_and_share(
    result: OnchainToolResult,
    requirements: nexus_primitives::proof_of_uid::UIDRequirements,
    output: nexus_primitives::tagged_output::TaggedOutput,
    ctx: &mut sui::tx_context::TxContext,
);

/// Consumes and deletes the finalized result, returning the exact durable contents workflow needs.
public native fun consume(
    result: OnchainToolResult,
    execution_uid: &sui::object::UID,
): (
    sui::vec_map::VecMap<sui::object::ID, vector<u8>>,
    vector<u8>,
    sui::vec_map::VecMap<vector<u8>, nexus_primitives::data::NexusData>,
    vector<u8>,
    address,
);

/// The object ID of the result.
public native fun id(result: &OnchainToolResult): sui::object::ID;

/// Whether the result has been finalized by its tool.
public native fun is_finalized(result: &OnchainToolResult): bool;

/// The ID of the execution this result belongs to.
public native fun execution_id(result: &OnchainToolResult): sui::object::ID;

/// Returns the canonical resolved input commitment stamped for this Tool invocation.
public native fun input_commitment(result: &OnchainToolResult): vector<u8>;
