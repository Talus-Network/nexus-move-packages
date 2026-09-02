#[test_only]
module nexus_local_testing::application_tests;

use nexus_interface::{
    agent as agent_interface,
    authorization as interface_authorization,
    dag::DAG,
    meta_schema,
    onchain_tool_result::{Self as onchain_tool_result, OnchainToolResult}
};
use nexus_kernel::runtime_authority::{Self as runtime_authority, RuntimeAuthority};
use nexus_local_testing::{application::{Self as application, ApplicationState}, review_vertex};
use nexus_primitives::{
    authorization as primitive_authorization,
    owner_cap::CloneableOwnerCap,
    proof_of_uid
};
use nexus_registry::agent_registry::{Self as agent_registry, AgentRegistry};
use nexus_scheduler::{scheduler, task::{Self as task, Task, TaskPointer}};
use nexus_tool::{
    tool_authority::OverTool,
    tool_cashier::OverToolCashier,
    tool_registry::{Self as tool_registry, Tool, ToolRegistry}
};
use std::unit_test::{assert_eq, destroy};
use sui::{clock::Clock, coin, test_scenario, vec_set};

const ALICE: address = @0xA11CE;

/// Complete local state for one scheduled review.
public struct ScheduledFixture {
    authority: RuntimeAuthority,
    registry: AgentRegistry,
    tool_registry: ToolRegistry,
    dag: DAG,
    state: ApplicationState,
    tool: Tool,
    tool_owner: CloneableOwnerCap<OverTool>,
    cashier_owner: CloneableOwnerCap<OverToolCashier>,
    clock: Clock,
    task: Task,
    pointer: TaskPointer,
}

fun port(
    name: vector<u8>,
    cardinality: bool,
    kind: meta_schema::ValueKind,
): meta_schema::PortSchema {
    meta_schema::port_schema(name, cardinality, kind)
}

fun review_tool_schema(): meta_schema::MetaSchema {
    let one = false;
    let many = true;
    let data = meta_schema::value_kind_data();
    meta_schema::new(
        vector[port(b"0", one, meta_schema::value_kind_object()), port(b"1", many, data)],
        vector[
            meta_schema::output_variant_schema(
                b"accepted",
                vector[port(b"length", one, data)],
            ),
            meta_schema::output_variant_schema(
                b"rejected",
                vector[port(b"minimum_length", one, data)],
            ),
        ],
    )
}

fun register_review_tool(
    state: &ApplicationState,
    ctx: &mut TxContext,
): (ToolRegistry, Tool, CloneableOwnerCap<OverTool>, CloneableOwnerCap<OverToolCashier>, Clock) {
    let mut registry = tool_registry::new_for_testing(ctx);
    let (tool, tool_owner, cashier_owner, clock) = tool_registry::register_on_chain_for_testing(
        &mut registry,
        @0xCAFE,
        review_vertex::module_name(),
        review_vertex::fqn(),
        b"Reviews content length",
        review_tool_schema(),
        10_000,
        application::tool_witness_id(state),
        ctx,
    );
    (registry, tool, tool_owner, cashier_owner, clock)
}

fun setup(
    ctx: &mut TxContext,
): (
    AgentRegistry,
    ToolRegistry,
    DAG,
    ApplicationState,
    Tool,
    CloneableOwnerCap<OverTool>,
    CloneableOwnerCap<OverToolCashier>,
    Clock,
    ID,
    u64,
) {
    let mut state = application::new_for_testing(ctx);
    let (tool_registry, tool, tool_owner, cashier_owner, clock) = register_review_tool(
        &state,
        ctx,
    );
    let mut registry = agent_registry::new_for_testing(ctx);
    let (mut dag, owner, agent_id, skill_id) = application::prepare_agent_for_testing(
        &mut registry,
        &mut state,
        &tool_registry,
        ctx,
    );
    dag.finalize_for_testing(owner);
    (
        registry,
        tool_registry,
        dag,
        state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
        agent_id,
        skill_id,
    )
}

