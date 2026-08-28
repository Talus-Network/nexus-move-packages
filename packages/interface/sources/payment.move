module nexus_interface::payment;

//! Interface for [`nexus_interface::payment`].
//!
//! Calls resolve to the published package.

/// Concrete payment source recorded on execution payments and scheduled reserves.
public enum PaymentSourceKind has copy, drop, store {
    UserFunded {
        user: address,
    },
    AgentFunded {
        agent_id: sui::object::ID,
    },
}

/// Capability proving an agent vault is authorized to settle a payment for a given agent.
public struct AgentVaultPaymentAuthorization has copy, drop {
    agent_id: sui::object::ID,
}

/// Final lifecycle state for an execution payment.
public enum ExecutionPaymentFinalState has copy, drop, store {
    Pending,
    Accomplished,
    Refunded,
}

/// Custodied payment for one standard agent execution.
public struct ExecutionPayment has key, store {
    id: sui::object::UID,
}

/// Payment limits and source mode required by a skill.
public enum SkillPaymentPolicy has copy, drop, store {
    UserFunded,
    AgentFunded {
        max_budget_mist: u64,
    },
}

/// Version one stored layout for [`ExecutionPayment`].
///
/// The stable [`ExecutionPayment`] cannot contain these fields because its
/// published layout must remain unchanged while stored data evolves.
public struct ExecutionPaymentInnerV1 has store {
    execution_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_revision: nexus_interface::version::InterfaceVersion,
    payment_policy: SkillPaymentPolicy,
    source_kind: PaymentSourceKind,
    max_budget_mist: u64,
    gas_budget_mist: u64,
    priority_fee_reserve_mist: u64,
    locked_budget_mist: u64,
    funds: sui::balance::Balance<sui::sui::SUI>,
    consumed: u64,
    tool_fee_charged: u64,
    priority_fee_charged: u64,
    priority_fee_percentage: u64,
    accomplished: bool,
    refunded: bool,
    final_state: ExecutionPaymentFinalState,
    tool_cost_snapshot: sui::vec_map::VecMap<vector<u8>, u64>,
    locked_vertices: vector<ExecutionPaymentVertexLock>,
}

/// Locked payment line for a runtime vertex.
public struct ExecutionPaymentVertexLock has copy, drop, store {
    vertex_key: vector<u8>,
    invocation_id: sui::object::ID,
    amount: u64,
}

/// Canonical workflow and payment data offered to one economic policy.
public struct InvocationRequest {
    execution_id: address,
    vertex_key: vector<u8>,
    tool_id: sui::object::ID,
    tool_fqn: vector<u8>,
    cashier_id: sui::object::ID,
    payment_id: sui::object::ID,
    source: PaymentSourceKind,
    price_snapshot: u64,
    authorized_at_ms: u64,
}

/// Linear authority to place one exact Invocation under its execution.
public struct InvocationLockReceipt {
    vertex_key: vector<u8>,
    invocation_id: sui::object::ID,
    amount: u64,
}

/// Linear authority to resolve one exact Invocation once.
public struct InvocationSettlementReceipt {
    invocation_id: sui::object::ID,
    was_refunded: bool,
}

/// Durable payment custody stored under a scheduler Task.
///
/// Occurrence correlation belongs to the owning Task. The reserve records only
/// the identity and policy needed to create and settle execution payments.
public struct TaskPaymentReserve has key, store {
    id: sui::object::UID,
}

/// Version one stored layout for [`TaskPaymentReserve`].
///
/// The stable [`TaskPaymentReserve`] cannot contain these fields because its
/// published layout must remain unchanged while stored data evolves.
public struct TaskPaymentReserveInnerV1 has store {
    task_id: sui::object::ID,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    authorization_id: sui::object::ID,
    source: PaymentSourceKind,
    /// Address that receives unused funds from an address funded [TaskPaymentReserve].
    refund_recipient: std::option::Option<address>,
    occurrence_budget_mist: u64,
    remaining_funds: sui::balance::Balance<sui::sui::SUI>,
    payment_policy: SkillPaymentPolicy,
}

