/// Interface for the published [`nexus_registry::network_auth`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_registry::network_auth;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Canonical identity key namespace for key bindings.
///
/// This value is used as:
/// - the key for the derived [KeyBinding] address, and
/// - the identity commitment inside PoP signatures (via `bcs(IdentityKey)`).
public enum IdentityKey has copy, drop, store {
    /// Leader identity keyed by leader capability ID.
    Leader {
        /// ID of the leader's `CloneableOwnerCap<leader_cap::OverNetwork>` capability object.
        leader_cap_id: sui::object::ID,
    },
    /// Tool identity keyed by stable Tool object ID.
    Tool {
        tool_id: sui::object::ID,
    },
}

/// Shared registry for identity key bindings.
public struct NetworkAuth has key {
    /// Object ID of the registry.
    id: sui::object::UID,
}

/// Version one stored layout for [`NetworkAuth`].
public struct NetworkAuthInnerV1 has store {
    /// Singleton witness for the registered key verifier.
    registered_key_witness: sui::object::UID,
    /// Discoverable set of identities that have a [KeyBinding].
    ///
    /// This enables indexers/tooling to enumerate which identities have created
    /// bindings, without needing to guess identities and derived addresses.
    identities: sui::vec_set::VecSet<IdentityKey>,
}

/// Per identity key binding stored at a deterministic derived address.
///
/// This object holds the full key lifecycle state for one identity:
/// - key registration (with PoP),
/// - active key selection (the only key verifiers accept),
/// - revocations (for incident response / decommissioning).
public struct KeyBinding has key, store {
    /// Object ID of the binding.
    id: sui::object::UID,
}

/// Version one stored layout for [`KeyBinding`].
public struct KeyBindingInnerV1 has store {
    /// Identity this binding belongs to.
    identity: IdentityKey,
    /// Optional description for operators and tooling.
    description: std::option::Option<vector<u8>>,
    /// Monotonically increasing key identifier.
    ///
    /// This is used as the key id for the next registration and as the PoP
    /// nonce to prevent replay of PoP signatures.
    next_key_id: u64,
    /// Active key identifier for verification.
    ///
    /// Offchain verifiers MUST accept signatures from this key only.
    /// This allows key rotation while keeping verification unambiguous.
    active_key_id: std::option::Option<u64>,
    /// Key records indexed by key id.
    keys: sui::table::Table<u64, KeyRecord>,
}

/// Single key record stored in a binding.
///
/// Keys are append only (registered under a new `key_id`) and can be revoked.
public struct KeyRecord has store {
    /// Key scheme identifier (Ed25519 only).
    scheme: u8,
    /// Raw public key bytes.
    public_key: vector<u8>,
    /// Timestamp when the key was registered.
    added_at_ms: u64,
    /// Timestamp when the key was revoked, if any.
    revoked_at_ms: std::option::Option<u64>,
}

/// Ephemeral proof that the caller is authorized to act for an identity.
///
/// This prevents unauthorized parties from creating bindings or registering keys
/// for identities they do not control.
public struct ProofOfIdentity has drop {
    /// Identity proven by on chain capabilities.
    identity: IdentityKey,
}

/// Ephemeral proof that a key is controlled by the signer.
///
/// This proves possession of the private key corresponding to `public_key`
/// without revealing it, and is valid only for a single registration slot
/// (bound to [KeyBinding::next_key_id]).
public struct ProofOfKey has drop {
    /// Key scheme identifier (Ed25519 only).
    scheme: u8,
    /// Public key proven by proof of possession.
    public_key: vector<u8>,
    /// Key id this proof is valid for.
    ///
    /// This must match [KeyBinding::next_key_id] when registering the key.
    key_id: u64,
}

/// Emitted when a new network auth registry is created.
public struct NetworkAuthCreatedEvent has copy, drop {
    /// Registry object ID.
    registry: sui::object::ID,
    /// Registered key verifier witness ID.
    registered_key_witness: sui::object::ID,
}

/// Emitted when a new key binding is created.
public struct KeyBindingCreatedEvent has copy, drop {
    /// Binding object ID.
    binding: sui::object::ID,
    /// Identity associated with the binding.
    identity: IdentityKey,
}

/// Emitted when a key is registered.
public struct KeyRegisteredEvent has copy, drop {
    /// Binding object ID.
    binding: sui::object::ID,
    /// Registered key identifier.
    key_id: u64,
    /// Key scheme identifier.
    scheme: u8,
    /// Public key bytes.
    public_key: vector<u8>,
    /// Timestamp when the key was registered.
    added_at_ms: u64,
}

/// Emitted when a key is revoked.
public struct KeyRevokedEvent has copy, drop {
    /// Binding object ID.
    binding: sui::object::ID,
    /// Revoked key identifier.
    key_id: u64,
    /// Timestamp when the key was revoked.
    revoked_at_ms: u64,
}

/// Emitted when the active key changes.
public struct ActiveKeyUpdatedEvent has copy, drop {
    /// Binding object ID.
    binding: sui::object::ID,
    /// New active key identifier, or none if cleared.
    active_key_id: std::option::Option<u64>,
}

