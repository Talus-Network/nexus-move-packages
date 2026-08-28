module nexus_registry::priority_fee_vault;

//! Interface for [`nexus_registry::priority_fee_vault`].
//!
//! Calls resolve to the published package.

public struct PriorityFeeVault has key {
    id: sui::object::UID,
}

/// Version one stored layout for [`PriorityFeeVault`].
public struct PriorityFeeVaultInnerV1 has store {
    sui_balance: sui::balance::Balance<sui::sui::SUI>,
    us_balance: sui::balance::Balance<talus::us::US>,
    exchange_rate_million_mists_us: u64,
    total_share: u64,
    leader_accounts: sui::vec_map::VecMap<sui::object::ID, PriorityFeeAccount>,
}

public struct PriorityFeeAccount has copy, drop, store {
    share: u64,
}

public struct PriorityFeeVaultOwnerCap has key, store {
    id: sui::object::UID,
    vault: sui::object::ID,
}

/// Receiving child transferred to the vault before atomic collection.
public struct PriorityFeeDeposit has key {
    id: sui::object::UID,
    amount: sui::balance::Balance<sui::sui::SUI>,
    leader_cap_id: sui::object::ID,
}

/// Identifies a newly object owned deposit.
public struct PriorityFeeDepositCreatedEvent has copy, drop {
    vault: sui::object::ID,
    deposit_id: sui::object::ID,
    leader_cap_id: sui::object::ID,
    amount: u64,
}

/// One leader's aggregate share increase in a successful collection batch.
public struct PriorityFeeShareChange has copy, drop {
    leader_cap_id: sui::object::ID,
    share_delta: u64,
}

/// Aggregate accounting changes emitted once for a successful collection batch.
public struct PriorityFeeSharesCollectedEvent has copy, drop {
    vault: sui::object::ID,
    deposit_count: u64,
    changes: vector<PriorityFeeShareChange>,
    total_share_delta: u64,
}

public struct PriorityFeeWithdrawnEvent has copy, drop {
    vault: sui::object::ID,
    leader_cap_id: sui::object::ID,
    share_to_withdraw: u64,
    us_out: u64,
    us_refunded: u64,
}

public struct PriorityFeeSwapEvent has copy, drop {
    vault: sui::object::ID,
    us_in: u64,
    us_refunded: u64,
    sui_out: u64,
}

public struct PriorityFeeVaultConfiguredEvent has copy, drop {
    vault: sui::object::ID,
    exchange_rate_million_mists_us: u64,
}

/// Transfers SUI to the [`PriorityFeeVault`] address as a deposit the vault can receive.
public native fun create_deposit(
    self: &PriorityFeeVault,
    amount: sui::balance::Balance<sui::sui::SUI>,
    leader_cap_id: sui::object::ID,
    ctx: &mut sui::tx_context::TxContext,
);

/// Receives and accounts for an atomic batch of deposits held at the vault address.
public native fun collect_deposits(
    self: &mut PriorityFeeVault,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    deposits: vector<sui::transfer::Receiving<PriorityFeeDeposit>>,
);

public native fun swap_us_for_sui(
    self: &mut PriorityFeeVault,
    input: sui::coin::Coin<talus::us::US>,
    min_sui_out: u64,
    ctx: &mut sui::tx_context::TxContext,
): (sui::coin::Coin<sui::sui::SUI>, sui::coin::Coin<talus::us::US>);

public native fun withdraw_priority_fee(
    self: &mut PriorityFeeVault,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    share_to_withdraw: u64,
    ctx: &mut sui::tx_context::TxContext,
): sui::coin::Coin<talus::us::US>;

public native fun configure(
    self: &mut PriorityFeeVault,
    owner_cap: &PriorityFeeVaultOwnerCap,
    exchange_rate_million_mists_us: u64,
);

public native fun leader_account(self: &PriorityFeeVault, leader_cap_id: sui::object::ID): u64;

public native fun exchange_rate_million_mists_us(self: &PriorityFeeVault): u64;

public native fun total_share(self: &PriorityFeeVault): u64;

public native fun sui_balance(self: &PriorityFeeVault): u64;

public native fun us_balance(self: &PriorityFeeVault): u64;

public native fun quote_swap_us_for_sui(self: &PriorityFeeVault, us_in: u64): u64;
