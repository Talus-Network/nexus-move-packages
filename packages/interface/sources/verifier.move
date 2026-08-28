module nexus_interface::verifier;

//! Interface for [`nexus_interface::verifier`].
//!
//! Calls resolve to the published package.

/// Verification selected by one offchain DAG vertex.
public enum ToolVerifierMode has copy, drop, store {
    None,
    RegisteredKey,
    External,
}

/// Concrete non generic external verifier target bound to one Tool.
public struct VerifierMethodId has copy, drop, store {
    tool_id: sui::object::ID,
    package_id: sui::object::ID,
    module_name: std::ascii::String,
    function_name: std::ascii::String,
}

/// Identifies terminal failure evidence produced by a Tool execution or verifier.
public enum FailureEvidenceKind has copy, drop, store {
    ToolEvidence,
    LeaderEvidence,
}

/// Exact data stored under the LeaderRegistry worksheet stamp.
public struct LeaderStampData has copy, drop, store {
    leader_cap_id: sui::object::ID,
    target: LeaderTarget,
}

/// The one verified mode globally supported by an off chain Tool.
public enum ToolVerifierSupport has copy, drop, store {
    RegisteredKey,
    External {
        method_id: VerifierMethodId,
    },
}

/// Hash bindings stored under the singleton RegisteredKey witness.
public struct RegisteredKeyStampData has copy, drop, store {
    input_hash: vector<u8>,
    output_hash: vector<u8>,
    nonce: vector<u8>,
}

/// The execution target authenticated by the leader stamp.
public enum LeaderTarget has copy, drop, store {
    Onchain {
        tool_witness_id: sui::object::ID,
    },
    Offchain {
        tool_id: sui::object::ID,
        verifier_witness_id: std::option::Option<sui::object::ID>,
    },
}

/// Output binding stored under an External verifier witness.
public struct ExternalVerifierStampData has copy, drop, store {
    output_hash: vector<u8>,
}

/// The only decision a Tool verifier may make.
public enum VerifierDecision has copy, drop, store {
    Accept,
    Reject {
        reason: std::option::Option<vector<u8>>,
    },
}

/// Strict BCS auxiliary for the built in two signature scheme.
public struct RegisteredKeyAuxiliary has copy, drop, store {
    input_hash: vector<u8>,
    nonce: vector<u8>,
    leader_signature: vector<u8>,
    tool_signature: vector<u8>,
}

/// Canonical BCS identity for one logical off chain Tool invocation.
public struct ToolInvocationNoncePreimage has copy, drop, store {
    execution_id: sui::object::ID,
    walk_index: u64,
    vertex_name: vector<u8>,
    iteration: u64,
}

/// One canonical port name/data pair in the RegisteredKey input transcript.
public struct CanonicalToolInput has copy, drop, store {
    port_name: vector<u8>,
    data: nexus_primitives::data::NexusData,
}

/// Same PTB hot potato produced by a verifier and consumed by offchain submission.
public struct VerificationVerdict {
    output: nexus_primitives::tagged_output::TaggedOutput,
    verifier_witness_id: std::option::Option<sui::object::ID>,
    decision: VerifierDecision,
}

public native fun verifier_mode_none(): ToolVerifierMode;

public native fun verifier_mode_registered_key(): ToolVerifierMode;

public native fun verifier_mode_external(): ToolVerifierMode;

public native fun failure_evidence_kind_tool_evidence(): FailureEvidenceKind;

public native fun failure_evidence_kind_leader_evidence(): FailureEvidenceKind;

public native fun committed_result_evidence_is_leader_failure(
    evidence: &std::option::Option<FailureEvidenceKind>,
): bool;

public native fun committed_result_evidence_is_tool_failure(
    evidence: &std::option::Option<FailureEvidenceKind>,
): bool;

public native fun new_method_id(
    tool_id: sui::object::ID,
    package_id: sui::object::ID,
    module_name: std::ascii::String,
    function_name: std::ascii::String,
): VerifierMethodId;

public native fun method_tool_id(self: &VerifierMethodId): sui::object::ID;

public native fun support_registered_key(): ToolVerifierSupport;

public native fun support_external(method_id: VerifierMethodId): ToolVerifierSupport;

public native fun support_matches_mode(self: &ToolVerifierSupport, mode: ToolVerifierMode): bool;

public native fun support_method(self: &ToolVerifierSupport): std::option::Option<VerifierMethodId>;

public native fun leader_target_onchain(tool_witness_id: sui::object::ID): LeaderTarget;

