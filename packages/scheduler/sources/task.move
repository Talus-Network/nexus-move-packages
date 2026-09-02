/// Interface for the published [`nexus_scheduler::task`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_scheduler::task;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Immutable authority for a [`Task`].
public enum TaskController has copy, drop, store {
    Address(address),
    Agent(sui::object::ID),
}

/// Correlation between one occurrence and one [`DAGExecution`].
public struct InFlightOccurrence has copy, drop, store {
    execution_id: sui::object::ID,
}

/// Explicit lifecycle state for a [`Task`].
public enum TaskStatus has copy, drop, store {
    Active,
    Paused,
    Canceled,
    Rejected {
        reason: TaskRejectionReason,
    },
    Finalized,
}

/// Dynamic field key for one occurrence allocated by a [`Task`].
public struct OccurrenceRecordKey(u64) has copy, drop, store;

/// Permanent reason current runtime refused a proposal contract.
public enum TaskRejectionReason has copy, drop, store {
    UnsupportedWorkAdmission,
    StaleSkillContract,
    MutableDAG,
}

/// Durable state for one occurrence allocated by a [`Task`].
public struct OccurrenceRecord has store {
    occurrence: nexus_scheduler::schedule::Occurrence,
    last_effective_start_time_ms: std::option::Option<u64>,
    state: OccurrenceState,
}

/// Behavior after a failed occurrence.
public enum FailureMode has copy, drop, store {
    Continue,
    Pause,
}

/// Durable scheduling authority and occurrence state.
public struct Task has key {
    id: sui::object::UID,
}

/// Monotonic lifecycle state for an allocated occurrence.
public enum OccurrenceState has copy, drop, store {
    /// The occurrence is waiting in its [`Task`]'s schedule.
    Scheduled,
    /// A leader dispatched the occurrence into a [`DAGExecution`].
    Dispatched {
        execution_id: sui::object::ID,
        dispatched_at_ms: u64,
    },
    /// The occurrence reached its deadline before dispatch.
    Missed {
        missed_at_ms: u64,
    },
    /// The occurrence left its schedule without dispatch.
    Withdrawn {
        reason: nexus_scheduler::schedule::OccurrenceWithdrawalReason,
    },
    /// The dispatched execution reached a terminal outcome.
    Settled {
        execution_id: sui::object::ID,
        dispatched_at_ms: u64,
        settled_at_ms: u64,
        succeeded: bool,
    },
}

/// Version one stored layout for [`Task`].
public struct TaskInnerV1 has store {
    controller: TaskController,
    status: TaskStatus,
    failure_mode: FailureMode,
    admission_contract: std::type_name::TypeName,
    operation: nexus_interface::agent::ExecutionSpec,
    schedule_policy: nexus_interface::agent::SkillSchedulePolicy,
    schedule: nexus_scheduler::schedule::Schedule,
    in_flight: sui::table::Table<u64, InFlightOccurrence>,
}

/// Owned pointer to a [`Task`] for discovery.
public struct TaskPointer has key, store {
    id: sui::object::UID,
    task_id: sui::object::ID,
}

/// Dynamic child key for the Task authorization.
public struct AuthorizationFieldKey() has copy, drop, store;

/// Dynamic child key for the Task payment reserve.
public struct PaymentReserveFieldKey() has copy, drop, store;

/// Returns the referenced [`Task`] ID.
public fun task_id(self: &TaskPointer): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the Task authorization.
public fun authorization(self: &Task): &nexus_interface::authorization::AgentSkillAuthorization {
    abort ELocalExecutionUnavailable
}

/// Returns the Task payment reserve.
public fun payment_reserve(self: &Task): &nexus_interface::payment::TaskPaymentReserve {
    abort ELocalExecutionUnavailable
}

/// Returns the validation contract selected by this proposal.
///
/// The selector is caller supplied metadata. Current admission must validate
/// every safety relevant field and must never treat this value as provenance.
public fun admission_contract(self: &Task): std::type_name::TypeName {
    abort ELocalExecutionUnavailable
}

/// Returns the skill scheduling limits.
public fun schedule_policy(self: &Task): nexus_interface::agent::SkillSchedulePolicy {
    abort ELocalExecutionUnavailable
}

/// Returns the occurrence schedule.
public fun occurrence_schedule(self: &Task): &nexus_scheduler::schedule::Schedule {
    abort ELocalExecutionUnavailable
}

/// Returns the immutable Task controller.
public fun controller(self: &Task): TaskController {
    abort ELocalExecutionUnavailable
}

/// Returns the explicit Task status.
public fun status(self: &Task): TaskStatus {
    abort ELocalExecutionUnavailable
}