fun destroy_setup(
    registry: AgentRegistry,
    tool_registry: ToolRegistry,
    dag: DAG,
    state: ApplicationState,
    tool: Tool,
    tool_owner: CloneableOwnerCap<OverTool>,
    cashier_owner: CloneableOwnerCap<OverToolCashier>,
    clock: Clock,
) {
    destroy(registry);
    destroy(tool_registry);
    destroy(dag);
    application::destroy_for_testing(state);
    destroy(tool);
    destroy(tool_owner);
    destroy(cashier_owner);
    destroy(clock);
}

fun scheduled_fixture(content: vector<u8>, ctx: &mut TxContext): ScheduledFixture {
    let (
        registry,
        tool_registry,
        dag,
        mut state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
        _,
        _,
    ) = setup(ctx);
    application::fund_agent(&mut state, coin::mint_for_testing(2_100_000_000, ctx));
    let authority = runtime_authority::new_for_testing(ctx);
    let (task, pointer) = application::prepare_review_for_testing(
        &authority,
        &registry,
        &dag,
        &tool_registry,
        &mut state,
        content,
        object::id_from_address(@0xBEEF),
        &clock,
        ctx,
    );
    ScheduledFixture {
        authority,
        registry,
        tool_registry,
        dag,
        state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
        task,
        pointer,
    }
}

fun destroy_scheduled_fixture(fixture: ScheduledFixture) {
    let ScheduledFixture {
        authority,
        registry,
        tool_registry,
        dag,
        mut state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
        mut task,
        pointer,
    } = fixture;
    application::cancel_review(&state, &mut task);
    application::close_review(&mut state, &mut task);
    destroy(authority);
    destroy(task);
    destroy(pointer);
    destroy_setup(
        registry,
        tool_registry,
        dag,
        state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
    );
}

#[test]
fun setup_binds_an_embedded_agent_to_the_review_tool() {
    let ctx = &mut tx_context::dummy();
    let (
        registry,
        tool_registry,
        dag,
        state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
        agent_id,
        skill_id,
    ) = setup(ctx);

    assert_eq!(application::agent_id(&state), agent_id);
    assert_eq!(application::dag_id(&state), object::id(&dag));
    assert_eq!(application::skill_id(&state), skill_id);
    assert!(dag.is_finalized());
    tool_registry.assert_registered_dag(&dag);

    let requirements = application::skill_requirements_for_testing(&registry, &state);
    assert_eq!(
        agent_interface::requirements_schedule_policy(requirements),
        agent_interface::schedule_once(),
    );
    let fixed_tools = agent_interface::requirements_fixed_tools(requirements);
    assert_eq!(fixed_tools.length(), 1);
    assert_eq!(agent_interface::fixed_tool_registry_id(fixed_tools[0]), object::id(&tool_registry));
    assert_eq!(agent_interface::fixed_tool_fqn(fixed_tools[0]), application::review_vertex_fqn());

    destroy_setup(
        registry,
        tool_registry,
        dag,
        state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
    );
}

#[test]
fun scheduling_and_closing_manage_the_complete_task_lifecycle() {
    let ctx = &mut tx_context::new_from_hint(ALICE, 0, 0, 0, 0);
    let ScheduledFixture {
        authority,
        registry,
        tool_registry,
        dag,
        mut state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
        mut task,
        pointer,
    } = scheduled_fixture(b"hello Nexus", ctx);

    assert_eq!(task.controller(), task::agent_controller(application::agent_id(&state)));
    assert_eq!(task::task_id(&pointer), object::id(&task));
    assert_eq!(application::pending_task_id(&state), object::id(&task));
    assert_eq!(
        interface_authorization::agent_skill_authorization_grant_count(task.authorization()),
        1,
    );
    assert!(scheduler::advertised_occurrence(&task).is_some());
    assert_eq!(application::agent_balance(&state), 1_400_000_000);

    application::cancel_review(&state, &mut task);
    application::close_review(&mut state, &mut task);
    assert!(!application::has_pending_review(&state));
    assert!(task.is_finalized());
    assert_eq!(application::agent_balance(&state), 2_100_000_000);

    destroy(authority);
    destroy(task);
    destroy(pointer);
    destroy_setup(
        registry,
        tool_registry,
        dag,
        state,
        tool,
        tool_owner,
        cashier_owner,
        clock,
    );
}

