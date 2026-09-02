/// Interface for the published [`nexus_primitives::object_state`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_primitives::object_state;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

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
public fun add<W: store, I: store>(id: &mut sui::object::UID, witness: W, inner: I) {
    abort ELocalExecutionUnavailable
}

/// Borrow the exact stored layout without changing package authority.
public fun inner<I: store>(id: &sui::object::UID): &I {
    abort ELocalExecutionUnavailable
}

/// Borrow the exact stored layout after verifying package authority.
public fun inner_mut<W: store, I: store>(id: &mut sui::object::UID): &mut I {
    abort ELocalExecutionUnavailable
}

/// Return whether the object accepts the exact witness type.
public fun has_witness<W: store>(id: &sui::object::UID): bool {
    abort ELocalExecutionUnavailable
}

/// Require the object to accept the exact witness type.
public fun assert_witness<W: store>(id: &sui::object::UID) {
    abort ELocalExecutionUnavailable
}

/// Replace an exact source witness with an exact target witness.
public fun replace_witness<Old: drop + store, New: store>(id: &mut sui::object::UID, witness: New) {
    abort ELocalExecutionUnavailable
}

/// Remove and return the exact stored layout during a declared transition.
public fun take_inner<I: store>(id: &mut sui::object::UID): I {
    abort ELocalExecutionUnavailable
}

/// Attach the target layout during a declared transition.
public fun add_inner<I: store>(id: &mut sui::object::UID, inner: I) {
    abort ELocalExecutionUnavailable
}

/// Destroy a stable identity after removing its typed fields.
///
/// The inner value is returned because only its defining module knows how to
/// destroy resources contained by that layout.
public fun destroy<W: drop + store, I: store>(id: sui::object::UID): I {
    abort ELocalExecutionUnavailable
}

/// Require an upgrade capability whose latest package introduced `W`.
public fun assert_upgrade_cap<W>(cap: &sui::package::UpgradeCap) {
    abort ELocalExecutionUnavailable
}
