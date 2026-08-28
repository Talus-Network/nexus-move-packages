module nexus_scheduler::task;

//! Interface for [`nexus_scheduler::task`].
//!
//! Calls resolve to the published package.

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
public native fun task_id(self: &TaskPointer): sui::object::ID;

/// Returns the Task authorization.
public native fun authorization(
    self: &Task,
): &nexus_interface::authorization::AgentSkillAuthorization;

/// Returns the Task payment reserve.
public native fun payment_reserve(self: &Task): &nexus_interface::payment::TaskPaymentReserve;

/// Returns the validation contract selected by this proposal.
///
/// The selector is caller supplied metadata. Current admission must validate
/// every safety relevant field and must never treat this value as provenance.
public native fun admission_contract(self: &Task): std::type_name::TypeName;

/// Returns the skill scheduling limits.
public native fun schedule_policy(self: &Task): nexus_interface::agent::SkillSchedulePolicy;

/// Returns the occurrence schedule.
public native fun occurrence_schedule(self: &Task): &nexus_scheduler::schedule::Schedule;

/// Returns the immutable Task controller.
public native fun controller(self: &Task): TaskController;

/// Returns the explicit Task status.
public native fun status(self: &Task): TaskStatus;

/// Returns the configured failure behavior.
public native fun failure_mode(self: &Task): FailureMode;

/// Derives the [`DAGExecution`] ID assigned to one [`Task`] occurrence.
public native fun derive_execution_id(
    task_id: sui::object::ID,
    occurrence_id: u64,
): sui::object::ID;

/// Returns whether the Task is active.
public native fun is_active(self: &Task): bool;

/// Returns whether the Task is paused.
public native fun is_paused(self: &Task): bool;

/// Returns whether the Task is canceled.
public native fun is_canceled(self: &Task): bool;

/// Returns whether current runtime permanently rejected the proposal.
public native fun is_rejected(self: &Task): bool;

/// Returns the permanent rejection reason, when present.
public native fun rejection_reason(self: &Task): std::option::Option<TaskRejectionReason>;

/// Returns whether the Task has released its live resources.
public native fun is_finalized(self: &Task): bool;

/// Returns the durable record for one allocated occurrence.
public native fun occurrence_record(self: &Task, occurrence_id: u64): &OccurrenceRecord;

/// Returns the occurrence preserved by a record.
public native fun occurrence(self: &OccurrenceRecord): nexus_scheduler::schedule::Occurrence;

/// Returns the latest effective start advertised for an occurrence.
public native fun last_effective_start_time_ms(self: &OccurrenceRecord): std::option::Option<u64>;

/// Returns the monotonic lifecycle state preserved by a record.
public native fun state(self: &OccurrenceRecord): OccurrenceState;

/// Returns whether an occurrence has not left its schedule.
public native fun is_scheduled(self: OccurrenceState): bool;

/// Returns whether an occurrence has been dispatched but not settled.
public native fun is_dispatched(self: OccurrenceState): bool;

/// Returns whether an occurrence expired before dispatch.
public native fun is_missed(self: OccurrenceState): bool;

/// Returns whether an occurrence was withdrawn before dispatch.
public native fun is_withdrawn(self: OccurrenceState): bool;

/// Returns whether a dispatched occurrence reached a terminal outcome.
public native fun is_settled(self: OccurrenceState): bool;

/// Returns the related [`DAGExecution`] ID after dispatch.
public native fun execution_id(self: OccurrenceState): std::option::Option<sui::object::ID>;

/// Returns the dispatch timestamp after dispatch.
public native fun dispatched_at_ms(self: OccurrenceState): std::option::Option<u64>;

/// Returns the expiration timestamp for a missed occurrence.
public native fun missed_at_ms(self: OccurrenceState): std::option::Option<u64>;

/// Returns why an occurrence was withdrawn.
public native fun withdrawal_reason(
    self: OccurrenceState,
): std::option::Option<nexus_scheduler::schedule::OccurrenceWithdrawalReason>;

/// Returns the settlement timestamp for a settled occurrence.
public native fun settled_at_ms(self: OccurrenceState): std::option::Option<u64>;

/// Returns the terminal outcome for a settled occurrence.
public native fun succeeded(self: OccurrenceState): std::option::Option<bool>;

/// Returns whether an occurrence remains in flight.
public native fun is_in_flight(self: &Task, occurrence_id: u64): bool;

/// Returns the number of in flight occurrences.
public native fun in_flight_count(self: &Task): u64;

/// Returns the execution correlated with an occurrence.
public native fun in_flight_execution_id(self: &Task, occurrence_id: u64): sui::object::ID;

/// Returns whether reserve funds cover one occurrence.
public native fun is_awaiting_funds(self: &Task): bool;

/// Returns whether the Task can release its live resources.
public native fun can_close(self: &Task): bool;

/// Returns an address controller.
public native fun address_controller(address: address): TaskController;

/// Returns an Agent controller.
public native fun agent_controller(agent_id: sui::object::ID): TaskController;

/// Returns the default continue behavior.
public native fun continue_on_failure(): FailureMode;

/// Returns explicit pause behavior.
public native fun pause_on_failure(): FailureMode;

/// Returns whether a failure mode continues.
public native fun is_continue(mode: FailureMode): bool;

/// Returns whether a [`TaskStatus`] is paused.
public native fun status_is_paused(status: TaskStatus): bool;
