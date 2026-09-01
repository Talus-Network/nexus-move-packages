/// Interface for the published [`nexus_primitives::authorization`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_primitives::authorization;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Value that can be trusted to have been created by a UID.
/// Optionally, the value can also be locked to be received only by a given
/// recipient.
public struct ProvenValue<T> {
    value: T,
    by: sui::object::ID,
    recipient: std::option::Option<sui::object::ID>,
}

/// Proven value material that can be copied by authorized holder code.
public struct CloneableProvenValue<T: copy + store> has copy, drop, store {
    value: T,
    by: sui::object::ID,
    recipient: std::option::Option<sui::object::ID>,
}

/// Copyable authorization grant backed by proven value material.
public struct Grant<T: copy + store> has copy, drop, store {
    proof: CloneableProvenValue<T>,
}

/// Proves that the value was wrapped by the given UID.
/// Anyone can unwrap the value.
public fun wrap<T>(by: &sui::object::UID, value: T): ProvenValue<T> {
    abort ELocalExecutionUnavailable
}

/// Proves that the value was wrapped by the given UID.
/// Only the recipient UID can unwrap the value.
public fun wrap_for_recipient<T>(
    by: &sui::object::UID,
    value: T,
    recipient: sui::object::ID,
): ProvenValue<T> {
    abort ELocalExecutionUnavailable
}

/// Proves that the value was wrapped by the given UID, as copyable material.
/// Anyone can unwrap the value.
public fun wrap_cloneable<T: copy + store>(
    by: &sui::object::UID,
    value: T,
): CloneableProvenValue<T> {
    abort ELocalExecutionUnavailable
}

/// Proves that the value was wrapped by the given UID, as copyable material.
/// Only the recipient UID can unwrap the value.
public fun wrap_cloneable_for_recipient<T: copy + store>(
    by: &sui::object::UID,
    value: T,
    recipient: sui::object::ID,
): CloneableProvenValue<T> {
    abort ELocalExecutionUnavailable
}

/// Wraps the value into a copyable authorization grant unwrappable by anyone.
public fun grant<T: copy + store>(by: &sui::object::UID, value: T): Grant<T> {
    abort ELocalExecutionUnavailable
}

/// Wraps the value into a copyable authorization grant for a specific recipient.
public fun grant_for_recipient<T: copy + store>(
    by: &sui::object::UID,
    value: T,
    recipient: sui::object::ID,
): Grant<T> {
    abort ELocalExecutionUnavailable
}

/// Unwraps an unrestricted [`ProvenValue`], discarding its proof metadata.
/// Recipient bound values require [`unwrap_as_recipient`].
public fun unwrap<T>(self: ProvenValue<T>): T {
    abort ELocalExecutionUnavailable
}

/// Unwraps the proven value on behalf of its recipient.
/// Aborts if the value is locked to a recipient other than the given UID.
public fun unwrap_as_recipient<T>(self: ProvenValue<T>, recipient: &sui::object::UID): T {
    abort ELocalExecutionUnavailable
}

/// Unwraps unrestricted [`CloneableProvenValue`] material.
/// Recipient bound material must first become [`ProvenValue`].
public fun unwrap_cloneable<T: copy + store>(self: CloneableProvenValue<T>): T {
    abort ELocalExecutionUnavailable
}

/// Converts copyable proven material into a non copyable proven value,
/// preserving the wrapper UID and recipient.
public fun cloneable_into_proven_value<T: copy + store>(
    self: CloneableProvenValue<T>,
): ProvenValue<T> {
    abort ELocalExecutionUnavailable
}

/// Converts an authorization grant into a non copyable proven value.
public fun grant_into_proven_value<T: copy + store>(self: Grant<T>): ProvenValue<T> {
    abort ELocalExecutionUnavailable
}

/// Discards a proven value whose inner type can be dropped.
public fun drop<T: drop>(self: ProvenValue<T>) {
    abort ELocalExecutionUnavailable
}

/// Who wrapped the value.
public fun by<T>(self: &ProvenValue<T>): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Who is the recipient of the value, if any.
public fun recipient<T>(self: &ProvenValue<T>): std::option::Option<sui::object::ID> {
    abort ELocalExecutionUnavailable
}

/// The copyable proven material's inner value.
public fun cloneable_value<T: copy + store>(self: &CloneableProvenValue<T>): T {
    abort ELocalExecutionUnavailable
}

/// The UID that wrapped the copyable proven material.
public fun cloneable_by<T: copy + store>(self: &CloneableProvenValue<T>): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// The recipient the copyable proven material is locked to, if any.
public fun cloneable_recipient<T: copy + store>(
    self: &CloneableProvenValue<T>,
): std::option::Option<sui::object::ID> {
    abort ELocalExecutionUnavailable
}

/// The grant's inner value.
public fun grant_value<T: copy + store>(self: &Grant<T>): T {
    abort ELocalExecutionUnavailable
}

/// The UID that issued the grant.
public fun grant_by<T: copy + store>(self: &Grant<T>): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// The recipient the grant is locked to, if any.
public fun grant_recipient<T: copy + store>(self: &Grant<T>): std::option::Option<sui::object::ID> {
    abort ELocalExecutionUnavailable
}
