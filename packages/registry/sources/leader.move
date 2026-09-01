/// Interface for the published [`nexus_registry::leader`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_registry::leader;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Leader liveness/eligibility status.
public enum LeaderStatus has copy, drop, store {
    /// Eligible for committee membership and off chain work.
    Active,
    /// Temporarily disabled (operator error, maintenance, etc.).
    Suspended,
    /// Slashed/evicted (ineligible).
    Slashed,
}

/// Admin capability for modifying the allowlist in [CapabilityManger].
public struct LeaderCapabilitiesAdminCap has key, store {
    id: sui::object::UID,
    registry: sui::object::ID,
}

/// Leader capability issuer state stored inside [LeaderRegistry].
public struct CapabilityManger has store {
    /// Addresses allowed to request capabilities.
    allowed_addresses: sui::vec_set::VecSet<address>,
    /// Network ID used by all issued [leader_cap::OverNetwork] objects.
    network_id: sui::object::ID,
    /// Shared leader admin capability object ID.
    admin_cap_id: sui::object::ID,
    /// Issuer for [leader_cap::OverNetwork].
    leader_cap_issuer: nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
}

/// Shared registry for leader operator records and pooled stake.
///
/// This is intended to be created once (by the workflow package initializer) and shared.
public struct LeaderRegistry has key {
    id: sui::object::UID,
}

/// Version one stored layout for [`LeaderRegistry`].
public struct LeaderRegistryInnerV1 has store {
    /// Unbonding delay for stake withdrawals.
    unbonding_duration_ms: u64,
    /// Minimum stake (in US base units) required for a leader to be eligible for ranking.
    min_stake_us: u64,
    /// Maximum budget (in MIST) a leader may spend on a single transaction.
    max_transaction_budget: u64,
    /// Discoverable set of registered leader capability IDs.
    leaders: sui::vec_set::VecSet<sui::object::ID>,
    /// Per leader record keyed by leader capability ID.
    records: sui::table::Table<sui::object::ID, Leader>,
    /// Capability issuer state.
    capabilities: CapabilityManger,
}

/// Per leader stake accounting (stored inside [Leader]).
public struct StakeManager<phantom StakeCoin> has store {
    /// Total pooled stake backing all shares for this leader.
    pool: sui::balance::Balance<StakeCoin>,
    /// Total stake shares for this leader.
    ///
    /// Users hold shares in [`StakePosition`]. Value is proportional:
    /// `value(shares) = pool * shares / total_shares`.
    total_shares: u64,
    /// Stake positions for third party staking: `staker -> position`.
    positions: sui::table::Table<address, StakePosition>,
}

/// Per-(leader, staker) stake position.
///
/// Pending shares remain exposed to slashing because they still participate in the pool.
public struct StakePosition has drop, store {
    active_shares: u64,
    pending_shares: u64,
    pending_requested_at_ms: std::option::Option<u64>,
}

/// Arbitrary operator provided metadata for a leader record.
///
/// This module does not interpret these values. The only enforced constraint is a size bound:
/// `bcs::to_bytes(&meta).length() <= MAX_META_LEN`.
public struct Metadata has copy, drop, store {
    data: sui::vec_map::VecMap<std::string::String, std::string::String>,
}

/// Per leader record stored in [LeaderRegistry].
///
/// The record is keyed by the leader's capability ID (`ID`) inside the registry table.
public struct Leader has store {
    /// Status of this leader.
    status: LeaderStatus,
    /// Opaque operator metadata (optional; application defined).
    meta: Metadata,
    /// Per leader stake accounting.
    stake_manager: StakeManager<talus::us::US>,
    /// Unique ownership token of the current activation.
    ///
    /// Set to the activating transaction's own digest (`*ctx.digest()`), which Sui
    /// guarantees is globally unique. A suspension only takes effect if it presents
    /// the exact token on record, so only the instance that passes the current `Active`
    /// state can suspend it. The assumption is that each instance passes the
    /// correct token.
    claim_token: vector<u8>,
}

