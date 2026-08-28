module nexus_primitives::object_state;

//! Interface for [`nexus_primitives::object_state`].
//!
//! Calls resolve to the published package.

/// Positional key for an object's exact stored layout.
///
/// A shared key is required because each object module must expose the same
/// observable storage position without sharing its stored value type.
public struct Inner() has copy, drop, store;

/// Positional key for the package an object accepts as write authority.
///
/// This is separate from [`Inner`] because execution can change without a
/// storage layout change.
public struct Witness() has copy, drop, store;

/// Attach one stored layout and one package witness to a stable object.
public native fun add<W: store, I: store>(id: &mut sui::object::UID, witness: W, inner: I);

/// Borrow the exact stored layout without changing package authority.
public native fun inner<I: store>(id: &sui::object::UID): &I;

/// Borrow the exact stored layout after verifying package authority.
public native fun inner_mut<W: store, I: store>(id: &mut sui::object::UID): &mut I;

/// Return whether the object accepts the exact witness type.
public native fun has_witness<W: store>(id: &sui::object::UID): bool;

/// Require the object to accept the exact witness type.
public native fun assert_witness<W: store>(id: &sui::object::UID);

/// Replace an exact source witness with an exact target witness.
public native fun replace_witness<Old: drop + store, New: store>(
    id: &mut sui::object::UID,
    witness: New,
);

/// Remove and return the exact stored layout during a declared transition.
public native fun take_inner<I: store>(id: &mut sui::object::UID): I;

/// Attach the target layout during a declared transition.
public native fun add_inner<I: store>(id: &mut sui::object::UID, inner: I);

/// Destroy a stable identity after removing its typed fields.
///
/// The inner value is returned because only its defining module knows how to
/// destroy resources contained by that layout.
public native fun destroy<W: drop + store, I: store>(id: sui::object::UID): I;

/// Require an upgrade capability whose latest package introduced `W`.
public native fun assert_upgrade_cap<W>(cap: &sui::package::UpgradeCap);
