/// Interface for the published [`nexus_registry::agent_registry`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_registry::agent_registry;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Current relationship between a proposal and one registered skill contract.
///
/// [`Current`] means admission may continue. [`Inactive`] is temporary and
/// leaves the proposal pending. [`Stale`] and [`Missing`] cannot become valid
/// without changing the immutable proposal.
public enum SkillContractState has copy, drop {
    Current,
    Inactive,
    Stale,
    Missing,
}

/// Shared registry of Talus agents and their skills, keyed by agent object ID.
public struct AgentRegistry has key {
    id: sui::object::UID,
}

/// Version one stored layout for [`AgentRegistry`].
public struct AgentRegistryInnerV1 has store {
    agents: sui::table::Table<sui::object::ID, AgentRecord>,
}

/// Dynamic field key under which the registry stores its [DefaultDagExecutor].
public struct DefaultDagExecutorFieldKey has copy, drop, store {}

/// Registry owned default DAG executor for runtime selected DAG execution.
///
/// The value embeds the actual default agent object and is stored as a dynamic
/// field under `AgentRegistry`, making the registry the physical owner of the
/// default executor surface.
public struct DefaultDagExecutor has store {
    agent: nexus_interface::agent::Agent,
    skill_id: u64,
}

/// Registry record for one Talus agent.
public struct AgentRecord has store {
    active: bool,
    skills: sui::table::Table<u64, SkillRecord>,
}

/// Registry owned metadata for a skill under an agent.
///
/// The skill ID is allocated from the agent owned `Agent`. The registry keeps
/// a skill table so callers can recover skill requirements without scanning dynamic
/// children under the `Agent`.
public struct SkillRecord has copy, drop, store {
    description: vector<u8>,
    active: bool,
    dag_binding: nexus_interface::agent::SkillDagBinding,
    requirements: nexus_interface::agent::SkillRequirement,
    current_interface_revision: nexus_interface::version::InterfaceVersion,
}

/// Emitted when a skill's interface revision advances (binding or policy change).
public struct SkillContractRevisionedEvent has copy, drop {
    agent_id: sui::object::ID,
    skill_id: u64,
    current_interface_revision: nexus_interface::version::InterfaceVersion,
    dag_binding: nexus_interface::agent::SkillDagBinding,
    requirements: nexus_interface::agent::SkillRequirement,
}

/// Emitted when a new skill is registered under an agent.
public struct SkillRegisteredEvent has copy, drop {
    agent_id: sui::object::ID,
    skill_id: u64,
    dag_id: address,
    dag_binding: nexus_interface::agent::SkillDagBinding,
}

/// Emitted when the registry owned default DAG executor target is set or updated.
public struct DefaultDagExecutorUpdatedEvent has copy, drop {
    agent_id: sui::object::ID,
    skill_id: u64,
}

/// Shares the canonical Agent registry for network use.
///
/// Once shared, mutations are guarded by mutable `Agent` custody rather than
/// object ownership of the registry itself.
public fun share_registry(registry: AgentRegistry) {
    abort ELocalExecutionUnavailable
}

/// Create a Talus agent record and its interface identity object.
///
/// The returned mutable `Agent` object becomes the custody handle for later
/// lifecycle and skill revision updates.
public fun create_agent(
    registry: &mut AgentRegistry,
    ctx: &mut sui::tx_context::TxContext,
): nexus_interface::agent::Agent {
    abort ELocalExecutionUnavailable
}

