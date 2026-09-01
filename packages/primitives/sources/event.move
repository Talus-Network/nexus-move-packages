/// Interface for the published [`nexus_primitives::event`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_primitives::event;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Wraps an event of type `T` so clients can search for it by wrapper type.
public struct EventWrapper<T> has copy, drop {
    event: T,
}

/// Emits the given event wrapped in `EventWrapper`.
public fun emit<T: copy + drop>(event: T) {
    abort ELocalExecutionUnavailable
}

/// Borrows the inner event from the wrapper.
public fun inner<T: copy + drop>(wrapper: &EventWrapper<T>): &T {
    abort ELocalExecutionUnavailable
}
