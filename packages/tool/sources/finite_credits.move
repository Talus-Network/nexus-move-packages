module nexus_tool::finite_credits;

//! Interface for [`nexus_tool::finite_credits`].
//!
//! Calls resolve to the published package.

/// Private construction witness for this policy.
public struct Policy has drop {}

/// Owner configured sale terms for finite credits.
public struct Config has store {
    issuance_enabled: bool,
    price_per_credit: u64,
    minimum_credits: u64,
    maximum_credits: u64,
}

/// Policy state stored in one beneficiary's canonical account.
public struct State has store {
    remaining: u64,
}

/// One prepaid unit held by an in flight [Invocation].
///
/// [CreditReserve] carries no SUI. Payment occurs when credits are purchased;
/// this marker preserves one unit until finalization or refund.
public struct CreditReserve has store {}

/// Records creation of one canonical finite credit [PolicyAccount].
public struct CreditsCreatedEvent has copy, drop {
    tool: sui::object::ID,
    cashier: sui::object::ID,
    credits: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    remaining: u64,
}

/// Records the complete commercial offer for future credit purchases.
public struct CreditOfferChangedEvent has copy, drop {
    cashier: sui::object::ID,
    issuance_enabled: bool,
    price_per_credit: u64,
    minimum_credits: u64,
    maximum_credits: u64,
}

/// Enables finite credit admission and sales.
public native fun enable(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    price_per_credit: u64,
    minimum_credits: u64,
    maximum_credits: u64,
);

/// Purchases credits, shares the canonical account, and transfers the prepaid
/// SUI to the cashier inbox.
public native fun buy(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    pay_with: &mut sui::coin::Coin<sui::sui::SUI>,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    credits: u64,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID;

/// Purchases units for an existing canonical credit account.
public native fun buy_more(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    credits: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    pay_with: &mut sui::coin::Coin<sui::sui::SUI>,
    additional_credits: u64,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID;

/// Stops purchases and owner issuance without invalidating existing accounts.
public native fun close_issuance(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
);

/// Resumes purchases and owner issuance for canonical credit accounts.
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
    price_per_credit: u64,
    minimum_credits: u64,
    maximum_credits: u64,
);

/// Returns the current finite credit offer.
public native fun offer(cashier: &nexus_tool::tool_cashier::ToolCashier): (bool, u64, u64, u64);

/// Issues credits under Tool owner authority.
public native fun issue(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    credits: u64,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::tool_cashier::PolicyAccount<Policy, State>;

/// Adds an owner granted amount to an existing canonical credit account.
public native fun issue_more(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    credits: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    additional_credits: u64,
);

/// Decrements [State] and creates an [Invocation] holding one prepaid unit.
///
/// The held [CreditReserve] is a unit marker, not an execution payment reserve.
/// The Invocation therefore records zero SUI and names [credits] as its exact
/// accounting source.
public native fun get_invocation(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    credits: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    request: nexus_interface::payment::InvocationRequest,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::invocation::Invocation;

/// Restores one exact refunded unit to its canonical credit account.
public native fun restore_refund(
    credits: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    receiving: sui::transfer::Receiving<nexus_tool::invocation::Invocation>,
);

/// Collects finalized credit Invocations and consumes their reserved units.
public native fun collect(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    invocations: vector<sui::transfer::Receiving<nexus_tool::invocation::Invocation>>,
): sui::balance::Balance<sui::sui::SUI>;

/// Shares a canonical credit [PolicyAccount] for runtime admission.
public native fun share(credits: nexus_tool::tool_cashier::PolicyAccount<Policy, State>);

/// Returns the units currently available in [self].
public native fun remaining(self: &nexus_tool::tool_cashier::PolicyAccount<Policy, State>): u64;

/// Derives the canonical finite credit account for [beneficiary].
public native fun derive_id(
    cashier: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
): sui::object::ID;
