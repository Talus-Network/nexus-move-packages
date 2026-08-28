module nexus_interface::agent;

//! Interface for [`nexus_interface::agent`].
//!
//! Calls resolve to the published package.

/// Binding between a TAP skill and DAG selection.
///
/// Ordinary skills pin one DAG. The default skill may use `RuntimeSelected`,
/// but the selected DAG must still be committed in execution evidence.
public enum SkillDagBinding has copy, drop, store {
    Pinned {
        dag_id: address,
    },
    RuntimeSelected,
}

/// Keyed on chain Talus agent identity object.
///
/// Custody of this object controls access to agent owned dynamic object
/// children such as the standard payment vault.
public struct Agent has key, store {
    id: sui::object::UID,
}

/// Selects either a registered Agent skill or the registry owned default Agent for one DAG execution.
public enum ExecutionSelection has copy, drop, store {
    AgentSkill {
        agent_id: sui::object::ID,
        skill_id: u64,
        selected_dag: std::option::Option<sui::object::ID>,
    },
    DefaultAgent {
        dag_id: sui::object::ID,
    },
}

/// Version one stored layout for [`Agent`].
///
/// The stable [`Agent`] cannot contain these fields because its published
/// layout must remain unchanged while stored data evolves.
public struct AgentInnerV1 has store {
    next_skill_id: u64,
    registry_id: std::option::Option<sui::object::ID>,
}

/// Scheduling limits committed by one skill revision.
public enum SkillSchedulePolicy has copy, drop, store {
    Once,
    Recurring {
        min_interval_ms: u64,
        max_occurrences: std::option::Option<u64>,
    },
}

/// Caller authored runtime intent for DAG execution through an agent selection.
public struct AgentExecutionConfig has copy, drop, store {
    selection: ExecutionSelection,
    network: sui::object::ID,
    entry_group: nexus_interface::graph::EntryGroup,
    inputs: sui::vec_map::VecMap<
        nexus_interface::graph::Vertex,
        sui::vec_map::VecMap<nexus_interface::graph::InputPort, nexus_primitives::data::NexusData>,
    >,
    invoker: address,
    authorization_bindings: sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
}

/// Dynamic object field key for the standard agent payment vault.
public struct AgentVaultFieldKey has copy, drop, store {}

/// Registry verified tool identity that must remain present in the bound DAG.
public struct FixedTool has copy, drop, store {
    tool_registry_id: sui::object::ID,
    tool_fqn: std::ascii::String,
}

/// Skill requirements committed by the current skill revision.
public struct SkillRequirement has copy, drop, store {
    input_commitment: vector<u8>,
    payment_policy: nexus_interface::payment::SkillPaymentPolicy,
    schedule_policy: SkillSchedulePolicy,
    fixed_tools: vector<FixedTool>,
}

/// Resolved execution target retained by a durable scheduler Task.
///
/// [`AgentExecutionConfig`] is caller intent. [`ExecutionSpec`] is the
/// registry validated target after agent, skill, DAG, and interface resolution.
public struct ExecutionSpec has copy, drop, store {
    dag_id: sui::object::ID,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    network: sui::object::ID,
    entry_group: nexus_interface::graph::EntryGroup,
    inputs: sui::vec_map::VecMap<
        nexus_interface::graph::Vertex,
        sui::vec_map::VecMap<nexus_interface::graph::InputPort, nexus_primitives::data::NexusData>,
    >,
    invoker: address,
}

/// Standard balance holder for agent funded TAP execution.
///
/// The vault is created with every agent as a dynamic object child. Deposits
/// are permissionless, while withdrawals go through registry mediated agent
/// custody. Active [`payment_interface::ExecutionPayment`] values split their
/// funds out of the vault at creation, so the stored balance is fully spendable.
public struct AgentPaymentVault has key, store {
    id: sui::object::UID,
}

/// Version one stored layout for [`AgentPaymentVault`].
///
/// The stable [`AgentPaymentVault`] cannot contain these fields because its
/// published layout must remain unchanged while stored data evolves.
public struct AgentPaymentVaultInnerV1 has store {
    agent_id: sui::object::ID,
    available_balance: sui::balance::Balance<sui::sui::SUI>,
}

/// Emitted when a new agent identity and its payment vault are created.
public struct AgentCreatedEvent has copy, drop {
    agent_id: sui::object::ID,
    vault_id: address,
}

/// Create the on chain identity object for one Talus agent.
///
/// The function initializes the Agent payment vault.
/// Registry code is responsible for checking mutable agent custody
/// before exposing this identity as an agent record.
public native fun create_agent_identity(ctx: &mut sui::tx_context::TxContext): Agent;

