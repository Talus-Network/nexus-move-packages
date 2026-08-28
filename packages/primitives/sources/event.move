module nexus_primitives::event;

//! Interface for [`nexus_primitives::event`].
//!
//! Calls resolve to the published package.

/// Wraps an event of type `T` so clients can search for it by wrapper type.
public struct EventWrapper<T> has copy, drop {
    event: T,
}

/// Emits the given event wrapped in `EventWrapper`.
public native fun emit<T: copy + drop>(event: T);

/// Borrows the inner event from the wrapper.
public native fun inner<T: copy + drop>(wrapper: &EventWrapper<T>): &T;
