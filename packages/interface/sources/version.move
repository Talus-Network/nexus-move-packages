module nexus_interface::version;

//! Interface for [`nexus_interface::version`].
//!
//! Calls resolve to the published package.

/// Identifies the interface revision implemented or expected by the surrounding stored state.
public struct InterfaceVersion has copy, drop, store {
    inner: u64,
}

/// Wraps a raw version number into an `InterfaceVersion`.
public native fun v(version: u64): InterfaceVersion;

/// Returns the raw version number.
public native fun number(self: &InterfaceVersion): u64;

/// Asserts that this interface version equals the expected number.
///
/// Aborts with `EInterfaceVersionMismatch` if the version does not match.
public native fun expect_v(self: &InterfaceVersion, expected: u64);