/// Allocate the next agent local skill index.
///
/// Only code with mutable access to `Agent` can allocate, preventing external
/// callers from forging skill IDs for an agent they do not control.
public native fun allocate_skill_id(agent: &mut Agent): u64;

/// Validate that the caller is the registry bound to this agent.
public native fun assert_agent_registry_authorized(
    agent: &Agent,
    registry_authority: &sui::object::UID,
);

/// Bind an agent identity to the registry that controls its skill metadata.
///
/// Only code that can borrow the registry UID later can register or update skills.
public native fun bind_agent_registry(agent: &mut Agent, registry_id: &sui::object::UID);

/// Returns the next skill index that would be allocated for this agent.
public native fun agent_next_skill_id(agent: &Agent): u64;

/// Returns the payment policy committed by these skill requirements.
public native fun requirements_payment_policy(
    requirements: SkillRequirement,
): nexus_interface::payment::SkillPaymentPolicy;

/// Returns the schedule policy committed by these skill requirements.
public native fun requirements_schedule_policy(requirements: SkillRequirement): SkillSchedulePolicy;

/// Returns the input commitment bytes committed by these skill requirements.
public native fun requirements_input_commitment(requirements: SkillRequirement): vector<u8>;

/// Returns the fixed tools that must remain present in the bound DAG.
public native fun requirements_fixed_tools(requirements: SkillRequirement): vector<FixedTool>;

/// Constructs a fixed tool identity from its registry ID and fully qualified name.
public native fun fixed_tool(
    tool_registry_id: sui::object::ID,
    tool_fqn: std::ascii::String,
): FixedTool;

/// Returns the tool registry ID of a fixed tool.
public native fun fixed_tool_registry_id(tool: FixedTool): sui::object::ID;

/// Returns the fully qualified name of a fixed tool.
public native fun fixed_tool_fqn(tool: FixedTool): std::ascii::String;

/// Constructs an execution selection targeting a specific agent skill.
public native fun execution_selection_agent_skill(
    agent_id: sui::object::ID,
    skill_id: u64,
    selected_dag: std::option::Option<sui::object::ID>,
): ExecutionSelection;

/// Constructs an execution selection targeting the default agent for a DAG.
public native fun execution_selection_default_agent(dag_id: sui::object::ID): ExecutionSelection;

/// Returns the agent ID of an agent skill execution selection.
///
/// Aborts with `EAgentExecutionSkillRequired` if the selection is a default agent selection.
public native fun execution_selection_agent_id(selection: &ExecutionSelection): sui::object::ID;

/// Returns the skill ID of an agent skill execution selection.
///
/// Aborts with `EAgentExecutionSkillRequired` if the selection is a default agent selection.
public native fun execution_selection_skill_id(selection: &ExecutionSelection): u64;

/// Returns the DAG ID of a default agent execution selection.
///
/// Aborts with `EDefaultAgentExecutionRequired` if the selection is an agent skill selection.
public native fun execution_selection_default_agent_dag_id(
    selection: &ExecutionSelection,
): sui::object::ID;

/// Builds an execution config that runs a DAG through the default agent.
///
/// The invoker is recorded as the transaction sender.
public native fun new_default_agent_execution_config(
    dag: sui::object::ID,
    network: sui::object::ID,
    entry_group: nexus_interface::graph::EntryGroup,
    inputs: sui::vec_map::VecMap<
        nexus_interface::graph::Vertex,
        sui::vec_map::VecMap<nexus_interface::graph::InputPort, nexus_primitives::data::NexusData>,
    >,
    ctx: &mut sui::tx_context::TxContext,
): AgentExecutionConfig;

/// Builds an execution config that runs a DAG through a specific agent skill.
///
/// The invoker is recorded as the transaction sender.
public native fun new_agent_execution_config(
    agent_id: sui::object::ID,
    network: sui::object::ID,
    entry_group: nexus_interface::graph::EntryGroup,
    inputs: sui::vec_map::VecMap<
        nexus_interface::graph::Vertex,
        sui::vec_map::VecMap<nexus_interface::graph::InputPort, nexus_primitives::data::NexusData>,
    >,
    skill_id: u64,
    selected_dag: std::option::Option<sui::object::ID>,
    authorization_bindings: sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
    ctx: &mut sui::tx_context::TxContext,
): AgentExecutionConfig;

/// Returns the DAG ID of a default agent execution config.
///
/// Aborts with `EDefaultAgentExecutionRequired` if the config targets an agent skill.
public native fun agent_execution_config_dag_id(self: &AgentExecutionConfig): sui::object::ID;

