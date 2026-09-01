/// Interface for the published [`nexus_scheduler::scheduler`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_scheduler::scheduler;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Settlement state visible to Task callers.
public enum SettlementStatus has copy, drop {
    Pending,
    Succeeded,
    Failed,
}

/// Emitted when a [`Task`] is created.
public struct TaskCreatedEvent has copy, drop {
    task_id: sui::object::ID,
    controller: nexus_scheduler::task::TaskController,
    agent_id: sui::object::ID,
    skill_id: u64,
}

/// Emitted when a [`Task`] is paused.
public struct TaskPausedEvent has copy, drop {
    task_id: sui::object::ID,
}

/// Emitted when a [`Task`] is resumed.
public struct TaskResumedEvent has copy, drop {
    task_id: sui::object::ID,
}

/// Emitted when future [`Task`] work is canceled.
public struct TaskCanceledEvent has copy, drop {
    task_id: sui::object::ID,
}

/// Emitted when current runtime permanently rejects a proposal.
///
/// Existing [`DAGExecution`] obligations remain valid. The controller can
/// reclaim the proposal reserve through [`close`] or [`close_as_agent`] after
/// all admitted obligations drain.
public struct TaskRejectedEvent has copy, drop {
    task_id: sui::object::ID,
    reason: nexus_scheduler::task::TaskRejectionReason,
}

/// Emitted when a [`Task`] is finalized and releases its owned resources.
public struct TaskClosedEvent has copy, drop {
    task_id: sui::object::ID,
}

/// Emitted when a [`Task`] allocates one [`Occurrence`] identity.
public struct OccurrenceScheduledEvent has copy, drop {
    task_id: sui::object::ID,
    occurrence_id: u64,
    start_time_ms: u64,
    deadline_ms: std::option::Option<u64>,
    priority_fee_percentage: u64,
    source: nexus_scheduler::schedule::OccurrenceSource,
}

/// Emitted when an [`Occurrence`] becomes the Task's dispatch candidate.
///
/// Allocation and dispatch readiness are distinct. An occurrence may exist
/// while another execution occupies the Task's capacity. Every transition
/// into the advertised state emits this event so leaders can discover the
/// candidate after capacity is restored.
public struct OccurrenceAdvertisedEvent has copy, drop {
    task_id: sui::object::ID,
    occurrence_id: u64,
    effective_start_time_ms: u64,
    deadline_ms: std::option::Option<u64>,
    priority_fee_percentage: u64,
}

/// Emitted when an [`Occurrence`] leaves its schedule without dispatch.
public struct OccurrenceWithdrawnEvent has copy, drop {
    task_id: sui::object::ID,
    occurrence_id: u64,
    reason: nexus_scheduler::schedule::OccurrenceWithdrawalReason,
}

/// Emitted when an advertised occurrence expires.
public struct OccurrenceMissedEvent has copy, drop {
    task_id: sui::object::ID,
    occurrence_id: u64,
    missed_at_ms: u64,
}

/// Emitted when a leader dispatches an occurrence.
public struct OccurrenceDispatchedEvent has copy, drop {
    task_id: sui::object::ID,
    occurrence_id: u64,
    execution_id: sui::object::ID,
    dispatched_at_ms: u64,
}

/// Emitted after terminal occurrence settlement.
public struct OccurrenceSettledEvent has copy, drop {
    task_id: sui::object::ID,
    occurrence_id: u64,
    execution_id: sui::object::ID,
    succeeded: bool,
}

/// Bind the immutable authority root to this Scheduler package lineage.
///
/// This is a one time deployment transition. Later Scheduler releases use
/// [`activate_runtime`] with the same stable [`UpgradeCap`] object.
public fun bind_runtime(
    authority: &mut nexus_kernel::runtime_authority::RuntimeAuthority,
    authority_cap: &nexus_kernel::runtime_authority::RuntimeAuthorityCap,
    scheduler_cap: &sui::package::UpgradeCap,
) {
    abort ELocalExecutionUnavailable
}

/// Activate this Scheduler release as the only protocol effect facade.
public fun activate_runtime(
    authority: &mut nexus_kernel::runtime_authority::RuntimeAuthority,
    scheduler_cap: &sui::package::UpgradeCap,
) {
    abort ELocalExecutionUnavailable
}