fun execute_review(
    fixture: &mut ScheduledFixture,
    committed_content: vector<u8>,
    actual_content: vector<u8>,
    ctx: &mut TxContext,
): (ID, UID, UID) {
    let dag_id = application::dag_id(&fixture.state);
    let witness_id = application::tool_witness_id(&fixture.state);
    execute_review_with_task(
        &fixture.task,
        dag_id,
        witness_id,
        &mut fixture.state,
        committed_content,
        actual_content,
        ctx,
    )
}

fun execute_review_with_task(
    task: &Task,
    expected_dag_id: ID,
    required_witness_id: ID,
    state: &mut ApplicationState,
    committed_content: vector<u8>,
    actual_content: vector<u8>,
    ctx: &mut TxContext,
): (ID, UID, UID) {
    let execution_uid = object::new(ctx);
    let leader_uid = object::new(ctx);
    let (grant, agent_id) = {
        let task_authorization = task.authorization();
        (
            interface_authorization::copy_agent_skill_authorization_vertex_grant(
                task_authorization,
                0,
            ),
            interface_authorization::agent_skill_authorization_agent_id(task_authorization),
        )
    };
    let value = primitive_authorization::grant_value(&grant);
    assert_eq!(interface_authorization::agent_vertex_authorization_dag_id(&value), expected_dag_id);
    assert_eq!(
        interface_authorization::agent_vertex_authorization_vertex(&value),
        application::review_vertex_name(),
    );
    assert_eq!(
        interface_authorization::agent_vertex_authorization_task_id(&value),
        object::id(task),
    );
    let commitment = review_vertex::input_commitment_for_testing(state, &committed_content);
    let context = interface_authorization::agent_vertex_authorization_context(
        agent_id,
        interface_authorization::agent_vertex_authorization_skill_id(&value),
        interface_authorization::agent_vertex_authorization_interface_version(&value),
        object::uid_to_inner(&execution_uid),
        interface_authorization::agent_vertex_authorization_vertex(&value),
        interface_authorization::agent_vertex_authorization_task_id(&value),
    );
    let stamp = interface_authorization::agent_vertex_authorization_stamp(
        context,
        copy commitment,
    );
    let mut worksheet = proof_of_uid::new(&execution_uid);
    worksheet.stamp_with_data(&execution_uid, std::bcs::to_bytes(&stamp));
    worksheet.stamp(&leader_uid);

    let result = onchain_tool_result::new(&execution_uid, &worksheet, &stamp, ctx);
    let result_id = onchain_tool_result::id(&result);
    let mut remaining = vec_set::singleton(required_witness_id);
    remaining.insert(result_id);
    let requirements = worksheet.into_requirements(&execution_uid, remaining);

    let authorization = primitive_authorization::grant_into_proven_value(grant);
    review_vertex::execute(
        authorization,
        requirements,
        result,
        state,
        actual_content,
        ctx,
    );
    (result_id, execution_uid, leader_uid)
}

