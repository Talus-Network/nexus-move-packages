/// Interface for the published [`nexus_interface::verifier`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_interface::verifier;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

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

public fun verifier_mode_none(): ToolVerifierMode {
    abort ELocalExecutionUnavailable
}

public fun verifier_mode_registered_key(): ToolVerifierMode {
    abort ELocalExecutionUnavailable
}

public fun verifier_mode_external(): ToolVerifierMode {
    abort ELocalExecutionUnavailable
}

public fun failure_evidence_kind_tool_evidence(): FailureEvidenceKind {
    abort ELocalExecutionUnavailable
}

public fun failure_evidence_kind_leader_evidence(): FailureEvidenceKind {
    abort ELocalExecutionUnavailable
}

public fun committed_result_evidence_is_leader_failure(
    evidence: &std::option::Option<FailureEvidenceKind>,
): bool {
    abort ELocalExecutionUnavailable
}

public fun committed_result_evidence_is_tool_failure(
    evidence: &std::option::Option<FailureEvidenceKind>,
): bool {
    abort ELocalExecutionUnavailable
}

public fun new_method_id(
    tool_id: sui::object::ID,
    package_id: sui::object::ID,
    module_name: std::ascii::String,
    function_name: std::ascii::String,
): VerifierMethodId {
    abort ELocalExecutionUnavailable
}

public fun method_tool_id(self: &VerifierMethodId): sui::object::ID {
    abort ELocalExecutionUnavailable
}

public fun support_registered_key(): ToolVerifierSupport {
    abort ELocalExecutionUnavailable
}

public fun support_external(method_id: VerifierMethodId): ToolVerifierSupport {
    abort ELocalExecutionUnavailable
}

public fun support_matches_mode(self: &ToolVerifierSupport, mode: ToolVerifierMode): bool {
    abort ELocalExecutionUnavailable
}

public fun support_method(self: &ToolVerifierSupport): std::option::Option<VerifierMethodId> {
    abort ELocalExecutionUnavailable
}

public fun leader_target_onchain(tool_witness_id: sui::object::ID): LeaderTarget {
    abort ELocalExecutionUnavailable
}

public fun leader_target_offchain(
    tool_id: sui::object::ID,
    verifier_witness_id: std::option::Option<sui::object::ID>,
): LeaderTarget {
    abort ELocalExecutionUnavailable
}

public fun leader_stamp_data(
    leader_cap_id: sui::object::ID,
    target: LeaderTarget,
): LeaderStampData {
    abort ELocalExecutionUnavailable
}

public fun leader_stamp_leader_cap_id(self: &LeaderStampData): sui::object::ID {
    abort ELocalExecutionUnavailable
}

public fun leader_stamp_target(self: &LeaderStampData): LeaderTarget {
    abort ELocalExecutionUnavailable
}

public fun leader_target_is_offchain(self: &LeaderTarget): bool {
    abort ELocalExecutionUnavailable
}

public fun leader_target_tool_id(self: &LeaderTarget): sui::object::ID {
    abort ELocalExecutionUnavailable
}

public fun leader_target_verifier_witness_id(
    self: &LeaderTarget,
): std::option::Option<sui::object::ID> {
    abort ELocalExecutionUnavailable
}

public fun registered_key_stamp_data(
    input_hash: vector<u8>,
    output_hash: vector<u8>,
    nonce: vector<u8>,
): RegisteredKeyStampData {
    abort ELocalExecutionUnavailable
}

public fun registered_key_stamp_input_hash(self: &RegisteredKeyStampData): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun registered_key_stamp_output_hash(self: &RegisteredKeyStampData): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun registered_key_stamp_nonce(self: &RegisteredKeyStampData): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun external_stamp_data(output_hash: vector<u8>): ExternalVerifierStampData {
    abort ELocalExecutionUnavailable
}

public fun external_stamp_output_hash(self: &ExternalVerifierStampData): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun registered_key_auxiliary(
    input_hash: vector<u8>,
    nonce: vector<u8>,
    leader_signature: vector<u8>,
    tool_signature: vector<u8>,
): RegisteredKeyAuxiliary {
    abort ELocalExecutionUnavailable
}

public fun auxiliary_input_hash(self: &RegisteredKeyAuxiliary): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun auxiliary_nonce(self: &RegisteredKeyAuxiliary): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun auxiliary_leader_signature(self: &RegisteredKeyAuxiliary): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun auxiliary_tool_signature(self: &RegisteredKeyAuxiliary): vector<u8> {
    abort ELocalExecutionUnavailable
}

/// Derives the nonce for one logical off chain Tool invocation.
public fun tool_invocation_nonce(
    execution_id: sui::object::ID,
    walk_index: u64,
    vertex_name: vector<u8>,
    iteration: u64,
): vector<u8> {
    abort ELocalExecutionUnavailable
}

/// Builds the exact nonce bound message signed by a RegisteredKey Tool.
public fun registered_key_tool_signature_message(
    leader_signature: vector<u8>,
    nonce: vector<u8>,
    output_hash: vector<u8>,
): vector<u8> {
    abort ELocalExecutionUnavailable
}

/// Hashes the canonical response body under the existing direct protocol domain.
public fun output_sha256(output: &nexus_primitives::tagged_output::TaggedOutput): vector<u8> {
    abort ELocalExecutionUnavailable
}

/// Builds an accepted verdict for a vertex configured as `None`.
public fun new_none(output: nexus_primitives::tagged_output::TaggedOutput): VerificationVerdict {
    abort ELocalExecutionUnavailable
}

/// Builds an External accept verdict and stamps the exact output hash.
public fun new_accept(
    worksheet: &mut nexus_primitives::proof_of_uid::ProofOfUID,
    output: nexus_primitives::tagged_output::TaggedOutput,
    witness_uid: &sui::object::UID,
): VerificationVerdict {
    abort ELocalExecutionUnavailable
}

/// Builds an External reject verdict and normalizes its optional reason.
public fun new_reject(
    worksheet: &mut nexus_primitives::proof_of_uid::ProofOfUID,
    output: nexus_primitives::tagged_output::TaggedOutput,
    witness_uid: &sui::object::UID,
    reason: std::option::Option<vector<u8>>,
): VerificationVerdict {
    abort ELocalExecutionUnavailable
}

/// Builds and stamps the verdict produced by the built in RegisteredKey verifier.
public fun new_registered_key_verdict(
    worksheet: &mut nexus_primitives::proof_of_uid::ProofOfUID,
    output: nexus_primitives::tagged_output::TaggedOutput,
    input_hash: vector<u8>,
    nonce: vector<u8>,
    witness_uid: &sui::object::UID,
    accepted: bool,
): VerificationVerdict {
    abort ELocalExecutionUnavailable
}

public fun verdict_witness_id(self: &VerificationVerdict): std::option::Option<sui::object::ID> {
    abort ELocalExecutionUnavailable
}

public fun verdict_decision(self: &VerificationVerdict): VerifierDecision {
    abort ELocalExecutionUnavailable
}

public fun verdict_output_hash(self: &VerificationVerdict): vector<u8> {
    abort ELocalExecutionUnavailable
}

public fun consume_verdict(
    self: VerificationVerdict,
): (
    nexus_primitives::tagged_output::TaggedOutput,
    std::option::Option<sui::object::ID>,
    VerifierDecision,
) {
    abort ELocalExecutionUnavailable
}

public fun decision_is_accept(self: &VerifierDecision): bool {
    abort ELocalExecutionUnavailable
}

public fun decision_reason(self: VerifierDecision): std::option::Option<vector<u8>> {
    abort ELocalExecutionUnavailable
}