/// Returns the configured failure behavior.
public fun failure_mode(self: &Task): FailureMode {
    abort ELocalExecutionUnavailable
}

/// Derives the [`DAGExecution`] ID assigned to one [`Task`] occurrence.
public fun derive_execution_id(task_id: sui::object::ID, occurrence_id: u64): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns whether the Task is active.
public fun is_active(self: &Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether the Task is paused.
public fun is_paused(self: &Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether the Task is canceled.
public fun is_canceled(self: &Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether current runtime permanently rejected the proposal.
public fun is_rejected(self: &Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the permanent rejection reason, when present.
public fun rejection_reason(self: &Task): std::option::Option<TaskRejectionReason> {
    abort ELocalExecutionUnavailable
}

/// Returns whether the Task has released its live resources.
public fun is_finalized(self: &Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the durable record for one allocated occurrence.
public fun occurrence_record(self: &Task, occurrence_id: u64): &OccurrenceRecord {
    abort ELocalExecutionUnavailable
}

/// Returns the occurrence preserved by a record.
public fun occurrence(self: &OccurrenceRecord): nexus_scheduler::schedule::Occurrence {
    abort ELocalExecutionUnavailable
}

/// Returns the latest effective start advertised for an occurrence.
public fun last_effective_start_time_ms(self: &OccurrenceRecord): std::option::Option<u64> {
    abort ELocalExecutionUnavailable
}

/// Returns the monotonic lifecycle state preserved by a record.
public fun state(self: &OccurrenceRecord): OccurrenceState {
    abort ELocalExecutionUnavailable
}

/// Returns whether an occurrence has not left its schedule.
public fun is_scheduled(self: OccurrenceState): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether an occurrence has been dispatched but not settled.
public fun is_dispatched(self: OccurrenceState): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether an occurrence expired before dispatch.
public fun is_missed(self: OccurrenceState): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether an occurrence was withdrawn before dispatch.
public fun is_withdrawn(self: OccurrenceState): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether a dispatched occurrence reached a terminal outcome.
public fun is_settled(self: OccurrenceState): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the related [`DAGExecution`] ID after dispatch.
public fun execution_id(self: OccurrenceState): std::option::Option<sui::object::ID> {
    abort ELocalExecutionUnavailable
}

/// Returns the dispatch timestamp after dispatch.
public fun dispatched_at_ms(self: OccurrenceState): std::option::Option<u64> {
    abort ELocalExecutionUnavailable
}

/// Returns the expiration timestamp for a missed occurrence.
public fun missed_at_ms(self: OccurrenceState): std::option::Option<u64> {
    abort ELocalExecutionUnavailable
}

/// Returns why an occurrence was withdrawn.
public fun withdrawal_reason(
    self: OccurrenceState,
): std::option::Option<nexus_scheduler::schedule::OccurrenceWithdrawalReason> {
    abort ELocalExecutionUnavailable
}

/// Returns the settlement timestamp for a settled occurrence.
public fun settled_at_ms(self: OccurrenceState): std::option::Option<u64> {
    abort ELocalExecutionUnavailable
}

/// Returns the terminal outcome for a settled occurrence.
public fun succeeded(self: OccurrenceState): std::option::Option<bool> {
    abort ELocalExecutionUnavailable
}

/// Returns whether an occurrence remains in flight.
public fun is_in_flight(self: &Task, occurrence_id: u64): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the number of in flight occurrences.
public fun in_flight_count(self: &Task): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns the execution correlated with an occurrence.
public fun in_flight_execution_id(self: &Task, occurrence_id: u64): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns whether reserve funds cover one occurrence.
public fun is_awaiting_funds(self: &Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether the Task can release its live resources.
public fun can_close(self: &Task): bool {
    abort ELocalExecutionUnavailable
}

/// Returns an address controller.
public fun address_controller(address: address): TaskController {
    abort ELocalExecutionUnavailable
}

/// Returns an Agent controller.
public fun agent_controller(agent_id: sui::object::ID): TaskController {
    abort ELocalExecutionUnavailable
}

/// Returns the default continue behavior.
public fun continue_on_failure(): FailureMode {
    abort ELocalExecutionUnavailable
}

/// Returns explicit pause behavior.
public fun pause_on_failure(): FailureMode {
    abort ELocalExecutionUnavailable
}

/// Returns whether a failure mode continues.
public fun is_continue(mode: FailureMode): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether a [`TaskStatus`] is paused.
public fun status_is_paused(status: TaskStatus): bool {
    abort ELocalExecutionUnavailable
}