/// Returns the skill ID of an agent skill execution config.
///
/// Aborts with `EAgentExecutionSkillRequired` if the config targets the default agent.
public native fun agent_execution_config_skill_id(self: &AgentExecutionConfig): u64;

/// Returns the runtime selected DAG of an agent skill execution config, if any.
///
/// Aborts with `EAgentExecutionSkillRequired` if the config targets the default agent.
public native fun agent_execution_config_selected_dag(
    self: &AgentExecutionConfig,
): std::option::Option<sui::object::ID>;

/// Returns the agent ID of an agent skill execution config.
///
/// Aborts with `EAgentExecutionSkillRequired` if the config targets the default agent.
public native fun agent_execution_config_agent_id(self: &AgentExecutionConfig): sui::object::ID;

/// Returns whether caller intent selects the default Agent.
public native fun agent_execution_config_is_default(self: &AgentExecutionConfig): bool;

/// Consumes an execution config and returns its component fields.
public native fun destroy_agent_execution_config(
    self: AgentExecutionConfig,
): (
    sui::object::ID,
    nexus_interface::graph::EntryGroup,
    sui::vec_map::VecMap<
        nexus_interface::graph::Vertex,
        sui::vec_map::VecMap<nexus_interface::graph::InputPort, nexus_primitives::data::NexusData>,
    >,
    address,
    ExecutionSelection,
    sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
);

/// Creates a durable execution target after registry validation.
public native fun execution_spec(
    dag_id: sui::object::ID,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    network: sui::object::ID,
    entry_group: nexus_interface::graph::EntryGroup,
    inputs: sui::vec_map::VecMap<
        nexus_interface::graph::Vertex,
        sui::vec_map::VecMap<nexus_interface::graph::InputPort, nexus_primitives::data::NexusData>,
    >,
    invoker: address,
): ExecutionSpec;

/// Returns the DAG pinned by [`ExecutionSpec`].
public native fun execution_spec_dag_id(self: &ExecutionSpec): sui::object::ID;

/// Returns the agent pinned by [`ExecutionSpec`].
public native fun execution_spec_agent_id(self: &ExecutionSpec): sui::object::ID;

/// Returns the skill pinned by [`ExecutionSpec`].
public native fun execution_spec_skill_id(self: &ExecutionSpec): u64;

/// Returns the interface revision pinned by [`ExecutionSpec`].
public native fun execution_spec_interface_version(
    self: &ExecutionSpec,
): nexus_interface::version::InterfaceVersion;

/// Returns the leader network pinned by [`ExecutionSpec`].
public native fun execution_spec_network(self: &ExecutionSpec): sui::object::ID;

/// Returns the entry group pinned by [`ExecutionSpec`].
public native fun execution_spec_entry_group(
    self: &ExecutionSpec,
): nexus_interface::graph::EntryGroup;

/// Returns the input values pinned by [`ExecutionSpec`].
public native fun execution_spec_inputs(
    self: &ExecutionSpec,
): sui::vec_map::VecMap<
    nexus_interface::graph::Vertex,
    sui::vec_map::VecMap<nexus_interface::graph::InputPort, nexus_primitives::data::NexusData>,
>;

/// Returns the invoker recorded by [`ExecutionSpec`].
public native fun execution_spec_invoker(self: &ExecutionSpec): address;

/// Builds vertex authorization grants for a Task.
public native fun new_task_vertex_authorization_grants(
    agent: &Agent,
    dag_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    task_id: sui::object::ID,
    authorization_bindings: sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
): vector<
    nexus_primitives::authorization::Grant<
        nexus_interface::authorization::AgentVertexAuthorization,
    >,
>;

/// Builds the authorization and user funded reserve for a Task.
public native fun new_task_components_address_funded_with_grants(
    agent: &Agent,
    interface_revision: nexus_interface::version::InterfaceVersion,
    payment_policy: nexus_interface::payment::SkillPaymentPolicy,
    task_id: sui::object::ID,
    skill_id: u64,
    prepayment: sui::coin::Coin<sui::sui::SUI>,
    refund_recipient: address,
    occurrence_budget_mist: u64,
    dag_id: sui::object::ID,
    authorization_bindings: sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
    ctx: &mut sui::tx_context::TxContext,
): (
    nexus_interface::authorization::AgentSkillAuthorization,
    nexus_interface::payment::TaskPaymentReserve,
);

