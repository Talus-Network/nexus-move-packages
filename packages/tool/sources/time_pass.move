/// Interface for the published [`nexus_tool::time_pass`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_tool::time_pass;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Private construction witness for this policy.
public struct Policy has drop {}

/// Owner configured sale terms for time passes.
public struct Config has store {
    issuance_enabled: bool,
    price_per_ms: u64,
    minimum_duration_ms: u64,
    maximum_duration_ms: u64,
}

/// Policy state for one inclusive start and exclusive end window.
public struct State has store {
    valid_from_ms: u64,
    valid_until_ms: u64,
}

/// Records creation of one canonical time pass [PolicyAccount].
public struct TimePassCreatedEvent has copy, drop {
    tool: sui::object::ID,
    cashier: sui::object::ID,
    pass: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    valid_from_ms: u64,
    valid_until_ms: u64,
}

/// Records the complete commercial offer for future time pass purchases.
public struct TimePassOfferChangedEvent has copy, drop {
    cashier: sui::object::ID,
    issuance_enabled: bool,
    price_per_ms: u64,
    minimum_duration_ms: u64,
    maximum_duration_ms: u64,
}

/// Enables time pass admission and sales.
public fun enable(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    price_per_ms: u64,
    minimum_duration_ms: u64,
    maximum_duration_ms: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Purchases and shares a pass while transferring prepaid SUI to the cashier.
public fun buy(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    pay_with: &mut sui::coin::Coin<sui::sui::SUI>,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    duration_ms: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Purchases more duration for an existing canonical time pass account.
public fun buy_more(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    pass: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    pay_with: &mut sui::coin::Coin<sui::sui::SUI>,
    duration_ms: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Stops purchases and owner issuance without invalidating existing passes.
public fun close_issuance(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
) {
    abort ELocalExecutionUnavailable
}

/// Resumes purchases and owner issuance for canonical time pass accounts.
public fun open_issuance(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
) {
    abort ELocalExecutionUnavailable
}

/// Replaces the sale terms used only for future purchases and grants.
public fun update_terms(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    price_per_ms: u64,
    minimum_duration_ms: u64,
    maximum_duration_ms: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Returns the current time pass offer.
public fun offer(cashier: &nexus_tool::tool_cashier::ToolCashier): (bool, u64, u64, u64) {
    abort ELocalExecutionUnavailable
}

/// Issues a time pass under Tool owner authority.
public fun issue(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    valid_from_ms: u64,
    valid_until_ms: u64,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::tool_cashier::PolicyAccount<Policy, State> {
    abort ELocalExecutionUnavailable
}

/// Replaces the validity window of an existing canonical pass.
public fun update_window(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    pass: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    valid_from_ms: u64,
    valid_until_ms: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Creates an Invocation when admission occurs inside the pass window.
///
/// Validity is evaluated at [InvocationRequest] authorization time. The start
/// is inclusive and the end is exclusive.
public fun get_invocation(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    pass: &nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    request: nexus_interface::payment::InvocationRequest,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::invocation::Invocation {
    abort ELocalExecutionUnavailable
}

/// Collects finalized time pass Invocations under Tool owner authority.
public fun collect(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    invocations: vector<sui::transfer::Receiving<nexus_tool::invocation::Invocation>>,
): sui::balance::Balance<sui::sui::SUI> {
    abort ELocalExecutionUnavailable
}

/// Derives the canonical time pass account for [beneficiary].
public fun derive_id(
    cashier: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Shares a time pass account for concurrent admission reads.
public fun share(pass: nexus_tool::tool_cashier::PolicyAccount<Policy, State>) {
    abort ELocalExecutionUnavailable
}

/// Returns the inclusive start and exclusive end of [pass].
public fun window(pass: &nexus_tool::tool_cashier::PolicyAccount<Policy, State>): (u64, u64) {
    abort ELocalExecutionUnavailable
}
