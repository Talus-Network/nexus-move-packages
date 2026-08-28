module nexus_interface::authorization;

//! Interface for [`nexus_interface::authorization`].
//!
//! Calls resolve to the published package.

/// Scheduled skill level authorization object.
///
/// Scheduled tasks store this keyed object as their durable authorization
/// component. It is intentionally non copy because it owns the copyable
/// per vertex grants that are copied into each scheduled execution.
public struct AgentSkillAuthorization has key, store {
    id: sui::object::UID,
}

/// Version one stored layout for [`AgentSkillAuthorization`].
///
/// The stable [`AgentSkillAuthorization`] cannot contain these fields because
/// its published layout must remain unchanged while stored data evolves.
public struct AgentSkillAuthorizationInnerV1 has store {
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    vertex_authorization_grants: vector<
        nexus_primitives::authorization::Grant<AgentVertexAuthorization>,
    >,
}

/// Per vertex DAG authorization payload.
///
/// Agent identity and recipient binding are enforced by primitive provenance.
public struct AgentVertexAuthorization has copy, drop, store {
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    dag_id: sui::object::ID,
    vertex: std::ascii::String,
    task_id: sui::object::ID,
}

/// Full context bound to a worksheet, used to check that a vertex authorization matches an execution.
public struct AgentVertexAuthorizationContext has copy, drop, store {
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    execution_id: sui::object::ID,
    vertex: std::ascii::String,
    task_id: sui::object::ID,
}

/// Execution stamp that binds vertex authorization context to exact Tool inputs.
///
/// [`AgentVertexAuthorizationContext`] cannot carry the input commitment without changing its
/// published layout, so both values live in this separate worksheet stamp payload.
public struct AgentVertexAuthorizationStamp has copy, drop, store {
    context: AgentVertexAuthorizationContext,
    input_commitment: vector<u8>,
}

/// Returns the skill ID of the vertex authorization.
public native fun agent_vertex_authorization_skill_id(self: &AgentVertexAuthorization): u64;

/// Returns the interface version of the vertex authorization.
public native fun agent_vertex_authorization_interface_version(
    self: &AgentVertexAuthorization,
): nexus_interface::version::InterfaceVersion;

/// Returns the DAG ID of the vertex authorization.
public native fun agent_vertex_authorization_dag_id(
    self: &AgentVertexAuthorization,
): sui::object::ID;

/// Returns the vertex of the vertex authorization.
public native fun agent_vertex_authorization_vertex(
    self: &AgentVertexAuthorization,
): std::ascii::String;

/// Returns the Task bound to the vertex authorization.
public native fun agent_vertex_authorization_task_id(
    self: &AgentVertexAuthorization,
): sui::object::ID;

/// Constructs the exact context bound to a vertex authorization worksheet stamp.
public native fun agent_vertex_authorization_context(
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    execution_id: sui::object::ID,
    vertex: std::ascii::String,
    task_id: sui::object::ID,
): AgentVertexAuthorizationContext;

/// Encodes a vertex authorization context into its BCS byte representation.
public native fun encode_agent_vertex_authorization_context(
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    execution_id: sui::object::ID,
    vertex: std::ascii::String,
    task_id: sui::object::ID,
): vector<u8>;

/// Constructs the execution stamp stored on a Tool result worksheet.
public native fun agent_vertex_authorization_stamp(
    context: AgentVertexAuthorizationContext,
    input_commitment: vector<u8>,
): AgentVertexAuthorizationStamp;

/// Returns the canonical 32 byte input commitment carried by the stamp.
public native fun agent_vertex_authorization_stamp_input_commitment(
    stamp: &AgentVertexAuthorizationStamp,
): vector<u8>;

/// Authenticates the stamp against the worksheet and returns its input commitment.
public native fun worksheet_input_commitment(
    worksheet: &nexus_primitives::proof_of_uid::ProofOfUID,
    stamp: &AgentVertexAuthorizationStamp,
): vector<u8>;

/// Returns true only if the vertex authorization derives the exact execution stamp on the worksheet.
public native fun authorization_matches_worksheet(
    authorization: &AgentVertexAuthorization,
    by: sui::object::ID,
    worksheet: &nexus_primitives::proof_of_uid::ProofOfUID,
    stamp: &AgentVertexAuthorizationStamp,
): bool;

/// Consumes an execution proven vertex authorization for the matching worksheet recipient.
public native fun consume_verified_for_worksheet_as_recipient(
    authorization: nexus_primitives::authorization::ProvenValue<AgentVertexAuthorization>,
    worksheet: &nexus_primitives::proof_of_uid::ProofOfUID,
    recipient: &sui::object::UID,
    input_commitment: vector<u8>,
): bool;

/// Returns the agent ID of the skill authorization.
public native fun agent_skill_authorization_agent_id(
    self: &AgentSkillAuthorization,
): sui::object::ID;

/// Returns the skill ID of the skill authorization.
public native fun agent_skill_authorization_skill_id(self: &AgentSkillAuthorization): u64;

/// Returns the interface version of the skill authorization.
public native fun agent_skill_authorization_interface_version(
    self: &AgentSkillAuthorization,
): nexus_interface::version::InterfaceVersion;

/// Returns the number of vertex authorization grants held by the skill authorization.
public native fun agent_skill_authorization_grant_count(self: &AgentSkillAuthorization): u64;

/// Returns a copy of the vertex authorization grant at the given index.
public native fun copy_agent_skill_authorization_vertex_grant(
    self: &AgentSkillAuthorization,
    index: u64,
): nexus_primitives::authorization::Grant<AgentVertexAuthorization>;

/// Destroys a Task authorization after no execution can consume its grants.
public native fun destroy_agent_skill_authorization(self: AgentSkillAuthorization);
