/// Interface for the published [`nexus_tool::tool_cashier`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_tool::tool_cashier;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Shared policy directory and completed invocation inbox for one Tool.
public struct ToolCashier has key {
    id: sui::object::UID,
}

/// Version one stored layout for [`ToolCashier`].
public struct ToolCashierInnerV1 has store {
    tool: sui::object::ID,
    tool_fqn: std::ascii::String,
    policies: sui::vec_set::VecSet<std::type_name::TypeName>,
}

/// Authorization marker for delegated [ToolCashier] administration.
public struct OverToolCashier has drop {}

/// Typed key for the [ToolCashier] derived from a Tool.
public struct ToolCashierKey() has copy, drop, store;

/// Typed configuration key for policy witness [P].
public struct PolicyKey<phantom P: drop>() has copy, drop, store;

/// Canonical account slot for policy [P] and one payment beneficiary.
public struct PolicyAccountKey<phantom P: drop>(
    nexus_interface::payment::PaymentSourceKind,
) has copy, drop, store;

/// Canonical beneficiary account containing state defined by policy [P].
public struct PolicyAccount<phantom P: drop, State: store> has key {
    id: sui::object::UID,
    cashier: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    state: State,
}

/// SUI transferred to a cashier for later owner collection.
public struct CashierDeposit has key {
    id: sui::object::UID,
    funds: sui::balance::Balance<sui::sui::SUI>,
}

/// Identifies one deposit transferred to a [ToolCashier].
public struct CashierDepositCreatedEvent has copy, drop {
    cashier: sui::object::ID,
    deposit: sui::object::ID,
    amount: u64,
}

/// Records that a [ToolCashier] accepts a policy for new [Invocation] objects.
public struct PolicyAddedEvent has copy, drop {
    cashier: sui::object::ID,
    policy: std::type_name::TypeName,
}

/// Records that a [ToolCashier] no longer accepts a policy.
public struct PolicyRemovedEvent has copy, drop {
    cashier: sui::object::ID,
    policy: std::type_name::TypeName,
}

/// Accepts configless policy witness [P].
public fun add_policy<P: drop>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    _: P,
) {
    abort ELocalExecutionUnavailable
}

/// Accepts policy witness [P] and stores its typed configuration.
public fun add_policy_with_config<P: drop, C: store>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    policy: P,
    config: C,
) {
    abort ELocalExecutionUnavailable
}

/// Stops accepting configless policy witness [P].
///
/// Existing Invocations remain valid because their material terms are stored
/// in the exact [Invocation] objects.
public fun remove_policy<P: drop>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    _: P,
) {
    abort ELocalExecutionUnavailable
}

/// Stops accepting policy witness [P] and returns its typed configuration.
public fun remove_policy_with_config<P: drop, C: store>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    policy: P,
): C {
    abort ELocalExecutionUnavailable
}

/// Returns the configuration for accepted policy witness [P].
public fun policy_config<P: drop, C: store>(self: &ToolCashier, _: P): &C {
    abort ELocalExecutionUnavailable
}

/// Returns mutable owner access to the configuration for policy witness [P].
public fun policy_config_mut<P: drop, C: store>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    _: P,
): &mut C {
    abort ELocalExecutionUnavailable
}

/// Returns whether policy witness [P] is accepted for new invocations.
public fun has_policy<P: drop>(self: &ToolCashier): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the accepted policy types for off chain discovery.
public fun policies(self: &ToolCashier): &sui::vec_set::VecSet<std::type_name::TypeName> {
    abort ELocalExecutionUnavailable
}

/// Derives the canonical policy account for [beneficiary].
public fun derive_policy_account_id<P: drop>(
    cashier: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Creates the canonical policy account for [beneficiary].
///
/// Creation mutates [ToolCashier] only when the account is first claimed.
public fun new_policy_account<P: drop, State: store>(
    self: &mut ToolCashier,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    _: P,
    state: State,
): PolicyAccount<P, State> {
    abort ELocalExecutionUnavailable
}

/// Shares a canonical policy account.
public fun share_policy_account<P: drop, State: store>(account: PolicyAccount<P, State>) {
    abort ELocalExecutionUnavailable
}

/// Returns the canonical policy account ID.
public fun policy_account_id<P: drop, State: store>(
    account: &PolicyAccount<P, State>,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the cashier that created [account].
public fun policy_account_cashier<P: drop, State: store>(
    account: &PolicyAccount<P, State>,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the beneficiary authorized by [account].
public fun policy_account_beneficiary<P: drop, State: store>(
    account: &PolicyAccount<P, State>,
): nexus_interface::payment::PaymentSourceKind {
    abort ELocalExecutionUnavailable
}

/// Returns policy module access to the state in [account].
public fun policy_account_state<P: drop, State: store>(
    account: &PolicyAccount<P, State>,
    _: P,
): &State {
    abort ELocalExecutionUnavailable
}

/// Returns mutable policy module access to the state in [account].
public fun policy_account_state_mut<P: drop, State: store>(
    account: &mut PolicyAccount<P, State>,
    _: P,
): &mut State {
    abort ELocalExecutionUnavailable
}

/// Returns policy module access to the receiving identity of [account].
public fun policy_account_uid_mut<P: drop, State: store>(
    account: &mut PolicyAccount<P, State>,
    _: P,
): &mut sui::object::UID {
    abort ELocalExecutionUnavailable
}

/// Transfers SUI to the [ToolCashier] inbox.
public fun send_deposit(
    self: &ToolCashier,
    funds: sui::balance::Balance<sui::sui::SUI>,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Receives a batch of deposits under Tool owner authority.
public fun collect_deposits(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    deposits: vector<sui::transfer::Receiving<CashierDeposit>>,
): sui::balance::Balance<sui::sui::SUI> {
    abort ELocalExecutionUnavailable
}

/// Returns the fully qualified name of the Tool served by [ToolCashier].
public fun tool_fqn(self: &ToolCashier): std::ascii::String {
    abort ELocalExecutionUnavailable
}

/// Returns the stable Tool object ID served by [ToolCashier].
public fun tool(self: &ToolCashier): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the object ID of [ToolCashier].
public fun id(self: &ToolCashier): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Derives the stable [ToolCashier] ID for a Tool ID.
public fun derive_id(tool: sui::object::ID): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Verifies exact Tool owner authority for policy module operations.
public fun assert_owner(
    self: &ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
) {
    abort ELocalExecutionUnavailable
}