/// Emitted when a new execution payment is created and its budget is locked.
public struct AgentSkillPaymentCreatedEvent has copy, drop {
    payment_id: address,
    execution_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_revision: nexus_interface::version::InterfaceVersion,
    payment_policy: SkillPaymentPolicy,
    source_kind: PaymentSourceKind,
    max_budget_mist: u64,
    gas_budget_mist: u64,
    priority_fee_reserve_mist: u64,
    locked_budget_mist: u64,
    priority_fee_percentage: u64,
}

/// Emitted when a [`TaskPaymentReserve`] receives more funds.
public struct TaskPaymentReserveRefilledEvent has copy, drop {
    task_id: sui::object::ID,
    reserve_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    source_kind: PaymentSourceKind,
    refill_amount: u64,
    occurrence_budget_mist: u64,
    remaining_funds: u64,
}

/// Emitted when a reserve creates the payment for one Task occurrence.
public struct TaskExecutionPaymentCreatedEvent has copy, drop {
    task_id: sui::object::ID,
    reserve_id: address,
    occurrence_id: u64,
    execution_id: address,
    payment_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    source_kind: PaymentSourceKind,
    budget: u64,
    remaining_funds: u64,
}

/// Emitted when a [`TaskPaymentReserve`] returns all remaining funds.
public struct TaskPaymentReserveCanceledEvent has copy, drop {
    task_id: sui::object::ID,
    reserve_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    source_kind: PaymentSourceKind,
    refunded_amount: u64,
    remaining_funds: u64,
}

/// Emitted when the payment for one Task occurrence reaches a final state.
public struct TaskExecutionPaymentFinalizedEvent has copy, drop {
    task_id: sui::object::ID,
    reserve_id: address,
    occurrence_id: u64,
    execution_id: address,
    payment_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_version: nexus_interface::version::InterfaceVersion,
    final_state: ExecutionPaymentFinalState,
    remaining_funds: u64,
}

/// Emitted when gas is consumed from an execution payment.
public struct GasPaymentConsumedEvent has copy, drop {
    payment_id: address,
    execution_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_revision: nexus_interface::version::InterfaceVersion,
    amount: u64,
    consumed_total: u64,
}

/// Emitted when payment fee totals are updated after gas, tool, or priority settlement.
public struct ExecutionPaymentFeesRecordedEvent has copy, drop {
    payment_id: address,
    execution_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    gas_fee_mist: u64,
    tool_fee_mist: u64,
    priority_fee_mist: u64,
    priority_fee_percentage: u64,
}

/// Emitted when a tool's cost is snapshotted onto an execution payment.
public struct ExecutionPaymentToolCostSnapshottedEvent has copy, drop {
    payment_id: address,
    execution_id: address,
    agent_id: sui::object::ID,
    tool_fqn: vector<u8>,
    cost: u64,
}

/// Emitted when an execution payment is accomplished.
public struct ExecutionAccomplishedEvent has copy, drop {
    execution_id: address,
    payment_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_revision: nexus_interface::version::InterfaceVersion,
}

/// Emitted when an execution payment is refunded, carrying the refund reason.
public struct ExecutionRefundedEvent has copy, drop {
    execution_id: address,
    payment_id: address,
    agent_id: sui::object::ID,
    skill_id: u64,
    interface_revision: nexus_interface::version::InterfaceVersion,
    refund_reason: vector<u8>,
}

/// Creates the payment for one Task occurrence.
///
/// The occurrence budget is split from the reserve. The owning Task records
/// the relationship between the occurrence and the resulting execution.
public native fun new_task_execution_payment(
    reserve: &mut TaskPaymentReserve,
    authorization: &nexus_interface::authorization::AgentSkillAuthorization,
    execution_id: address,
    occurrence_id: u64,
    priority_fee_percentage: u64,
    ctx: &mut sui::tx_context::TxContext,
): ExecutionPayment;

