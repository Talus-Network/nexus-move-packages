module nexus_tool::tool_cashier;

//! Interface for [`nexus_tool::tool_cashier`].
//!
//! Calls resolve to the published package.

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
public native fun add_policy<P: drop>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    _: P,
);

/// Accepts policy witness [P] and stores its typed configuration.
public native fun add_policy_with_config<P: drop, C: store>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    policy: P,
    config: C,
);

/// Stops accepting configless policy witness [P].
///
/// Existing Invocations remain valid because their material terms are stored
/// in the exact [Invocation] objects.
public native fun remove_policy<P: drop>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    _: P,
);

/// Stops accepting policy witness [P] and returns its typed configuration.
public native fun remove_policy_with_config<P: drop, C: store>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    policy: P,
): C;

/// Returns the configuration for accepted policy witness [P].
public native fun policy_config<P: drop, C: store>(self: &ToolCashier, _: P): &C;

/// Returns mutable owner access to the configuration for policy witness [P].
public native fun policy_config_mut<P: drop, C: store>(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    _: P,
): &mut C;

/// Returns whether policy witness [P] is accepted for new invocations.
public native fun has_policy<P: drop>(self: &ToolCashier): bool;

/// Returns the accepted policy types for off chain discovery.
public native fun policies(self: &ToolCashier): &sui::vec_set::VecSet<std::type_name::TypeName>;

/// Derives the canonical policy account for [beneficiary].
public native fun derive_policy_account_id<P: drop>(
    cashier: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
): sui::object::ID;

/// Creates the canonical policy account for [beneficiary].
///
/// Creation mutates [ToolCashier] only when the account is first claimed.
public native fun new_policy_account<P: drop, State: store>(
    self: &mut ToolCashier,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    _: P,
    state: State,
): PolicyAccount<P, State>;

/// Shares a canonical policy account.
public native fun share_policy_account<P: drop, State: store>(account: PolicyAccount<P, State>);

/// Returns the canonical policy account ID.
public native fun policy_account_id<P: drop, State: store>(
    account: &PolicyAccount<P, State>,
): sui::object::ID;

/// Returns the cashier that created [account].
public native fun policy_account_cashier<P: drop, State: store>(
    account: &PolicyAccount<P, State>,
): sui::object::ID;

/// Returns the beneficiary authorized by [account].
public native fun policy_account_beneficiary<P: drop, State: store>(
    account: &PolicyAccount<P, State>,
): nexus_interface::payment::PaymentSourceKind;

/// Returns policy module access to the state in [account].
public native fun policy_account_state<P: drop, State: store>(
    account: &PolicyAccount<P, State>,
    _: P,
): &State;

/// Returns mutable policy module access to the state in [account].
public native fun policy_account_state_mut<P: drop, State: store>(
    account: &mut PolicyAccount<P, State>,
    _: P,
): &mut State;

/// Returns policy module access to the receiving identity of [account].
public native fun policy_account_uid_mut<P: drop, State: store>(
    account: &mut PolicyAccount<P, State>,
    _: P,
): &mut sui::object::UID;

/// Transfers SUI to the [ToolCashier] inbox.
public native fun send_deposit(
    self: &ToolCashier,
    funds: sui::balance::Balance<sui::sui::SUI>,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID;

/// Receives a batch of deposits under Tool owner authority.
public native fun collect_deposits(
    self: &mut ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
    deposits: vector<sui::transfer::Receiving<CashierDeposit>>,
): sui::balance::Balance<sui::sui::SUI>;

/// Returns the fully qualified name of the Tool served by [ToolCashier].
public native fun tool_fqn(self: &ToolCashier): std::ascii::String;

/// Returns the stable Tool object ID served by [ToolCashier].
public native fun tool(self: &ToolCashier): sui::object::ID;

/// Returns the object ID of [ToolCashier].
public native fun id(self: &ToolCashier): sui::object::ID;

/// Derives the stable [ToolCashier] ID for a Tool ID.
public native fun derive_id(tool: sui::object::ID): sui::object::ID;

/// Verifies exact Tool owner authority for policy module operations.
public native fun assert_owner(
    self: &ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<OverToolCashier>,
);
