#[test_only]
extend module nexus_tool::tool_registry;

use nexus_primitives::{object_state, owner_cap::CloneableOwnerCap};
use nexus_tool::{era, tool_authority::OverTool, tool_cashier::OverToolCashier};
use std::ascii::String as AsciiString;
use sui::{clock::{Self as clock, Clock}, coin, linked_table, table};
use talus::us::US;

/// Creates the empty Tool registry state needed by a TAP unit test.
///
/// The test calls the published registration function to add the Tool. This
/// fixture only replaces the private deployment constructor.
public fun new_for_testing(ctx: &mut TxContext): ToolRegistry {
    let mut registry = ToolRegistry { id: object::new(ctx) };
    object_state::add(
        &mut registry.id,
        era::v1_for_testing(),
        ToolRegistryInnerV1 {
            tool_ids: linked_table::new(ctx),
            registered_tools: table::new(ctx),
            meta_schemas: table::new(ctx),
            timeouts: linked_table::new(ctx),
            verifier_support: table::new(ctx),
            external_verifiers: table::new(ctx),
            invocation_costs_mist: table::new(ctx),
            on_chain_tool_witnesses: linked_table::new(ctx),
            workflow_authorization_cap_first: linked_table::new(ctx),
            us_collateral_to_lock: 1,
            lock_duration_ms: 1,
        },
    );
    registry
}

/// Registers one workflow authorized onchain Tool with local collateral.
///
/// Collateral creation is test setup. Tool registration still executes the
/// exact published Nexus function.
public fun register_on_chain_for_testing(
    registry: &mut ToolRegistry,
    package_address: address,
    module_name: AsciiString,
    fqn: AsciiString,
    description: vector<u8>,
    schema: nexus_interface::meta_schema::MetaSchema,
    timeout_ms: u64,
    tool_witness_id: ID,
    ctx: &mut TxContext,
): (Tool, CloneableOwnerCap<OverTool>, CloneableOwnerCap<OverToolCashier>, Clock) {
    let clock = clock::create_for_testing(ctx);
    let mut collateral = coin::mint_for_testing<US>(2, ctx);
    let (
        tool,
        tool_owner,
        cashier_owner,
    ) = registry.register_on_chain_tool_with_workflow_authorization_cap(
        package_address,
        module_name,
        fqn,
        description,
        schema,
        timeout_ms,
        tool_witness_id,
        0,
        &mut collateral,
        &clock,
        ctx,
    );
    std::unit_test::destroy(collateral);
    (tool, tool_owner, cashier_owner, clock)
}
