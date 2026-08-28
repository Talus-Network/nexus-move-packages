module nexus_registry::leader_slashing;

//! Interface for [`nexus_registry::leader_slashing`].
//!
//! Calls resolve to the published package.

/// Capability role that authorizes Leader stake slashing.
public struct OverLeaderSlashing has drop {}