/// Create proof for the leader (sender) using its leader capability.
///
/// The leader capability serves as the on chain authorization to act as a
/// Leader identity and register/rotate keys for `IdentityKey::Leader { leader_cap_id:
/// object::id(leader_cap) }`.
public fun prove_leader(
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
): ProofOfIdentity {
    abort ELocalExecutionUnavailable
}

/// Creates identity proof for an off chain Tool using its owner capability.
///
/// The owner cap is validated against the Tool object before binding its stable ID.
public fun prove_offchain_tool(
    tool: &nexus_tool::tool_registry::Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
): ProofOfIdentity {
    abort ELocalExecutionUnavailable
}

/// Return the identity proven by the proof.
public fun proof_identity(self: &ProofOfIdentity): IdentityKey {
    abort ELocalExecutionUnavailable
}

/// Build a leader identity key from a leader capability id.
public fun identity_key_leader(leader_cap_id: sui::object::ID): IdentityKey {
    abort ELocalExecutionUnavailable
}

/// Build a tool identity key from a stable Tool object ID.
public fun identity_key_tool(tool_id: sui::object::ID): IdentityKey {
    abort ELocalExecutionUnavailable
}

/// Create proof_of_possession for registering the given public key.
/// Only Ed25519 keys are supported.
///
/// The signature must verify over
/// `POP_DOMAIN || bcs(IdentityKey) || bcs(key_id) || public_key`
/// using the same public key, proving control of the private key for this
/// specific identity and key id slot.
public fun new_proof_of_key(
    binding: &KeyBinding,
    identity: &ProofOfIdentity,
    public_key: vector<u8>,
    signature: vector<u8>,
): ProofOfKey {
    abort ELocalExecutionUnavailable
}

/// Deterministic derived address for the key binding.
///
/// Uses the registry object ID and the identity as the derivation key.
///
/// This allows any caller to deterministically compute where the [KeyBinding]
/// for an identity lives on chain.
public fun binding_address(registry: &NetworkAuth, identity: IdentityKey): address {
    abort ELocalExecutionUnavailable
}

/// Check whether a binding has been created for the given identity.
public fun binding_exists(registry: &NetworkAuth, identity: IdentityKey): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the singleton registered key verifier witness ID.
public fun registered_key_witness(self: &NetworkAuth): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Create a new key binding for the given identity.
///
/// This claims the derived object ID, initializes the binding state, and
/// inserts the identity into the registry's discovery set.
public fun create_binding(
    registry: &mut NetworkAuth,
    identity: ProofOfIdentity,
    description: std::option::Option<vector<u8>>,
    ctx: &mut sui::tx_context::TxContext,
): KeyBinding {
    abort ELocalExecutionUnavailable
}

/// Return the identity associated with a key binding.
public fun key_binding_identity(self: &KeyBinding): IdentityKey {
    abort ELocalExecutionUnavailable
}

/// Return the active key id for a binding.
///
/// Offchain verifiers must accept signatures from this key only.
public fun key_binding_active_key_id(self: &KeyBinding): std::option::Option<u64> {
    abort ELocalExecutionUnavailable
}

/// Return the next key id that will be assigned on registration.
///
/// This value is also committed into PoP signatures to make them one time use.
public fun key_binding_next_key_id(self: &KeyBinding): u64 {
    abort ELocalExecutionUnavailable
}

/// Borrow a key record by id.
public fun key_binding_key(self: &KeyBinding, key_id: u64): &KeyRecord {
    abort ELocalExecutionUnavailable
}

/// Returns whether the current active slot is a live, correctly sized Ed25519 key.
public fun active_key_is_usable(binding: &KeyBinding): bool {
    abort ELocalExecutionUnavailable
}

/// Verify an Ed25519 signature against the currently active key for this binding.
///
/// Returns `false` unless:
/// - the active key record exists and is not revoked,
/// - the key scheme and sizes are valid Ed25519 values, and
/// - signature verification succeeds.
public fun verify_active_key_signature(
    binding: &KeyBinding,
    signature: &vector<u8>,
    message: &vector<u8>,
): bool {
    abort ELocalExecutionUnavailable
}

/// Register a new key and set it as active.
///
/// This assigns a monotonically increasing key id, stores the key record, and
/// updates the active key pointer.
public fun register_key(
    binding: &mut KeyBinding,
    identity: &ProofOfIdentity,
    proof_of_key: ProofOfKey,
    clock: &sui::clock::Clock,
) {
    abort ELocalExecutionUnavailable
}

/// Revoke an existing key.
///
/// This sets the revocation timestamp and clears the active key if needed.
public fun revoke_key(
    binding: &mut KeyBinding,
    identity: &ProofOfIdentity,
    key_id: u64,
    clock: &sui::clock::Clock,
) {
    abort ELocalExecutionUnavailable
}

/// Set the active key to an existing, non revoked key.
///
/// This switches the active key pointer without altering key records.
public fun set_active_key(binding: &mut KeyBinding, identity: &ProofOfIdentity, key_id: u64) {
    abort ELocalExecutionUnavailable
}
