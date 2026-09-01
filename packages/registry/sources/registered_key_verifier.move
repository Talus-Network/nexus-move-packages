/// Interface for the published [`nexus_registry::registered_key_verifier`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_registry::registered_key_verifier;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Configures a Tool's one time RegisteredKey support after validating its current key binding.
public fun configure_tool(
    tool_registry: &mut nexus_tool::tool_registry::ToolRegistry,
    tool: &nexus_tool::tool_registry::Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    network_auth: &nexus_registry::network_auth::NetworkAuth,
    tool_key_binding: &nexus_registry::network_auth::KeyBinding,
) {
    abort ELocalExecutionUnavailable
}

/// Verifies the two signature RegisteredKey protocol and always stamps a structurally valid result.
/// Invalid active keys or signatures produce `Reject`; malformed protocol objects abort.
public fun verify(
    worksheet: &mut nexus_primitives::proof_of_uid::ProofOfUID,
    result: nexus_primitives::tagged_output::TaggedOutput,
    auxiliary: nexus_interface::verifier::RegisteredKeyAuxiliary,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    network_auth: &nexus_registry::network_auth::NetworkAuth,
    leader_key_binding: &nexus_registry::network_auth::KeyBinding,
    tool_key_binding: &nexus_registry::network_auth::KeyBinding,
    tool_id: sui::object::ID,
): nexus_interface::verifier::VerificationVerdict {
    abort ELocalExecutionUnavailable
}