/// Records the immutable snapshotted cost for a Tool on an [`ExecutionPayment`].
/// Aborts if the payment is already accomplished or refunded.
public native fun snapshot_payment_tool_cost(
    payment: &mut ExecutionPayment,
    tool_fqn: vector<u8>,
    cost: u64,
);

/// Consumes gas from an execution payment, reimbursing the transaction sender's address balance.
public native fun consume_payment_for_verified_leader_submission(
    payment: &mut ExecutionPayment,
    amount: u64,
    ctx: &mut sui::tx_context::TxContext,
);

/// Consumes gas from an execution payment, reimbursing the given recipient's address balance; a no op when the amount is zero.
/// Aborts if the payment is final or if [`amount`] exceeds available funds.
public native fun consume_payment_for_verified_leader_submission_to_recipient(
    payment: &mut ExecutionPayment,
    amount: u64,
    recipient: address,
);

/// Consumes gas from a [`TaskPaymentReserve`] and reimburses the transaction sender.
///
/// Authorization is exactly mutable access to [`TaskPaymentReserve`].
/// The caller cannot select another reimbursement address.
/// Does nothing when the amount is zero.
public native fun consume_task_payment_reserve_for_sender(
    reserve: &mut TaskPaymentReserve,
    amount: u64,
    ctx: &mut sui::tx_context::TxContext,
);

/// Adds coin funds to an execution payment, increasing its max budget, and returns the refill amount.
/// Aborts if the coin value is zero, or if the payment is already accomplished or refunded.
public native fun refill_execution_payment_from_coin(
    payment: &mut ExecutionPayment,
    coin: sui::coin::Coin<sui::sui::SUI>,
): u64;

/// Creates canonical policy input for one workflow [Invocation].
public native fun new_invocation_request(
    payment: &ExecutionPayment,
    vertex_key: vector<u8>,
    tool_id: sui::object::ID,
    tool_fqn: vector<u8>,
    cashier_id: sui::object::ID,
    clock: &sui::clock::Clock,
): InvocationRequest;

/// Records one exact Invocation obligation and returns its placement authority.
public native fun lock_invocation(
    payment: &mut ExecutionPayment,
    vertex_key: vector<u8>,
    invocation_id: sui::object::ID,
    amount: u64,
): InvocationLockReceipt;

/// Returns the execution recorded by [InvocationRequest].
public native fun invocation_request_execution_id(request: &InvocationRequest): address;

/// Returns the runtime vertex key recorded by [InvocationRequest].
public native fun invocation_request_vertex_key(request: &InvocationRequest): vector<u8>;

/// Returns the Tool recorded by [InvocationRequest].
public native fun invocation_request_tool_id(request: &InvocationRequest): sui::object::ID;

/// Returns the Tool name recorded by [InvocationRequest].
public native fun invocation_request_tool_fqn(request: &InvocationRequest): vector<u8>;

/// Returns the cashier recorded by [InvocationRequest].
public native fun invocation_request_cashier_id(request: &InvocationRequest): sui::object::ID;

/// Returns the payment recorded by [InvocationRequest].
public native fun invocation_request_payment_id(request: &InvocationRequest): sui::object::ID;

/// Returns the payment source recorded by [InvocationRequest].
public native fun invocation_request_source(request: &InvocationRequest): PaymentSourceKind;

/// Returns the snapshotted Tool price recorded by [InvocationRequest].
public native fun invocation_request_price_snapshot(request: &InvocationRequest): u64;

/// Returns the authorization time recorded by [InvocationRequest].
public native fun invocation_request_authorized_at_ms(request: &InvocationRequest): u64;

/// Consumes [InvocationRequest] and returns its canonical fields.
public native fun into_invocation_request(
    request: InvocationRequest,
): (
    address,
    vector<u8>,
    sui::object::ID,
    vector<u8>,
    sui::object::ID,
    sui::object::ID,
    PaymentSourceKind,
    u64,
    u64,
);

/// Consumes [InvocationLockReceipt] and returns the exact placement fields.
public native fun into_invocation_lock_receipt(
    receipt: InvocationLockReceipt,
): (vector<u8>, sui::object::ID, u64);

