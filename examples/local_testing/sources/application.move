module nexus_local_testing::application;

use nexus_primitives::data::NexusData;
use nexus_scheduler::task::TaskStatus;

/// Application owned observation of [NexusData] and its [TaskStatus].
public struct Observation has copy, drop {
    value: NexusData,
    status: TaskStatus,
    accepted: bool,
}

/// Records application state associated with [NexusData] without invoking a
/// Nexus function.
public fun observe(value: NexusData, status: TaskStatus, accepted: bool): Observation {
    Observation {
        value,
        status,
        accepted,
    }
}

/// Returns whether the application accepted this [Observation].
public fun is_accepted(self: &Observation): bool {
    self.accepted
}

/// Returns the [NexusData] recorded by this [Observation].
public fun value(self: &Observation): &NexusData {
    &self.value
}

/// Returns the [TaskStatus] recorded by this [Observation].
public fun status(self: &Observation): TaskStatus {
    self.status
}
