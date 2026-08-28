module nexus_registry::leader_cap;

//! Interface for [`nexus_registry::leader_cap`].
//!
//! Calls resolve to the published package.

/// Type of [OwnerCap] that can be held by the leader of an off chain network.
/// An off chain network has one or more equally trusted leaders.
/// TODO: Need Migration if the package is upgraded
public struct OverNetwork has drop {}

/// Emitted when a founding leader capability is minted for a new network.
public struct FoundingLeaderCapCreatedEvent has copy, drop {
    leader_cap: sui::object::ID,
    network: sui::object::ID,
}

/// Compatibility wrapper so existing call sites can keep using method syntax.
public native fun what_for(
    self: &nexus_primitives::owner_cap::CloneableOwnerCap<OverNetwork>,
): sui::object::ID;