/// Resolves one exact Invocation obligation.
///
/// A finalized obligation withdraws the amount recorded by its lock. A
/// refunded obligation only removes the lock and leaves all funds available.
public native fun settle_invocation(
    payment: &mut ExecutionPayment,
    vertex_key: vector<u8>,
    invocation_id: sui::object::ID,
    was_refunded: bool,
): (sui::balance::Balance<sui::sui::SUI>, InvocationSettlementReceipt);

/// Consumes [InvocationSettlementReceipt] and returns its exact fields.
public native fun into_invocation_settlement_receipt(
    receipt: InvocationSettlementReceipt,
): (sui::object::ID, bool);

/// Returns the base leader gas consumed by the payment, excluding paid tool fees and priority.
public native fun payment_leader_gas_consumed(payment: &ExecutionPayment): u64;

/// Returns the cumulative priority charge due for the payment's consumed leader gas.
public native fun priority_charge_for(payment: &ExecutionPayment): u64;

/// Returns the priority delta due after adding a settlement's valid payable leader gas.
public native fun settlement_priority_delta_for_leader_gas(
    payment: &ExecutionPayment,
    payable_leader_gas: u64,
): u64;

/// Returns the base leader gas plus priority delta required for a committed result settlement.
public native fun settlement_charge_required(
    payment: &ExecutionPayment,
    payable_leader_gas: u64,
): u64;

/// Returns spendable payment funds for settlement after preserving locked tool payments.
public native fun payment_available_settlement_funds(payment: &ExecutionPayment): u64;

/// Returns the amount currently available for a settlement requiring the given leader gas.
public native fun payment_available_settlement_charge(
    payment: &ExecutionPayment,
    payable_leader_gas: u64,
): u64;

/// Returns the missing amount for a committed result settlement, or zero when payable.
public native fun settlement_charge_missing(
    payment: &ExecutionPayment,
    payable_leader_gas: u64,
): u64;

/// Records and splits a committed result settlement's priority delta.
public native fun consume_priority_fee_for_settlement(
    payment: &mut ExecutionPayment,
    priority_delta: u64,
): sui::balance::Balance<sui::sui::SUI>;

/// Returns whether [payment] contains an obligation for [vertex_key].
public native fun invocation_locked(payment: &ExecutionPayment, vertex_key: vector<u8>): bool;

/// Returns the exact [Invocation] locked for [vertex_key], if one exists.
public native fun locked_invocation_id(
    payment: &ExecutionPayment,
    vertex_key: vector<u8>,
): std::option::Option<sui::object::ID>;

/// Marks a user funded payment accomplished and returns any remaining funds to the funding user; a no op if already accomplished.
/// Aborts if the payment still has locked vertices, if its source is not user funded, or if it is already refunded.
public native fun accomplish_invoker_payment(
    payment: &mut ExecutionPayment,
    ctx: &mut sui::tx_context::TxContext,
);

/// Marks a user funded payment refunded and returns all remaining funds to the funding user; a no op if already refunded.
/// Aborts if the payment still has locked vertices, if its source is not user funded, or if it is already accomplished.
public native fun refund_invoker_payment(
    payment: &mut ExecutionPayment,
    refund_reason: vector<u8>,
    ctx: &mut sui::tx_context::TxContext,
);

/// Constructs a user funded payment source for the given user address.
public native fun payment_source_kind_user_funded(user: address): PaymentSourceKind;

/// Constructs an agent funded payment source for the given agent.
public native fun payment_source_kind_agent_funded(agent_id: sui::object::ID): PaymentSourceKind;

/// Returns whether the payment source is user funded.
public native fun payment_source_kind_is_user_funded(source: &PaymentSourceKind): bool;

/// Returns whether the payment source is agent funded.
public native fun payment_source_kind_is_agent_funded(source: &PaymentSourceKind): bool;

/// Returns the funding user address of a user funded payment source.
/// Aborts if the source is agent funded.
public native fun payment_source_kind_user(source: &PaymentSourceKind): address;