/// Builds the authorization and Agent funded reserve for a Task.
public native fun new_task_components_from_agent_vault_with_grants(
    agent: &mut Agent,
    interface_revision: nexus_interface::version::InterfaceVersion,
    payment_policy: nexus_interface::payment::SkillPaymentPolicy,
    task_id: sui::object::ID,
    skill_id: u64,
    prepay_amount_mist: u64,
    occurrence_budget_mist: u64,
    dag_id: sui::object::ID,
    authorization_bindings: sui::vec_map::VecMap<nexus_interface::graph::Vertex, sui::object::ID>,
    ctx: &mut sui::tx_context::TxContext,
): (
    nexus_interface::authorization::AgentSkillAuthorization,
    nexus_interface::payment::TaskPaymentReserve,
);

/// Asserts that a fixed tool list contains no duplicate entries.
///
/// Aborts with `EFixedToolDuplicate` if two entries share both registry ID and FQN.
public native fun assert_canonical_fixed_tools(fixed_tools: &vector<FixedTool>);

/// Cancels a scheduled payment reserve and returns its remaining funds to the agent vault.
///
/// Aborts with `EVaultAgentMismatch` if the reserve or vault does not belong to the agent.
public native fun cancel_task_reserve_to_vault(
    agent: &mut Agent,
    reserve: &mut nexus_interface::payment::TaskPaymentReserve,
);

/// Refills an agent funded Task reserve from its owning vault.
public native fun refill_task_reserve_from_vault(
    agent: &mut Agent,
    reserve: &mut nexus_interface::payment::TaskPaymentReserve,
    amount: u64,
);

/// Deposit SUI into an agent payment vault. Any sender may fund a vault.
public native fun deposit_agent_payment_vault(
    agent: &mut Agent,
    coin: sui::coin::Coin<sui::sui::SUI>,
);

/// Refill an agent funded execution payment by withdrawing from the owning agent vault.
public native fun refill_execution_payment_from_agent_vault_balance(
    agent: &mut Agent,
    payment: &mut nexus_interface::payment::ExecutionPayment,
    amount: u64,
): u64;

/// Withdraw SUI from an agent payment vault.
///
/// Registry wrappers choose the authorization policy. Active payment funds
/// are held by their [`payment_interface::ExecutionPayment`] values.
public native fun withdraw_agent_payment_vault(
    agent: &mut Agent,
    amount: u64,
    ctx: &mut sui::tx_context::TxContext,
): sui::coin::Coin<sui::sui::SUI>;

/// Constructs a skill DAG binding pinned to a specific DAG.
public native fun dag_binding_pinned(dag_id: address): SkillDagBinding;

/// Constructs a skill DAG binding whose DAG is selected at runtime.
public native fun dag_binding_runtime_selected(): SkillDagBinding;

/// Returns whether a skill DAG binding selects its DAG at runtime.
public native fun dag_binding_is_runtime_selected(binding: SkillDagBinding): bool;

/// Returns the pinned DAG ID of a binding, or `none` when the DAG is runtime selected.
public native fun dag_binding_pinned_dag_id(binding: SkillDagBinding): std::option::Option<address>;

/// Returns the object address of the agent's payment vault.
public native fun agent_payment_vault_id(agent: &Agent): address;

/// Returns the agent ID recorded in the agent's payment vault.
public native fun agent_payment_vault_agent_id(agent: &Agent): sui::object::ID;

/// Returns the spendable SUI balance of the agent's payment vault.
public native fun agent_payment_vault_available_balance(agent: &Agent): u64;

/// Constructs the input, payment, scheduling, and fixed Tool requirements committed by a skill revision.
public native fun skill_requirements(
    input_commitment: vector<u8>,
    payment_policy: nexus_interface::payment::SkillPaymentPolicy,
    schedule_policy: SkillSchedulePolicy,
    fixed_tools: vector<FixedTool>,
): SkillRequirement;

/// Creates a policy that permits exactly one dispatched occurrence.
public native fun schedule_once(): SkillSchedulePolicy;

/// Creates a recurring policy with a minimum interval and optional total cap.
///
/// Aborts with `EInvalidSchedulePolicy` if `min_interval_ms` is zero or a supplied
/// `max_occurrences` is zero.
public native fun schedule_recurring(
    min_interval_ms: u64,
    max_occurrences: std::option::Option<u64>,
): SkillSchedulePolicy;

/// Returns whether [`SkillSchedulePolicy`] permits recurrence.
public native fun schedule_policy_allows_recurrence(policy: SkillSchedulePolicy): bool;

/// Returns the minimum dispatch interval.
public native fun schedule_policy_min_interval_ms(policy: SkillSchedulePolicy): u64;

/// Returns the total dispatch cap.
public native fun schedule_policy_max_occurrences(
    policy: SkillSchedulePolicy,
): std::option::Option<u64>;
