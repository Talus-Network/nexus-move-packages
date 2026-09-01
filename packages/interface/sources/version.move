/// Interface for the published [`nexus_interface::version`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_interface::version;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Identifies the interface revision implemented or expected by the surrounding stored state.
public struct InterfaceVersion has copy, drop, store {
    inner: u64,
}

/// Wraps a raw version number into an `InterfaceVersion`.
public fun v(version: u64): InterfaceVersion {
    abort ELocalExecutionUnavailable
}

/// Returns the raw version number.
public fun number(self: &InterfaceVersion): u64 {
    abort ELocalExecutionUnavailable
}

/// Asserts that this interface version equals the expected number.
///
/// Aborts with `EInterfaceVersionMismatch` if the version does not match.
public fun expect_v(self: &InterfaceVersion, expected: u64) {
    abort ELocalExecutionUnavailable
}