/// Returns the agent id of an agent funded payment source.
/// Aborts if the source is user funded.
public native fun payment_source_kind_agent_id(source: &PaymentSourceKind): sui::object::ID;

/// Returns the pending execution payment final state.
public native fun payment_final_state_pending(): ExecutionPaymentFinalState;

/// Returns the accomplished execution payment final state.
public native fun payment_final_state_accomplished(): ExecutionPaymentFinalState;

/// Returns the refunded execution payment final state.
public native fun payment_final_state_refunded(): ExecutionPaymentFinalState;

/// Returns the user funded skill payment policy.
public native fun payment_policy_user_funded(): SkillPaymentPolicy;

/// Returns an agent funded skill payment policy with the given maximum budget.
/// Aborts if the maximum budget is zero.
public native fun payment_policy_agent_funded(max_budget_mist: u64): SkillPaymentPolicy;

/// Returns whether the skill payment policy is agent funded.
public native fun payment_policy_is_agent_funded(policy: SkillPaymentPolicy): bool;

/// Returns the maximum budget of the payment policy, or zero for a user funded policy.
public native fun payment_policy_max_budget_mist(policy: SkillPaymentPolicy): u64;

/// Asserts that a payment source and budget satisfy the skill payment policy for the given agent.
/// Aborts if a user funded policy is not user funded, if an agent funded budget is zero or exceeds the policy maximum, or if the agent funded source's agent does not match.
public native fun assert_payment_policy(
    agent_id: sui::object::ID,
    policy: SkillPaymentPolicy,
    source: &PaymentSourceKind,
    max_budget_mist: u64,
);

/// Returns the agent id owning the execution payment.
public native fun payment_agent_id(payment: &ExecutionPayment): sui::object::ID;

/// Returns the skill id of the execution payment.
public native fun payment_skill_id(payment: &ExecutionPayment): u64;

/// Returns the interface revision the execution payment was created under.
public native fun payment_interface_revision(
    payment: &ExecutionPayment,
): nexus_interface::version::InterfaceVersion;

/// Returns the execution id the payment funds.
public native fun payment_execution_id(payment: &ExecutionPayment): address;

/// Returns the total amount consumed from the execution payment so far.
public native fun payment_consumed(payment: &ExecutionPayment): u64;

/// Returns the current balance of funds held by the execution payment.
public native fun payment_funds(payment: &ExecutionPayment): u64;

/// Returns the funding source of the execution payment.
public native fun payment_source_kind(payment: &ExecutionPayment): PaymentSourceKind;

/// Returns the MIST budget locked by the execution payment, including refills.
public native fun payment_locked_budget_mist(payment: &ExecutionPayment): u64;

/// Returns the execution payment's lifecycle final state.
public native fun payment_final_state(payment: &ExecutionPayment): ExecutionPaymentFinalState;

/// Returns the execution payment's total gas plus priority ceiling in MIST.
public native fun payment_max_budget_mist(payment: &ExecutionPayment): u64;

/// Returns the maximal transaction gas and Tool invocation budget in MIST.
public native fun payment_gas_budget_mist(payment: &ExecutionPayment): u64;

/// Returns the priority fee reserve in MIST derived from the total ceiling.
public native fun payment_priority_fee_reserve_mist(payment: &ExecutionPayment): u64;

/// Returns the priority fee percentage stored on the execution payment.
public native fun payment_priority_fee_percentage(payment: &ExecutionPayment): u64;

/// Returns the priority fee charged during terminal settlement.
public native fun payment_priority_fee_charged(payment: &ExecutionPayment): u64;

/// Returns whether the execution payment has been accomplished.
public native fun payment_accomplished(payment: &ExecutionPayment): bool;

/// Returns whether the execution payment has been refunded.
public native fun payment_refunded(payment: &ExecutionPayment): bool;

/// Returns the number of currently locked vertices on the execution payment.
public native fun payment_locks(payment: &ExecutionPayment): u64;

/// Returns the base execution funds still available to spend in MIST.
public native fun payment_available_funds(payment: &ExecutionPayment): u64;

