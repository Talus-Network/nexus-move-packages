/// Interface for the published [`nexus_primitives::owner_cap`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_primitives::owner_cap;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// When you want to prove you own something.
///
/// The pattern of usage:
/// Authorize with `what_for` UID value of the resource and assert `what_for`
/// from the resource's module.
/// In this case [clone] is useful to allow multiple addresses or
/// multiple concurrent txs.
///
/// # Important
/// The generic parameter `T` is a phantom type that is used to distinguish
/// between different things that can be owned.
///
/// a. `T has drop` then [CloneableOwnerCap] can be created only by giving `T`
/// b. `T has store` then [CloneableOwnerCap] can be created by giving `&T`
///     and associated [UID].
public struct CloneableOwnerCap<phantom T> has key, store {
    id: sui::object::UID,
    /// ID of the resource controlled by this capability.
    what_for: sui::object::ID,
    /// Some packages might not care about the `what_for` field, so they accept
    /// [OwnerCap].
    ///
    /// This allows us to emulate Rust's `AsRef` trait.
    /// Similar pattern for [sui::coin] and [sui::balance].
    inner: OwnerCap<T>,
}

/// When you want to prove you own something.
///
/// The pattern of usage:
/// Store the [OwnerCap] ID in a resource and assert from the resource's
/// module that the sender has the right [OwnerCap]'s ID.
///
/// # Important
/// The generic parameter `T` is a phantom type that is used to distinguish
/// between different things that can be owned.
/// Anyone with a reference to [T] can create an [OwnerCap] with its generic.
public struct OwnerCap<phantom T> has drop, store {
    unique: sui::object::ID,
}

/// Creates a non cloneable ownership capability with a fresh unique ID.
/// Anyone holding a reference to `T` can mint one.
public fun new_uncloneable<T>(_: &T, ctx: &mut sui::tx_context::TxContext): OwnerCap<T> {
    abort ELocalExecutionUnavailable
}

/// Creates cloneable authority over `what_for` from a consumable role witness.
public fun new_cloneable_drop<T: drop>(
    witness: T,
    what_for: &sui::object::UID,
    ctx: &mut sui::tx_context::TxContext,
): CloneableOwnerCap<T> {
    abort ELocalExecutionUnavailable
}

/// Creates cloneable authority over an object after verifying its UID.
public fun new_cloneable_key<T: key>(
    object: &T,
    its_uid: &sui::object::UID,
    ctx: &mut sui::tx_context::TxContext,
): CloneableOwnerCap<T> {
    abort ELocalExecutionUnavailable
}

/// Creates a new [CloneableOwnerCap] with the same `what_for`.
public fun clone<T>(
    cap: &CloneableOwnerCap<T>,
    ctx: &mut sui::tx_context::TxContext,
): CloneableOwnerCap<T> {
    abort ELocalExecutionUnavailable
}

/// Creates N new [CloneableOwnerCap]s with the same `what_for`.
public fun clone_n<T>(
    cap: &CloneableOwnerCap<T>,
    n: u64,
    ctx: &mut sui::tx_context::TxContext,
): vector<CloneableOwnerCap<T>> {
    abort ELocalExecutionUnavailable
}

/// Creates a new [CloneableOwnerCap] with the same `what_for` and transfers it to the
/// given address.
public fun clone_for_receiver<T>(
    cap: &CloneableOwnerCap<T>,
    receiver: address,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Destroys a cloneable capability and drops its inner authority token.
public fun destroy<T>(self: CloneableOwnerCap<T>) {
    abort ELocalExecutionUnavailable
}

/// The capability's unique ID.
public fun id<T>(self: &OwnerCap<T>): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// The ID of the resource this capability owns.
public fun what_for<T>(self: &CloneableOwnerCap<T>): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Whether this capability owns the given object.
public fun is_for<T, U: key>(self: &CloneableOwnerCap<T>, what: &U): bool {
    abort ELocalExecutionUnavailable
}

/// Whether this capability owns the resource with the given ID.
public fun is_for_id<T>(self: &CloneableOwnerCap<T>, what_id: sui::object::ID): bool {
    abort ELocalExecutionUnavailable
}

/// Borrows the inner non cloneable `OwnerCap` for APIs that care about authority identity but not resource binding.
/// This provides the same view style pattern used to expose narrower coin or balance capabilities.
public fun as_ref<T>(self: &CloneableOwnerCap<T>): &OwnerCap<T> {
    abort ELocalExecutionUnavailable
}
