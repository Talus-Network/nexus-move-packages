/// Interface for the published [`nexus_kernel::runtime_authority`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_kernel::runtime_authority;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Fixed root selecting the only Scheduler facade allowed to authorize protocol effects.
///
/// Registry, Workflow, and Tool dependency functions consume the facade's
/// [`RuntimePermit`]; they do not acquire independent runtime authority. The
/// selected Scheduler package fixes the linked protocol dependency graph, so
/// one rotation changes that effect graph as one transition.
///
/// `scheduler_upgrade_cap` binds this root to one package lineage. The
/// [`UpgradeCap`] object keeps its ID across upgrades while its package pointer
/// advances, which makes package activation a forward only transition.
public struct RuntimeAuthority has key {
    id: sui::object::UID,
    scheduler_upgrade_cap: std::option::Option<sui::object::ID>,
    current_runtime: std::option::Option<std::type_name::TypeName>,
    current_runtime_package: std::option::Option<sui::object::ID>,
    paused: bool,
}

/// Capability for emergency pause and proposal admission policy changes.
public struct RuntimeAuthorityCap has key, store {
    id: sui::object::UID,
    authority_id: sui::object::ID,
}

/// Ephemeral proof that code entered through the current Scheduler facade.
///
/// The value cannot be stored or copied. Dependency functions accept only a
/// borrowed permit, so authority remains scoped to one transaction call tree.
public struct RuntimePermit<phantom R> has drop {
    authority_id: sui::object::ID,
}

/// Dynamic marker preventing new acceptance under proposal contract `E`.
public struct WorkAdmissionDisabled<phantom E>() has copy, drop, store;

/// Bind the fixed root to the Scheduler package lineage and its first runtime.
///
/// The actual `runtime_witness` value proves constructibility by the facade.
/// Its type selects identity; it does not prove exact bytecode provenance.
public fun bind_runtime<R: drop>(
    authority: &mut RuntimeAuthority,
    authority_cap: &RuntimeAuthorityCap,
    scheduler_cap: &sui::package::UpgradeCap,
    runtime_witness: R,
) {
    abort ELocalExecutionUnavailable
}

/// Rotate effect authority to a witness introduced by the latest Scheduler.
///
/// Rotation accepts only the [`UpgradeCap`] bound by [`bind_runtime`]. A target
/// introduced by the current package is rejected, including while paused.
public fun rotate_runtime<R: drop>(
    authority: &mut RuntimeAuthority,
    scheduler_cap: &sui::package::UpgradeCap,
    runtime_witness: R,
) {
    abort ELocalExecutionUnavailable
}

/// Permanently pause the currently bound runtime identity.
///
/// There is no resume transition. Recovery requires [`rotate_runtime`] with a
/// witness introduced by a later package reached through the bound cap.
public fun pause(authority: &mut RuntimeAuthority, cap: &RuntimeAuthorityCap) {
    abort ELocalExecutionUnavailable
}

/// Acquire transaction scoped effect authority for exact runtime type `R`.
///
/// Requiring a value prevents callers from gaining authority by naming a type
/// alone. The type name is still only identity, not provenance evidence.
public fun authorize<R: drop>(authority: &RuntimeAuthority, runtime_witness: R): RuntimePermit<R> {
    abort ELocalExecutionUnavailable
}

/// Return whether new proposal work under contract `E` must abort.
///
/// An absent marker means the contract is open. Immortal proposal code reads
/// this fixed state in the transaction that records a new occurrence, so an
/// explicit disable rolls back every caller side effect atomically. Work
/// accepted before the marker was added remains a promise to current runtime.
public fun is_work_admission_disabled<E>(authority: &RuntimeAuthority): bool {
    abort ELocalExecutionUnavailable
}

/// Add or remove the explicit rejection marker for proposal epoch `E`.
public fun set_work_admission_disabled<E>(
    authority: &mut RuntimeAuthority,
    cap: &RuntimeAuthorityCap,
    disabled: bool,
) {
    abort ELocalExecutionUnavailable
}

/// Return the package that introduced the currently bound runtime type.
public fun runtime_package(authority: &RuntimeAuthority): std::option::Option<sui::object::ID> {
    abort ELocalExecutionUnavailable
}

/// Return the exact currently bound runtime type.
public fun runtime_type(
    authority: &RuntimeAuthority,
): std::option::Option<std::type_name::TypeName> {
    abort ELocalExecutionUnavailable
}

/// Return whether the current runtime identity has been permanently paused.
public fun is_paused(authority: &RuntimeAuthority): bool {
    abort ELocalExecutionUnavailable
}

/// Return the fixed authority root ID proven by this permit.
public fun permit_authority<R>(permit: &RuntimePermit<R>): sui::object::ID {
    abort ELocalExecutionUnavailable
}
