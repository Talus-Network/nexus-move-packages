#[test_only]
extend module nexus_scheduler::task;

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
