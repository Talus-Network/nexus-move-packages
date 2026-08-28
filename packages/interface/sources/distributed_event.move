module nexus_interface::distributed_event;

//! Interface for [`nexus_interface::distributed_event`].
//!
//! Calls resolve to the published package.

/// Wraps an event of type `T` with the metadata the Leader network uses to
/// assign and time its off chain pickup: deadline, request timestamp,
/// task ID, and the ordered set of candidate leaders.
public struct DistributedEventWrapper<T: copy + drop> has copy, drop {
    event: T,
    deadline_ms: u64,
    requested_at_ms: u64,
    task_id: sui::object::ID,
    leaders: vector<sui::object::ID>,
}

/// Emits an event with the metadata required for distributed Leader pickup.
public native fun emit<T: copy + drop>(
    event: T,
    deadline_ms: u64,
    requested_at_ms: u64,
    task_id: sui::object::ID,
    leaders: vector<sui::object::ID>,
);

/// Returns the wrapped event.
public native fun inner<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): &T;

/// Returns the per Leader pickup interval in milliseconds.
public native fun deadline_ms<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): u64;

/// Returns the request timestamp in milliseconds.
public native fun requested_at_ms<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): u64;

/// Returns the Task ID used to correlate the request.
public native fun task_id<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): sui::object::ID;

/// Returns the ordered Leader candidates for the request.
public native fun leaders<T: copy + drop>(
    wrapper: &DistributedEventWrapper<T>,
): &vector<sui::object::ID>;