/// Returns whether available funds can cover a vertex amount.
public native fun can_lock_payment_vertex_with_amount(
    payment: &ExecutionPayment,
    amount: u64,
): bool;

/// Returns whether an [`ExecutionPayment`] has frozen the supplied Tool price.
public native fun has_payment_tool_cost_snapshot(
    payment: &ExecutionPayment,
    tool_fqn: &vector<u8>,
): bool;

/// Returns the snapshotted cost for the given tool on the execution payment.
/// Aborts if no cost snapshot exists for the tool.
public native fun payment_tool_cost(payment: &ExecutionPayment, tool_fqn: vector<u8>): u64;

/// Returns the Task that owns the reserve.
public native fun task_payment_reserve_task_id(self: &TaskPaymentReserve): sui::object::ID;

/// Returns the agent id of the reserve.
public native fun task_payment_reserve_agent_id(self: &TaskPaymentReserve): sui::object::ID;

/// Returns the skill id of the reserve.
public native fun task_payment_reserve_skill_id(self: &TaskPaymentReserve): u64;

/// Returns the interface version of the reserve.
public native fun task_payment_reserve_interface_version(
    self: &TaskPaymentReserve,
): nexus_interface::version::InterfaceVersion;

/// Returns the id of the agent skill authorization bound to the reserve.
public native fun task_payment_reserve_authorization_id(self: &TaskPaymentReserve): sui::object::ID;

/// Returns the per occurrence budget of the reserve.
public native fun task_payment_reserve_occurrence_budget_mist(self: &TaskPaymentReserve): u64;

/// Returns the remaining funds held by the reserve.
public native fun task_payment_reserve_remaining_funds(self: &TaskPaymentReserve): u64;

/// Returns the funding source of the reserve.
public native fun task_payment_reserve_source_kind(self: &TaskPaymentReserve): PaymentSourceKind;

/// Returns the skill payment policy of the reserve.
public native fun task_payment_reserve_payment_policy(
    self: &TaskPaymentReserve,
): SkillPaymentPolicy;

/// Adds user funds to a [`TaskPaymentReserve`].
public native fun refill_task_payment_reserve_address_funded(
    reserve: &mut TaskPaymentReserve,
    coin: sui::coin::Coin<sui::sui::SUI>,
);

/// Returns all user funds held by a [`TaskPaymentReserve`].
public native fun cancel_task_payment_reserve_address_funded(
    reserve: &mut TaskPaymentReserve,
    ctx: &mut sui::tx_context::TxContext,
);

/// Accomplishes one Task execution and restores its unused funds.
public native fun accomplish_task_execution_payment(
    reserve: &mut TaskPaymentReserve,
    payment: &mut ExecutionPayment,
    occurrence_id: u64,
);

/// Refunds one Task execution and restores its unused funds.
public native fun refund_task_execution_payment(
    reserve: &mut TaskPaymentReserve,
    payment: &mut ExecutionPayment,
    occurrence_id: u64,
    refund_reason: vector<u8>,
);

/// Normalizes an optional priority fee percentage to the effective on chain value.
public native fun priority_fee_percentage(priority_fee_percentage: std::option::Option<u64>): u64;

/// Computes the priority fee in MIST as `floor(gas_budget_mist * priority_fee_percentage / 100)`.
public native fun priority_fee_mist_for_gas_budget(
    gas_budget_mist: u64,
    priority_fee_percentage: u64,
): u64;

/// Computes the maximal base gas budget and its priority reserve for a total MIST ceiling.
public native fun budget_split_mist(max_budget_mist: u64, priority_fee_percentage: u64): (u64, u64);

/// Computes the largest base gas budget that fits within a total MIST ceiling.
public native fun gas_budget_mist_for_max_budget_mist(
    max_budget_mist: u64,
    priority_fee_percentage: u64,
): u64;

/// Destroys a [`TaskPaymentReserve`] after all funds were returned.
public native fun destroy_empty_task_payment_reserve(reserve: TaskPaymentReserve);
