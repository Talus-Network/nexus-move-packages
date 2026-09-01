/// Interface for the published [`nexus_interface::distributed_event`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_interface::distributed_event;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

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
public fun emit<T: copy + drop>(
    event: T,
    deadline_ms: u64,
    requested_at_ms: u64,
    task_id: sui::object::ID,
    leaders: vector<sui::object::ID>,
) {
    abort ELocalExecutionUnavailable
}

/// Returns the wrapped event.
public fun inner<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): &T {
    abort ELocalExecutionUnavailable
}

/// Returns the per Leader pickup interval in milliseconds.
public fun deadline_ms<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns the request timestamp in milliseconds.
public fun requested_at_ms<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): u64 {
    abort ELocalExecutionUnavailable
}

/// Returns the Task ID used to correlate the request.
public fun task_id<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the ordered Leader candidates for the request.
public fun leaders<T: copy + drop>(wrapper: &DistributedEventWrapper<T>): &vector<sui::object::ID> {
    abort ELocalExecutionUnavailable
}