/// Emitted when a new [LeaderRegistry] is created.
public struct LeaderRegistryCreatedEvent has copy, drop {
    registry: sui::object::ID,
}

/// Emitted when a leader record is created or updated via [upsert_self].
public struct LeaderUpsertedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    status: LeaderStatus,
}

/// Emitted when a leader capability is issued and transferred.
///
/// This is the authoritative off chain signal that a new leader cap ID exists
/// for this registry/network.
public struct LeaderCapIssuedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    network: sui::object::ID,
    leader: address,
}

/// Emitted when a leader's status changes, e.g. via [set_status], a suspension
/// through [suspend_if_token], or a `Suspended -> Active` transition in
/// [activate_and_claim].
public struct LeaderStatusChangedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    old_status: LeaderStatus,
    new_status: LeaderStatus,
}

/// Emitted when a leader claims (or re claims) ownership of the `Active` state via
/// [activate_and_claim]. `claim_token` is the activating transaction's own digest.
public struct LeaderClaimedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    claim_token: vector<u8>,
}

/// Emitted when [suspend_if_token] is called by an instance that does not own the
/// current `Active` state (the presented token does not match the one on record).
/// The suspension is skipped.
public struct LeaderSuspensionSkippedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    attempted: vector<u8>,
    owner: vector<u8>,
}

/// Emitted when the registry's unbonding duration is updated.
public struct UnbondingDurationUpdatedEvent has copy, drop {
    registry: sui::object::ID,
    unbonding_duration_ms: u64,
}

/// Emitted when the registry's minimum eligible stake is updated.
public struct MinStakeUsUpdatedEvent has copy, drop {
    registry: sui::object::ID,
    min_stake_us: u64,
}

/// Emitted when the registry's per transaction max budget is updated.
public struct MaxTransactionBudgetUpdatedEvent has copy, drop {
    registry: sui::object::ID,
    max_transaction_budget: u64,
}

/// Emitted when stake is deposited into a leader pool and shares are minted.
public struct StakeDepositedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    staker: address,
    amount: u64,
    minted_shares: u64,
    total_shares: u64,
    pool_total: u64,
    at_ms: u64,
}

/// Emitted when a staker requests an unstake, locking shares until the unlock time.
public struct UnstakeRequestedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    staker: address,
    shares: u64,
    unlock_at_ms: u64,
}

/// Emitted when a staker claims a matured unstake and receives the withdrawn US.
public struct UnstakeClaimedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    staker: address,
    shares: u64,
    amount: u64,
    at_ms: u64,
}

/// Emitted when a leader's pooled stake is slashed.
public struct StakeSlashedEvent has copy, drop {
    registry: sui::object::ID,
    leader_cap_id: sui::object::ID,
    amount: u64,
    at_ms: u64,
}

/// Returns the registry's unbonding delay (in milliseconds) for stake withdrawals.
public fun unbonding_duration_ms(self: &LeaderRegistry): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns the minimum stake (in US base units) a leader needs to be eligible for ranking.
public fun min_stake_us(self: &LeaderRegistry): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns the maximum budget (in MIST) a leader may spend on a single transaction.
public fun max_transaction_budget(self: &LeaderRegistry): u64 {
    abort ELocalExecutionUnavailable
}

/// Verifies that one reimbursed transaction respects the [`LeaderRegistry`] gas ceiling.
public fun assert_transaction_budget(self: &LeaderRegistry, gas_charge: u64) {
    abort ELocalExecutionUnavailable
}

/// Returns the network ID shared by all leader capabilities issued by this registry.
public fun network_id(self: &LeaderRegistry): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Anyone can query the expected stamp ID (for tool configuration).
/// This is the same as the registry's object ID.
public fun leader_stamp_id(self: &LeaderRegistry): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the `Active` leader status value.
public fun status_active(): LeaderStatus {
    abort ELocalExecutionUnavailable
}

/// Returns the `Suspended` leader status value.
public fun status_suspended(): LeaderStatus {
    abort ELocalExecutionUnavailable
}

