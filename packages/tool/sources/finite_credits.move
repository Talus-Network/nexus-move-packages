/// Interface for the published [`nexus_tool::finite_credits`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_tool::finite_credits;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

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
public fun enable(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    price_per_credit: u64,
    minimum_credits: u64,
    maximum_credits: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Purchases credits, shares the canonical account, and transfers the prepaid
/// SUI to the cashier inbox.
public fun buy(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    pay_with: &mut sui::coin::Coin<sui::sui::SUI>,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    credits: u64,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Purchases units for an existing canonical credit account.
public fun buy_more(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    credits: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    pay_with: &mut sui::coin::Coin<sui::sui::SUI>,
    additional_credits: u64,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Stops purchases and owner issuance without invalidating existing accounts.
public fun close_issuance(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
) {
    abort ELocalExecutionUnavailable
}

/// Resumes purchases and owner issuance for canonical credit accounts.
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
    price_per_credit: u64,
    minimum_credits: u64,
    maximum_credits: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Returns the current finite credit offer.
public fun offer(cashier: &nexus_tool::tool_cashier::ToolCashier): (bool, u64, u64, u64) {
    abort ELocalExecutionUnavailable
}

/// Issues credits under Tool owner authority.
public fun issue(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    credits: u64,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::tool_cashier::PolicyAccount<Policy, State> {
    abort ELocalExecutionUnavailable
}

/// Adds an owner granted amount to an existing canonical credit account.
public fun issue_more(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    credits: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    additional_credits: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Decrements [State] and creates an [Invocation] holding one prepaid unit.
///
/// The held [CreditReserve] is a unit marker, not an execution payment reserve.
/// The Invocation therefore records zero SUI and names [credits] as its exact
/// accounting source.
public fun get_invocation(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    credits: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    request: nexus_interface::payment::InvocationRequest,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::invocation::Invocation {
    abort ELocalExecutionUnavailable
}

/// Restores one exact refunded unit to its canonical credit account.
public fun restore_refund(
    credits: &mut nexus_tool::tool_cashier::PolicyAccount<Policy, State>,
    receiving: sui::transfer::Receiving<nexus_tool::invocation::Invocation>,
) {
    abort ELocalExecutionUnavailable
}

/// Collects finalized credit Invocations and consumes their reserved units.
public fun collect(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    invocations: vector<sui::transfer::Receiving<nexus_tool::invocation::Invocation>>,
): sui::balance::Balance<sui::sui::SUI> {
    abort ELocalExecutionUnavailable
}

/// Shares a canonical credit [PolicyAccount] for runtime admission.
public fun share(credits: nexus_tool::tool_cashier::PolicyAccount<Policy, State>) {
    abort ELocalExecutionUnavailable
}

/// Returns the units currently available in [self].
public fun remaining(self: &nexus_tool::tool_cashier::PolicyAccount<Policy, State>): u64 {
    abort ELocalExecutionUnavailable
}

/// Derives the canonical finite credit account for [beneficiary].
public fun derive_id(
    cashier: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}
