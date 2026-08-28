module nexus_tool::time_pass;

//! Interface for [`nexus_tool::time_pass`].
//!
//! Calls resolve to the published package.

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
public native fun enable(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    price_per_ms: u64,
    minimum_duration_ms: u64,
    maximum_duration_ms: u64,
);

/// Purchases and shares a pass while transferring prepaid SUI to the cashier.
public native fun buy(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    pay_with: &mut sui::coin::Coin<sui::sui::SUI>,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    duration_ms: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID;

/// Purchases more duration for an existing canonical time pass account.
public native fun buy_more(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    pass: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    pay_with: &mut sui::coin::Coin<sui::sui::SUI>,
    duration_ms: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID;

/// Stops purchases and owner issuance without invalidating existing passes.
public native fun close_issuance(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
);

/// Resumes purchases and owner issuance for canonical time pass accounts.
public native fun open_issuance(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
);

/// Replaces the sale terms used only for future purchases and grants.
public native fun update_terms(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    price_per_ms: u64,
    minimum_duration_ms: u64,
    maximum_duration_ms: u64,
);

/// Returns the current time pass offer.
public native fun offer(cashier: &nexus_tool::tool_cashier::ToolCashier): (bool, u64, u64, u64);

/// Issues a time pass under Tool owner authority.
public native fun issue(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    valid_from_ms: u64,
    valid_until_ms: u64,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::tool_cashier::PolicyAccount<Policy, State>;

/// Replaces the validity window of an existing canonical pass.
public native fun update_window(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    pass: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    valid_from_ms: u64,
    valid_until_ms: u64,
);

/// Creates an Invocation when admission occurs inside the pass window.
///
/// Validity is evaluated at [InvocationRequest] authorization time. The start
/// is inclusive and the end is exclusive.
public native fun get_invocation(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    pass: &nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    request: nexus_interface::payment::InvocationRequest,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::invocation::Invocation;

/// Collects finalized time pass Invocations under Tool owner authority.
public native fun collect(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    invocations: vector<sui::transfer::Receiving<nexus_tool::invocation::Invocation>>,
): sui::balance::Balance<sui::sui::SUI>;

/// Derives the canonical time pass account for [beneficiary].
public native fun derive_id(
    cashier: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
): sui::object::ID;

/// Shares a time pass account for concurrent admission reads.
public native fun share(pass: nexus_tool::tool_cashier::PolicyAccount<Policy, State>);

/// Returns the inclusive start and exclusive end of [pass].
public native fun window(pass: &nexus_tool::tool_cashier::PolicyAccount<Policy, State>): (u64, u64);