/// Returns the `Slashed` leader status value.
public fun status_slashed(): LeaderStatus {
    abort ELocalExecutionUnavailable
}

/// Creates a metadata container from pre defined key/value pairs.
public fun new_metadata(
    data: sui::vec_map::VecMap<std::string::String, std::string::String>,
): Metadata {
    abort ELocalExecutionUnavailable
}

/// Returns an empty metadata container.
public fun empty_metadata(): Metadata {
    abort ELocalExecutionUnavailable
}

/// Returns whether a leader record exists for the given capability ID.
public fun exists(self: &LeaderRegistry, leader_cap_id: sui::object::ID): bool {
    abort ELocalExecutionUnavailable
}

/// Aborts with [ELeaderNotRegistered] unless a record exists for the capability ID.
public fun assert_registered(self: &LeaderRegistry, leader_cap_id: sui::object::ID) {
    abort ELocalExecutionUnavailable
}

/// Aborts when any execution input references an issued LeaderCap.
public fun assert_execution_inputs_allowed(
    self: &LeaderRegistry,
    operation: &nexus_interface::agent::ExecutionSpec,
) {
    abort ELocalExecutionUnavailable
}

/// Aborts when any explicit output Object field references an issued LeaderCap.
public fun assert_output_objects_allowed(
    self: &LeaderRegistry,
    output: &sui::vec_map::VecMap<
        nexus_interface::graph::OutputPort,
        nexus_primitives::data::NexusData,
    >,
) {
    abort ELocalExecutionUnavailable
}

/// Returns the current status of a leader record.
///
/// Aborts with [ELeaderNotFound] if the leader has no record.
public fun status(self: &LeaderRegistry, leader_cap_id: sui::object::ID): LeaderStatus {
    abort ELocalExecutionUnavailable
}

/// Returns the current ownership claim token for a leader record.
///
/// Aborts with [ELeaderNotFound] if the leader has no record.
public fun claim_token(self: &LeaderRegistry, leader_cap_id: sui::object::ID): vector<u8> {
    abort ELocalExecutionUnavailable
}

/// Returns whether a leader record exists and has status `Active`.
public fun is_active(self: &LeaderRegistry, leader_cap_id: sui::object::ID): bool {
    abort ELocalExecutionUnavailable
}

/// Returns whether a leader is active and sufficiently staked.
public fun is_eligible(self: &LeaderRegistry, leader_cap_id: sui::object::ID): bool {
    abort ELocalExecutionUnavailable
}

/// Asserts that a leader is active.
///
/// Aborts with [ELeaderNotActive] if the leader is missing or not active.
public fun assert_active(self: &LeaderRegistry, leader_cap_id: sui::object::ID) {
    abort ELocalExecutionUnavailable
}

/// Returns the metadata for a leader record.
///
/// Aborts with [ELeaderNotFound] if the leader has not registered a record.
public fun metadata(self: &LeaderRegistry, leader_cap_id: sui::object::ID): &Metadata {
    abort ELocalExecutionUnavailable
}

/// Convenience getter for the underlying key/value map inside [Metadata].
public fun metadata_data(
    self: &Metadata,
): &sui::vec_map::VecMap<std::string::String, std::string::String> {
    abort ELocalExecutionUnavailable
}

/// Returns the total pooled stake (in US base units) backing a leader.
///
/// Aborts with [ELeaderNotFound] if the leader has no record.
public fun leader_pool_total(self: &LeaderRegistry, leader_cap_id: sui::object::ID): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns the total stake shares outstanding for a leader.
///
/// Aborts with [ELeaderNotFound] if the leader has no record.
public fun leader_total_shares(self: &LeaderRegistry, leader_cap_id: sui::object::ID): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns a staker's active (non pending) shares in a leader pool, or 0 if none.
///
/// Aborts with [ELeaderNotFound] if the leader has no record.
public fun staker_active_shares(
    self: &LeaderRegistry,
    leader_cap_id: sui::object::ID,
    staker: address,
): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns a staker's pending (unstake locked) shares in a leader pool, or 0 if none.
///
/// Aborts with [ELeaderNotFound] if the leader has no record.
public fun staker_pending_shares(
    self: &LeaderRegistry,
    leader_cap_id: sui::object::ID,
    staker: address,
): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns a staker's total (active plus pending) shares in a leader pool.
///
/// Aborts with [ELeaderNotFound] if the leader has no record.
public fun staker_total_shares(
    self: &LeaderRegistry,
    leader_cap_id: sui::object::ID,
    staker: address,
): u64 {
    abort ELocalExecutionUnavailable
}