fun assert_result(
    scenario: &mut test_scenario::Scenario,
    result_id: ID,
    execution_uid: &UID,
    leader_uid: &UID,
    state_id: ID,
    expected_tag: vector<u8>,
    expected_port: vector<u8>,
    expected_value: vector<u8>,
) {
    scenario.next_tx(ALICE);
    let result: OnchainToolResult = scenario.take_shared_by_id(result_id);
    let (stamps, tag, payload, digest, recipient) = onchain_tool_result::consume(
        result,
        execution_uid,
    );
    assert!(stamps.contains(&object::uid_to_inner(execution_uid)));
    assert!(stamps.contains(&object::uid_to_inner(leader_uid)));
    assert!(stamps.contains(&state_id));
    assert!(stamps.contains(&result_id));
    assert_eq!(stamps.length(), 4);
    assert_eq!(tag, expected_tag);
    let (name, value) = payload.get_entry_by_idx(0);
    assert_eq!(*name, expected_port);
    assert_eq!(value.inline_data_bytes().destroy_some(), expected_value);
    assert_eq!(digest.length(), 32);
    assert_eq!(recipient, ALICE);
}

#[test]
fun execute_accepts_content_and_finalizes_the_nexus_result() {
    let mut scenario = test_scenario::begin(ALICE);
    let mut fixture = scheduled_fixture(b"hello", scenario.ctx());
    let state_id = application::state_id(&fixture.state);
    let (result_id, execution_uid, leader_uid) = execute_review(
        &mut fixture,
        b"hello",
        b"hello",
        scenario.ctx(),
    );

    assert_result(
        &mut scenario,
        result_id,
        &execution_uid,
        &leader_uid,
        state_id,
        b"accepted",
        b"length",
        b"5",
    );
    assert_eq!(application::accepted_count(&fixture.state), 1);
    assert_eq!(application::rejected_count(&fixture.state), 0);

    execution_uid.delete();
    leader_uid.delete();
    destroy_scheduled_fixture(fixture);
    scenario.end();
}

#[test, expected_failure(abort_code = application::EAuthorizationMismatch)]
fun execute_rejects_authorization_for_another_application_state() {
    let ctx = &mut tx_context::dummy();
    let fixture = scheduled_fixture(b"hello", ctx);
    let dag_id = application::dag_id(&fixture.state);
    let required_witness_id = application::tool_witness_id(&fixture.state);
    let mut other_state = application::new_for_testing(ctx);

    let (_, execution_uid, leader_uid) = execute_review_with_task(
        &fixture.task,
        dag_id,
        required_witness_id,
        &mut other_state,
        b"hello",
        b"hello",
        ctx,
    );
    execution_uid.delete();
    leader_uid.delete();
    application::destroy_for_testing(other_state);
    destroy_scheduled_fixture(fixture);
    abort
}

#[test]
fun execute_rejects_short_content_and_finalizes_the_nexus_result() {
    let mut scenario = test_scenario::begin(ALICE);
    let mut fixture = scheduled_fixture(b"no", scenario.ctx());
    let state_id = application::state_id(&fixture.state);
    let (result_id, execution_uid, leader_uid) = execute_review(
        &mut fixture,
        b"no",
        b"no",
        scenario.ctx(),
    );

    assert_result(
        &mut scenario,
        result_id,
        &execution_uid,
        &leader_uid,
        state_id,
        b"rejected",
        b"minimum_length",
        b"5",
    );
    assert_eq!(application::accepted_count(&fixture.state), 0);
    assert_eq!(application::rejected_count(&fixture.state), 1);

    execution_uid.delete();
    leader_uid.delete();
    destroy_scheduled_fixture(fixture);
    scenario.end();
}

#[
    test,
    expected_failure(
        abort_code = review_vertex::EInputCommitmentMismatch,
        location = nexus_local_testing::review_vertex,
    ),
]
fun execute_rejects_content_that_does_not_match_the_committed_input() {
    let ctx = &mut tx_context::dummy();
    let mut fixture = scheduled_fixture(b"hello Nexus", ctx);
    let (_, execution_uid, leader_uid) = execute_review(
        &mut fixture,
        b"hello Nexus",
        b"changed content",
        ctx,
    );
    execution_uid.delete();
    leader_uid.delete();
    destroy_scheduled_fixture(fixture);
    abort
}