/// Creates an address controlled and user funded [`Task`] for one agent skill.
public fun new_user_task(
    registry: &nexus_registry::agent_registry::AgentRegistry,
    dag: &nexus_interface::dag::DAG,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    agent: &nexus_interface::agent::Agent,
    config: nexus_interface::agent::AgentExecutionConfig,
    prepayment: sui::coin::Coin<sui::sui::SUI>,
    refund_recipient: address,
    occurrence_budget_mist: u64,
    failure_mode: nexus_scheduler::task::FailureMode,
    ctx: &mut sui::tx_context::TxContext,
): (nexus_scheduler::task::Task, nexus_scheduler::task::TaskPointer) {
    abort ELocalExecutionUnavailable
}

/// Creates an Agent controlled [`Task`] funded by its payment vault.
public fun new_agent_task(
    registry: &nexus_registry::agent_registry::AgentRegistry,
    dag: &nexus_interface::dag::DAG,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    agent: &mut nexus_interface::agent::Agent,
    config: nexus_interface::agent::AgentExecutionConfig,
    prepay_amount_mist: u64,
    occurrence_budget_mist: u64,
    failure_mode: nexus_scheduler::task::FailureMode,
    ctx: &mut sui::tx_context::TxContext,
): (nexus_scheduler::task::Task, nexus_scheduler::task::TaskPointer) {
    abort ELocalExecutionUnavailable
}

/// Creates an address controlled [`Task`] for the default executor.
public fun new_default_task(
    registry: &nexus_registry::agent_registry::AgentRegistry,
    dag: &nexus_interface::dag::DAG,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    config: nexus_interface::agent::AgentExecutionConfig,
    prepayment: sui::coin::Coin<sui::sui::SUI>,
    refund_recipient: address,
    occurrence_budget_mist: u64,
    failure_mode: nexus_scheduler::task::FailureMode,
    ctx: &mut sui::tx_context::TxContext,
): (nexus_scheduler::task::Task, nexus_scheduler::task::TaskPointer) {
    abort ELocalExecutionUnavailable
}

/// Shares a fully composed Task.
public fun share(task: nexus_scheduler::task::Task) {
    abort ELocalExecutionUnavailable
}