/// Current stake value (in US base units) for a staker in the given leader pool.
///
/// Returns 0 if either:
/// - the leader has no shares, or
/// - the staker has no shares.
public fun staker_value(
    self: &LeaderRegistry,
    leader_cap_id: sui::object::ID,
    staker: address,
): u64 {
    abort ELocalExecutionUnavailable
}

/// Upsert the sender's leader record.
///
/// Requires a leader capability for this workflow instance.
///
/// Behavior:
/// - Keyed by `object::id(leader_cap)`.
/// - `leader_cap` must belong to this registry network.
/// - Updates metadata for an existing record when called by the holder of the leader cap.
/// - Enforces a size bound on `meta` via `bcs::to_bytes(&meta)` (see [MAX_META_LEN]).
public fun upsert_self(
    self: &mut LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    meta: Metadata,
) {
    abort ELocalExecutionUnavailable
}

/// Stake `amount` (MIST) into a leader's pool.
///
/// Anyone can stake into any active leader. Staking mints shares for the caller based on the
/// current pool value and total shares.
public fun stake(
    self: &mut LeaderRegistry,
    leader_cap_id: sui::object::ID,
    pay_with: &mut sui::coin::Coin<talus::us::US>,
    amount: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Request to unstake `amount` (MIST) from a leader pool.
///
/// This converts `amount` into shares at the current share price, moves those shares from the
/// caller's active position into a pending position, and records the request timestamp.
public fun request_unstake(
    self: &mut LeaderRegistry,
    leader_cap_id: sui::object::ID,
    amount: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

public fun assert_leader_cap_matches_registry(
    self: &LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
) {
    abort ELocalExecutionUnavailable
}

/// Asserts that the concrete leader capability belongs to and is currently listed by this registry.
public fun assert_current_leader_cap(
    self: &LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
) {
    abort ELocalExecutionUnavailable
}

/// Return the top 2 leaders from a uniform deterministic ranking over all active leaders in this
/// registry.
///
/// Aborts with [EEmptyLeaderSet] if there are no eligible leaders (see [is_eligible]). If exactly
/// one eligible leader remains, it is duplicated to produce a length 2 result.
public fun rank_active_leaders_uniform<W: drop>(
    self: &LeaderRegistry,
    seed: &vector<u8>,
): vector<sui::object::ID> {
    abort ELocalExecutionUnavailable
}

/// Return the top 2 leaders from a stake weighted deterministic ranking over all active leaders
/// in this registry.
///
/// Aborts with [EEmptyLeaderSet] if there are no eligible leaders (see [is_eligible]). If exactly
/// one eligible leader remains, it is duplicated to produce a length 2 result.
public fun rank_active_leaders_stake_weighted<W: drop>(
    self: &LeaderRegistry,
    seed: &vector<u8>,
): vector<sui::object::ID> {
    abort ELocalExecutionUnavailable
}

/// Stamps a worksheet with this registry through the current runtime authority.
public fun stamp_workflow_worksheet<R>(
    _permit: &nexus_kernel::runtime_authority::RuntimePermit<R>,
    self: &LeaderRegistry,
    worksheet: &mut nexus_primitives::proof_of_uid::ProofOfUID,
    data: vector<u8>,
) {
    abort ELocalExecutionUnavailable
}

/// Activate a leader and claim ownership of its `Active` state.
///
/// Sets `status = Active` and writes a fresh ownership token = the activating
/// transaction's own digest (`*ctx.digest()`), which Sui guarantees is globally
/// unique. The off chain instance learns this digest from the transaction receipt
/// and remembers it, so it can later prove ownership when suspending.
///
/// Aborts with [ELeaderSlashed] if the leader is `Slashed` (the only abort path);
/// a slashed leader can never reclaim. Aborts with [ELeaderNotFound] if no record
/// exists.
public fun activate_and_claim(
    self: &mut LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Suspend a leader only if the caller still owns the current `Active` state.
///
/// This never aborts on a mismatch — the expected race during a rolling restart
/// (a departing instance that no longer owns the record) must be a cheap no op,
/// not an abort, because the shutdown suspend runs inside a bounded time budget.
///
/// Behavior:
/// - returns `false` (no op) if `status != Active`;
/// - if `claim_token == token`: sets `Suspended`, emits [LeaderStatusChangedEvent],
///   returns `true`;
/// - otherwise: emits [LeaderSuspensionSkippedEvent] and returns `false`.
///
/// Does not clear `claim_token`; the next activation overwrites it. Aborts with
/// [ELeaderNotFound] if no record exists.
public fun suspend_if_token(
    self: &mut LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    token: vector<u8>,
): bool {
    abort ELocalExecutionUnavailable
}

/// Set the unbonding duration (in milliseconds) applied to [request_unstake].
///
/// This is an administrative action gated by the leader capabilities admin cap.
public fun set_unbonding_duration_ms(
    self: &mut LeaderRegistry,
    admin: &mut LeaderCapabilitiesAdminCap,
    new_duration_ms: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Set the minimum stake (in US base units) required for leader eligibility.
///
/// This is an administrative action gated by the leader capabilities admin cap.
public fun set_min_stake_us(
    self: &mut LeaderRegistry,
    admin: &mut LeaderCapabilitiesAdminCap,
    min_stake_us: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Set the maximum budget (in MIST) a leader may spend on a single transaction.
///
/// This is an administrative action gated by the leader capabilities admin cap.
/// Aborts with [EMaxTransactionBudgetTooLow] if the new value is below
/// [MIN_TRANSACTION_BUDGET_MIST].
public fun set_max_transaction_budget(
    self: &mut LeaderRegistry,
    admin: &mut LeaderCapabilitiesAdminCap,
    new_max_transaction_budget: u64,
) {
    abort ELocalExecutionUnavailable
}

/// Slash stake for a leader. Returns the slashed balance to the caller.
///
/// Slashing reduces the leader pool and therefore reduces share value for all stakers.
public fun slash_stake(
    self: &mut LeaderRegistry,
    _slashing_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_slashing::OverLeaderSlashing,
    >,
    leader_cap_id: sui::object::ID,
    amount: u64,
    clock: &sui::clock::Clock,
): sui::balance::Balance<talus::us::US> {
    abort ELocalExecutionUnavailable
}

/// Allow [address] to request capabilities from this registry.
public fun allow_address(
    self: &mut LeaderRegistry,
    admin: &mut LeaderCapabilitiesAdminCap,
    address: address,
) {
    abort ELocalExecutionUnavailable
}

/// Revoke [address] from requesting capabilities.
public fun disallow_address(
    self: &mut LeaderRegistry,
    admin: &mut LeaderCapabilitiesAdminCap,
    address: address,
) {
    abort ELocalExecutionUnavailable
}

/// Clone and transfer a leader capability to the sender.
///
/// The sender must be in the capabilities allowlist.
public fun request_leader_cap(
    self: &mut LeaderRegistry,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Register the sender as a leader in a single atomic flow:
/// 1) clone and transfer [leader_cap::OverNetwork],
/// 2) create the leader record,
/// 3) store metadata and stake.
///
/// Requirements:
/// - sender is in the capabilities allowlist.
/// - `amount >= min_stake_us(self)` (eligible on registration).
public fun register(
    self: &mut LeaderRegistry,
    pay_with: &mut sui::coin::Coin<talus::us::US>,
    amount: u64,
    meta: Metadata,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}
