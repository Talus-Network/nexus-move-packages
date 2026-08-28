module nexus_scheduler::era;

//! Interface for [`nexus_scheduler::era`].
//!
//! Calls resolve to the published package.

/// Runtime identity introduced by the first Scheduler facade release.
///
/// This type is distinct from [`V1`]: it selects system effect authority,
/// while [`V1`] controls mutation of durable Scheduler objects.
public struct RuntimeV1() has drop;

/// Validation contract selected by Tasks created through the first proposal API.
///
/// This type identifies admission semantics. It is not evidence that a
/// particular package or function constructed a Task.
public struct WorkAdmissionV1() has copy, drop, store;

/// Version one Scheduler package witness.
public struct V1() has copy, drop, store;