/// Attach an embedded TAP agent identity to the registry.
///
/// This lets examples keep custody of the `Agent` object inside their own
/// state while still using the standard registry for skill discovery and execution resolution.
public fun attach_embedded_agent(
    registry: &mut AgentRegistry,
    agent: &mut nexus_interface::agent::Agent,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Register a pinned DAG skill.
///
/// The caller must have mutable custody of the agent. Revision 1 is stored as
/// the current skill; historical revision lookup belongs to emitted events.
public fun register_skill(
    registry: &mut AgentRegistry,
    agent: &mut nexus_interface::agent::Agent,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    dag: &nexus_interface::dag::DAG,
    description: vector<u8>,
    input_commitment: vector<u8>,
    payment_policy: nexus_interface::payment::SkillPaymentPolicy,
    schedule_policy: nexus_interface::agent::SkillSchedulePolicy,
    fixed_tools: vector<nexus_interface::agent::FixedTool>,
    ctx: &mut sui::tx_context::TxContext,
): u64 {
    abort ELocalExecutionUnavailable
}

/// Bootstrap the standard default runtime selected DAG skill for deployment.
///
/// This is the only public default bootstrap entry. It creates one default
/// agent, allocates one runtime selected skill, stores revision 1 as the current
/// skill, and records that `(agent, skill)` in the registry default
/// executor. The fixed default floor is intentionally narrow:
/// user funded zero cap payments, a once schedule, no fixed tools, and active
/// revision 1.
public fun bootstrap_default_runtime_dag_skill_for_deployment(
    registry: &mut AgentRegistry,
    ctx: &mut sui::tx_context::TxContext,
): (sui::object::ID, u64) {
    abort ELocalExecutionUnavailable
}

/// Return requirements for the currently active interface revision.
public fun get_skill_requirements(
    registry: &AgentRegistry,
    agent: &nexus_interface::agent::Agent,
    skill_id: u64,
): nexus_interface::agent::SkillRequirement {
    abort ELocalExecutionUnavailable
}

/// Build the scheduled skill components (authorization and payment reserve) for the
/// registry owned default DAG executor.
///
/// Aborts with [EAgentNotFound] if the stored default executor agent does not match its
/// recorded ID.
public fun new_default_task_components(
    registry: &AgentRegistry,
    task_id: sui::object::ID,
    dag_id: sui::object::ID,
    prepayment: sui::coin::Coin<sui::sui::SUI>,
    refund_recipient: address,
    occurrence_budget_mist: u64,
    ctx: &mut sui::tx_context::TxContext,
): (
    nexus_interface::authorization::AgentSkillAuthorization,
    nexus_interface::payment::TaskPaymentReserve,
    sui::object::ID,
    u64,
) {
    abort ELocalExecutionUnavailable
}

/// Withdraw `amount` from an agent's payment vault to a returned coin.
///
/// Aborts with [EAgentNotFound] if the agent is not registered.
public fun withdraw_agent_payment_vault(
    registry: &AgentRegistry,
    agent: &mut nexus_interface::agent::Agent,
    amount: u64,
    ctx: &mut sui::tx_context::TxContext,
): sui::coin::Coin<sui::sui::SUI> {
    abort ELocalExecutionUnavailable
}

/// Returns the agent ID of the registry owned default DAG executor.
///
/// Aborts with [EDefaultDagExecutorMissing] if no default executor has been bootstrapped.
public fun default_dag_executor_agent_id_from_registry(registry: &AgentRegistry): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the skill ID of the registry owned default DAG executor.
///
/// Aborts with [EDefaultDagExecutorMissing] if no default executor has been bootstrapped.
public fun default_dag_executor_skill_id_from_registry(registry: &AgentRegistry): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns whether the given `(agent_id, skill_id)` is the registry owned default DAG executor.
///
/// Aborts with [EDefaultDagExecutorMissing] if no default executor has been bootstrapped.
public fun is_default_dag_executor_skill(
    registry: &AgentRegistry,
    agent_id: sui::object::ID,
    skill_id: u64,
): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the pinned DAG ID for a skill, or `none` if the skill is runtime selected.
///
/// Aborts with [ESkillNotFound] if the agent has no such skill.
public fun skill_pinned_dag_id_for_skill(
    registry: &AgentRegistry,
    agent_id: sui::object::ID,
    skill_id: u64,
): std::option::Option<address> {
    abort ELocalExecutionUnavailable
}

/// Returns the requirements for an active skill under an active agent.
///
/// Aborts with [ESkillNotFound] if the skill does not exist, or [EActiveEndpointNotFound]
/// if the agent or skill is inactive.
public fun skill_requirements_for_skill(
    registry: &AgentRegistry,
    agent_id: sui::object::ID,
    skill_id: u64,
): nexus_interface::agent::SkillRequirement {
    abort ELocalExecutionUnavailable
}

/// Returns the interface revision, payment policy, and schedule policy for an active skill.
///
/// Aborts with [ESkillNotFound] if the skill does not exist, or [EActiveEndpointNotFound]
/// if the agent or skill is inactive.
public fun get_agent_skill_record(
    registry: &AgentRegistry,
    agent_id: sui::object::ID,
    skill_id: u64,
): (
    nexus_interface::version::InterfaceVersion,
    nexus_interface::payment::SkillPaymentPolicy,
    nexus_interface::agent::SkillSchedulePolicy,
) {
    abort ELocalExecutionUnavailable
}

/// Classifies an immutable proposal against current Agent Registry state.
///
/// This function never aborts for a missing or inactive Agent or skill. That
/// lets current Scheduler code commit a proven rejection instead of rolling
/// it back through an abort.
public fun classify_skill_contract(
    registry: &AgentRegistry,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_revision: nexus_interface::version::InterfaceVersion,
    dag_id: sui::object::ID,
): SkillContractState {
    abort ELocalExecutionUnavailable
}

/// Returns whether a skill contract classification permits admission.
public fun skill_contract_is_current(state: SkillContractState): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether a skill contract may become admissible without changing the proposal.
public fun skill_contract_is_inactive(state: SkillContractState): bool {
    abort ELocalExecutionUnavailable
}

/// Resolves the DAG ID an execution config should run, honoring the skill's binding.
///
/// For runtime selected skills, aborts with [EDagSelectionRequired] if no DAG is selected;
/// for pinned skills, aborts with [EDagSelectionRedundant] if a DAG is selected. Aborts with
/// [ESkillNotFound] or [EActiveEndpointNotFound] if the skill is missing or inactive.
public fun resolve_agent_execution_config_dag(
    registry: &AgentRegistry,
    config: &nexus_interface::agent::AgentExecutionConfig,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Resolves caller intent into one durable execution target.
public fun resolve_execution_spec(
    registry: &AgentRegistry,
    config: nexus_interface::agent::AgentExecutionConfig,
): (
    nexus_interface::agent::ExecutionSpec,
    sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
    nexus_interface::payment::SkillPaymentPolicy,
    nexus_interface::agent::SkillSchedulePolicy,
) {
    abort ELocalExecutionUnavailable
}

/// Returns the DAG binding for a skill under an agent.
///
/// Aborts with [ESkillNotFound] if the agent has no such skill.
public fun skill_dag_binding(
    registry: &AgentRegistry,
    agent: &nexus_interface::agent::Agent,
    skill_id: u64,
): nexus_interface::agent::SkillDagBinding {
    abort ELocalExecutionUnavailable
}

/// Activate or deactivate a skill.
///
/// Aborts with [EAgentNotFound] if the agent is not registered.
public fun set_skill_active(
    registry: &mut AgentRegistry,
    agent: &mut nexus_interface::agent::Agent,
    skill_id: u64,
    active: bool,
) {
    abort ELocalExecutionUnavailable
}

/// Activate or deactivate an agent.
///
/// Aborts with [EAgentNotFound] if the agent is not registered.
public fun set_agent_active(
    registry: &mut AgentRegistry,
    agent: &mut nexus_interface::agent::Agent,
    active: bool,
) {
    abort ELocalExecutionUnavailable
}

/// Replace a skill's description.
///
/// Aborts with [EAgentNotFound] if the agent is not registered.
public fun update_skill_description(
    registry: &mut AgentRegistry,
    agent: &mut nexus_interface::agent::Agent,
    skill_id: u64,
    description: vector<u8>,
) {
    abort ELocalExecutionUnavailable
}

/// Repoint a skill to a new pinned DAG, advancing its interface revision.
///
/// Aborts with [EAgentNotFound] if the agent is not registered.
public fun update_dag(
    registry: &mut AgentRegistry,
    agent: &mut nexus_interface::agent::Agent,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    dag: &nexus_interface::dag::DAG,
    skill_id: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Replace a skill's payment and schedule policies, advancing its interface revision.
///
/// Aborts with [EAgentNotFound] if the agent is not registered.
public fun update_skill_policies(
    registry: &mut AgentRegistry,
    agent: &mut nexus_interface::agent::Agent,
    skill_id: u64,
    payment_policy: nexus_interface::payment::SkillPaymentPolicy,
    schedule_policy: nexus_interface::agent::SkillSchedulePolicy,
) {
    abort ELocalExecutionUnavailable
}
