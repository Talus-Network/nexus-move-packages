module nexus_primitives::authorization;

//! Interface for [`nexus_primitives::authorization`].
//!
//! Calls resolve to the published package.

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
public native fun wrap<T>(by: &sui::object::UID, value: T): ProvenValue<T>;

/// Proves that the value was wrapped by the given UID.
/// Only the recipient UID can unwrap the value.
public native fun wrap_for_recipient<T>(
    by: &sui::object::UID,
    value: T,
    recipient: sui::object::ID,
): ProvenValue<T>;

/// Proves that the value was wrapped by the given UID, as copyable material.
/// Anyone can unwrap the value.
public native fun wrap_cloneable<T: copy + store>(
    by: &sui::object::UID,
    value: T,
): CloneableProvenValue<T>;

/// Proves that the value was wrapped by the given UID, as copyable material.
/// Only the recipient UID can unwrap the value.
public native fun wrap_cloneable_for_recipient<T: copy + store>(
    by: &sui::object::UID,
    value: T,
    recipient: sui::object::ID,
): CloneableProvenValue<T>;

/// Wraps the value into a copyable authorization grant unwrappable by anyone.
public native fun grant<T: copy + store>(by: &sui::object::UID, value: T): Grant<T>;

/// Wraps the value into a copyable authorization grant for a specific recipient.
public native fun grant_for_recipient<T: copy + store>(
    by: &sui::object::UID,
    value: T,
    recipient: sui::object::ID,
): Grant<T>;

/// Unwraps an unrestricted [`ProvenValue`], discarding its proof metadata.
/// Recipient bound values require [`unwrap_as_recipient`].
public native fun unwrap<T>(self: ProvenValue<T>): T;

/// Unwraps the proven value on behalf of its recipient.
/// Aborts if the value is locked to a recipient other than the given UID.
public native fun unwrap_as_recipient<T>(self: ProvenValue<T>, recipient: &sui::object::UID): T;

/// Unwraps unrestricted [`CloneableProvenValue`] material.
/// Recipient bound material must first become [`ProvenValue`].
public native fun unwrap_cloneable<T: copy + store>(self: CloneableProvenValue<T>): T;

/// Converts copyable proven material into a non copyable proven value,
/// preserving the wrapper UID and recipient.
public native fun cloneable_into_proven_value<T: copy + store>(
    self: CloneableProvenValue<T>,
): ProvenValue<T>;

/// Converts an authorization grant into a non copyable proven value.
public native fun grant_into_proven_value<T: copy + store>(self: Grant<T>): ProvenValue<T>;

/// Discards a proven value whose inner type can be dropped.
public native fun drop<T: drop>(self: ProvenValue<T>);

/// Who wrapped the value.
public native fun by<T>(self: &ProvenValue<T>): sui::object::ID;

/// Who is the recipient of the value, if any.
public native fun recipient<T>(self: &ProvenValue<T>): std::option::Option<sui::object::ID>;

/// The copyable proven material's inner value.
public native fun cloneable_value<T: copy + store>(self: &CloneableProvenValue<T>): T;

/// The UID that wrapped the copyable proven material.
public native fun cloneable_by<T: copy + store>(self: &CloneableProvenValue<T>): sui::object::ID;

/// The recipient the copyable proven material is locked to, if any.
public native fun cloneable_recipient<T: copy + store>(
    self: &CloneableProvenValue<T>,
): std::option::Option<sui::object::ID>;

/// The grant's inner value.
public native fun grant_value<T: copy + store>(self: &Grant<T>): T;

/// The UID that issued the grant.
public native fun grant_by<T: copy + store>(self: &Grant<T>): sui::object::ID;

/// The recipient the grant is locked to, if any.
public native fun grant_recipient<T: copy + store>(
    self: &Grant<T>,
): std::option::Option<sui::object::ID>;
