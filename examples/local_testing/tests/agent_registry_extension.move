#[test_only]
extend module nexus_registry::agent_registry;

use nexus_primitives::object_state;
use nexus_registry::era;
use sui::table;

/// Creates the empty registry state needed by an embedded Agent unit test.
public fun new_for_testing(ctx: &mut TxContext): AgentRegistry {
    let mut registry = AgentRegistry { id: object::new(ctx) };
    object_state::add(
        &mut registry.id,
        era::v1_for_testing(),
        AgentRegistryInnerV1 { agents: table::new(ctx) },
    );
    registry
}