public native fun leader_target_offchain(
    tool_id: sui::object::ID,
    verifier_witness_id: std::option::Option<sui::object::ID>,
): LeaderTarget;

public native fun leader_stamp_data(
    leader_cap_id: sui::object::ID,
    target: LeaderTarget,
): LeaderStampData;

public native fun leader_stamp_leader_cap_id(self: &LeaderStampData): sui::object::ID;

public native fun leader_stamp_target(self: &LeaderStampData): LeaderTarget;

public native fun leader_target_is_offchain(self: &LeaderTarget): bool;

public native fun leader_target_tool_id(self: &LeaderTarget): sui::object::ID;

public native fun leader_target_verifier_witness_id(
    self: &LeaderTarget,
): std::option::Option<sui::object::ID>;

public native fun registered_key_stamp_data(
    input_hash: vector<u8>,
    output_hash: vector<u8>,
    nonce: vector<u8>,
): RegisteredKeyStampData;

public native fun registered_key_stamp_input_hash(self: &RegisteredKeyStampData): vector<u8>;

public native fun registered_key_stamp_output_hash(self: &RegisteredKeyStampData): vector<u8>;

public native fun registered_key_stamp_nonce(self: &RegisteredKeyStampData): vector<u8>;

public native fun external_stamp_data(output_hash: vector<u8>): ExternalVerifierStampData;

public native fun external_stamp_output_hash(self: &ExternalVerifierStampData): vector<u8>;

public native fun registered_key_auxiliary(
    input_hash: vector<u8>,
    nonce: vector<u8>,
    leader_signature: vector<u8>,
    tool_signature: vector<u8>,
): RegisteredKeyAuxiliary;

public native fun auxiliary_input_hash(self: &RegisteredKeyAuxiliary): vector<u8>;

public native fun auxiliary_nonce(self: &RegisteredKeyAuxiliary): vector<u8>;

public native fun auxiliary_leader_signature(self: &RegisteredKeyAuxiliary): vector<u8>;

public native fun auxiliary_tool_signature(self: &RegisteredKeyAuxiliary): vector<u8>;

/// Derives the nonce for one logical off chain Tool invocation.
public native fun tool_invocation_nonce(
    execution_id: sui::object::ID,
    walk_index: u64,
    vertex_name: vector<u8>,
    iteration: u64,
): vector<u8>;

/// Builds the exact nonce bound message signed by a RegisteredKey Tool.
public native fun registered_key_tool_signature_message(
    leader_signature: vector<u8>,
    nonce: vector<u8>,
    output_hash: vector<u8>,
): vector<u8>;

/// Hashes the canonical response body under the existing direct protocol domain.
public native fun output_sha256(output: &nexus_primitives::tagged_output::TaggedOutput): vector<u8>;

/// Builds an accepted verdict for a vertex configured as `None`.
public native fun new_none(
    output: nexus_primitives::tagged_output::TaggedOutput,
): VerificationVerdict;

/// Builds an External accept verdict and stamps the exact output hash.
public native fun new_accept(
    worksheet: &mut nexus_primitives::proof_of_uid::ProofOfUID,
    output: nexus_primitives::tagged_output::TaggedOutput,
    witness_uid: &sui::object::UID,
): VerificationVerdict;

/// Builds an External reject verdict and normalizes its optional reason.
public native fun new_reject(
    worksheet: &mut nexus_primitives::proof_of_uid::ProofOfUID,
    output: nexus_primitives::tagged_output::TaggedOutput,
    witness_uid: &sui::object::UID,
    reason: std::option::Option<vector<u8>>,
): VerificationVerdict;

/// Builds and stamps the verdict produced by the built in RegisteredKey verifier.
public native fun new_registered_key_verdict(
    worksheet: &mut nexus_primitives::proof_of_uid::ProofOfUID,
    output: nexus_primitives::tagged_output::TaggedOutput,
    input_hash: vector<u8>,
    nonce: vector<u8>,
    witness_uid: &sui::object::UID,
    accepted: bool,
): VerificationVerdict;

public native fun verdict_witness_id(
    self: &VerificationVerdict,
): std::option::Option<sui::object::ID>;

public native fun verdict_decision(self: &VerificationVerdict): VerifierDecision;

public native fun verdict_output_hash(self: &VerificationVerdict): vector<u8>;

public native fun consume_verdict(
    self: VerificationVerdict,
): (
    nexus_primitives::tagged_output::TaggedOutput,
    std::option::Option<sui::object::ID>,
    VerifierDecision,
);

public native fun decision_is_accept(self: &VerifierDecision): bool;

public native fun decision_reason(self: VerifierDecision): std::option::Option<vector<u8>>;
