#[test_only]
extend module nexus_scheduler::task;

use nexus_primitives::data::{Self as data, NexusData};

/// Creates the active [TaskStatus] used by a local application test.
public fun active_for_testing(): TaskStatus {
    TaskStatus::Active
}

/// Returns whether [TaskStatus] is active in a local application test.
public fun is_active_for_testing(self: TaskStatus): bool {
    match (self) {
        TaskStatus::Active => true,
        _ => false,
    }
}

/// Combines fixtures from two published Nexus packages.
public fun active_with_data_for_testing(bytes: vector<u8>): (TaskStatus, NexusData) {
    (TaskStatus::Active, data::inline_for_testing(bytes))
}
