module nexus_primitives::owner_cap;

//! Interface for [`nexus_primitives::owner_cap`].
//!
//! Calls resolve to the published package.

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
public native fun new_uncloneable<T>(_: &T, ctx: &mut sui::tx_context::TxContext): OwnerCap<T>;

/// Creates cloneable authority over `what_for` from a consumable role witness.
public native fun new_cloneable_drop<T: drop>(
    witness: T,
    what_for: &sui::object::UID,
    ctx: &mut sui::tx_context::TxContext,
): CloneableOwnerCap<T>;

/// Creates cloneable authority over an object after verifying its UID.
public native fun new_cloneable_key<T: key>(
    object: &T,
    its_uid: &sui::object::UID,
    ctx: &mut sui::tx_context::TxContext,
): CloneableOwnerCap<T>;

/// Creates a new [CloneableOwnerCap] with the same `what_for`.
public native fun clone<T>(
    cap: &CloneableOwnerCap<T>,
    ctx: &mut sui::tx_context::TxContext,
): CloneableOwnerCap<T>;

/// Creates N new [CloneableOwnerCap]s with the same `what_for`.
public native fun clone_n<T>(
    cap: &CloneableOwnerCap<T>,
    n: u64,
    ctx: &mut sui::tx_context::TxContext,
): vector<CloneableOwnerCap<T>>;

/// Creates a new [CloneableOwnerCap] with the same `what_for` and transfers it to the
/// given address.
public native fun clone_for_receiver<T>(
    cap: &CloneableOwnerCap<T>,
    receiver: address,
    ctx: &mut sui::tx_context::TxContext,
);

/// Destroys a cloneable capability and drops its inner authority token.
public native fun destroy<T>(self: CloneableOwnerCap<T>);

/// The capability's unique ID.
public native fun id<T>(self: &OwnerCap<T>): sui::object::ID;

/// The ID of the resource this capability owns.
public native fun what_for<T>(self: &CloneableOwnerCap<T>): sui::object::ID;

/// Whether this capability owns the given object.
public native fun is_for<T, U: key>(self: &CloneableOwnerCap<T>, what: &U): bool;

/// Whether this capability owns the resource with the given ID.
public native fun is_for_id<T>(self: &CloneableOwnerCap<T>, what_id: sui::object::ID): bool;

/// Borrows the inner non cloneable `OwnerCap` for APIs that care about authority identity but not resource binding.
/// This provides the same view style pattern used to expose narrower coin or balance capabilities.
public native fun as_ref<T>(self: &CloneableOwnerCap<T>): &OwnerCap<T>;
