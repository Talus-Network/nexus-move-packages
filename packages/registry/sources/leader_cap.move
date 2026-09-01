/// Interface for the published [`nexus_registry::leader_cap`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_registry::leader_cap;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

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
public fun what_for(
    self: &nexus_primitives::owner_cap::CloneableOwnerCap<OverNetwork>,
): sui::object::ID {
    abort ELocalExecutionUnavailable
}
