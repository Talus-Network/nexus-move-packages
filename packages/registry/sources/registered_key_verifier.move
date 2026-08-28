module nexus_registry::registered_key_verifier;

//! Interface for [`nexus_registry::registered_key_verifier`].
//!
//! Calls resolve to the published package.

/// Configures a Tool's one time RegisteredKey support after validating its current key binding.
public native fun configure_tool(
    tool_registry: &mut nexus_tool::tool_registry::ToolRegistry,
    tool: &nexus_tool::tool_registry::Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    network_auth: &nexus_registry::network_auth::NetworkAuth,
    tool_key_binding: &nexus_registry::network_auth::KeyBinding,
);

/// Verifies the two signature RegisteredKey protocol and always stamps a structurally valid result.
/// Invalid active keys or signatures produce `Reject`; malformed protocol objects abort.
public native fun verify(
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
): nexus_interface::verifier::VerificationVerdict;