/// Atomically accepts one occurrence under an address controller.
///
/// The fixed authority read makes an explicit WorkAdmission disable roll back
/// this entire caller transaction before any proposal state can persist.
public fun schedule(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    start_time_ms: u64,
    deadline_ms: std::option::Option<u64>,
    priority_fee_percentage: u64,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Atomically accepts one occurrence under an Agent controller.
public fun schedule_as_agent(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    agent: &nexus_interface::agent::Agent,
    start_time_ms: u64,
    deadline_ms: std::option::Option<u64>,
    priority_fee_percentage: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Atomically accepts one lazy recurrence under an address controller.
public fun set_recurrence(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    start_time_ms: u64,
    deadline_ms: std::option::Option<u64>,
    interval_ms: u64,
    max_occurrences: std::option::Option<u64>,
    priority_fee_percentage: u64,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Atomically accepts one lazy recurrence under an Agent controller.
public fun set_recurrence_as_agent(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    agent: &nexus_interface::agent::Agent,
    start_time_ms: u64,
    deadline_ms: std::option::Option<u64>,
    interval_ms: u64,
    max_occurrences: std::option::Option<u64>,
    priority_fee_percentage: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Clears recurring work under an address controller.
public fun clear_recurrence(
    task: &mut nexus_scheduler::task::Task,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Clears recurring work under an Agent controller.
public fun clear_recurrence_as_agent(
    task: &mut nexus_scheduler::task::Task,
    agent: &nexus_interface::agent::Agent,
) {
    abort ELocalExecutionUnavailable
}

/// Pauses address controlled dispatch.
public fun pause(task: &mut nexus_scheduler::task::Task, ctx: &mut sui::tx_context::TxContext) {
    abort ELocalExecutionUnavailable
}

/// Pauses Agent controlled dispatch.
public fun pause_as_agent(
    task: &mut nexus_scheduler::task::Task,
    agent: &nexus_interface::agent::Agent,
) {
    abort ELocalExecutionUnavailable
}

/// Resumes address controlled dispatch.
public fun resume(task: &mut nexus_scheduler::task::Task, ctx: &mut sui::tx_context::TxContext) {
    abort ELocalExecutionUnavailable
}

/// Resumes Agent controlled dispatch.
public fun resume_as_agent(
    task: &mut nexus_scheduler::task::Task,
    agent: &nexus_interface::agent::Agent,
) {
    abort ELocalExecutionUnavailable
}

/// Cancels future work under an address controller.
public fun cancel(task: &mut nexus_scheduler::task::Task, ctx: &mut sui::tx_context::TxContext) {
    abort ELocalExecutionUnavailable
}

/// Cancels future work under an Agent controller.
public fun cancel_as_agent(
    task: &mut nexus_scheduler::task::Task,
    agent: &nexus_interface::agent::Agent,
) {
    abort ELocalExecutionUnavailable
}

/// Refills an address funded Task reserve and advertises restored work.
public fun refill(
    task: &mut nexus_scheduler::task::Task,
    funds: sui::coin::Coin<sui::sui::SUI>,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Refills an Agent funded Task reserve and advertises restored work.
public fun refill_from_agent(
    task: &mut nexus_scheduler::task::Task,
    agent: &mut nexus_interface::agent::Agent,
    amount: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Expires exactly the advertised occurrence.
public fun expire(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    expected_occurrence_id: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Expires the advertised occurrence and consumes its leader submission gas charge.
public fun expire_with_gas_charge(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    expected_occurrence_id: u64,
    gas_charge: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Admits exactly one accepted occurrence into a funded protocol obligation.
///
/// Proposal metadata is never runtime authority. The current runtime revalidates
/// its contract, Agent skill revision, policies, leader, DAG, authorization, and
/// funding before [`DAGExecution`] creation. A later WorkAdmission disable does
/// not revoke an occurrence whose scheduling transaction already succeeded.
public fun admit_next(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    dag: &nexus_interface::dag::DAG,
    registry: &nexus_registry::agent_registry::AgentRegistry,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    expected_occurrence_id: u64,
    gas_charge: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): nexus_workflow::execution::DAGExecution {
    abort ELocalExecutionUnavailable
}

/// Commits a proven permanent rejection and makes the reserve reclaimable.
///
/// An abort cannot represent rejection because it would roll back the Task
/// transition and any charge. Only the selected current leader may commit this
/// transition, and the reason is derived entirely from onchain state.
public fun reject_next(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    dag: &nexus_interface::dag::DAG,
    registry: &nexus_registry::agent_registry::AgentRegistry,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    expected_occurrence_id: u64,
    gas_charge: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): nexus_scheduler::task::TaskRejectionReason {
    abort ELocalExecutionUnavailable
}

/// Settles one execution back into its owning Task.
public fun settle(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    task: &mut nexus_scheduler::task::Task,
    execution: &mut nexus_workflow::execution::DAGExecution,
    clock: &sui::clock::Clock,
): SettlementStatus {
    abort ELocalExecutionUnavailable
}

/// Finalizes an address controlled [`Task`] and refunds its recorded source.
public fun close(task: &mut nexus_scheduler::task::Task, ctx: &mut sui::tx_context::TxContext) {
    abort ELocalExecutionUnavailable
}

/// Finalizes an Agent controlled [`Task`] and refunds its vault.
public fun close_as_agent(
    task: &mut nexus_scheduler::task::Task,
    agent: &mut nexus_interface::agent::Agent,
) {
    abort ELocalExecutionUnavailable
}

/// Returns the default continue behavior.
public fun continue_on_failure(): nexus_scheduler::task::FailureMode {
    abort ELocalExecutionUnavailable
}

/// Returns explicit pause behavior.
public fun pause_on_failure(): nexus_scheduler::task::FailureMode {
    abort ELocalExecutionUnavailable
}

/// Returns whether a failure mode continues.
public fun is_continue(mode: nexus_scheduler::task::FailureMode): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the advertised occurrence.
public fun advertised_occurrence(
    task: &nexus_scheduler::task::Task,
): std::option::Option<nexus_scheduler::schedule::Occurrence> {
    abort ELocalExecutionUnavailable
}

/// Returns whether no future occurrence exists.
public fun is_idle(task: &nexus_scheduler::task::Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether the skill occurrence quota is exhausted.
public fun is_exhausted(task: &nexus_scheduler::task::Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether one occurrence cannot currently be funded.
public fun is_awaiting_funds(task: &nexus_scheduler::task::Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether the Task may be closed.
public fun can_close(task: &nexus_scheduler::task::Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether settlement is pending.
public fun settlement_is_pending(status: SettlementStatus): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether settlement succeeded.
public fun settlement_is_succeeded(status: SettlementStatus): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether settlement failed.
public fun settlement_is_failed(status: SettlementStatus): bool {
    abort ELocalExecutionUnavailable
}
