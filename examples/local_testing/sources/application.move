module nexus_local_testing::application;

use nexus_interface::{
    agent::{Self as agent_interface, Agent, SkillRequirement},
    authorization::{Self as interface_authorization, AgentVertexAuthorization},
    dag::{Self as dag, DAG},
    graph,
    payment as payment_interface
};
use nexus_kernel::runtime_authority::RuntimeAuthority;
use nexus_primitives::{
    authorization::ProvenValue,
    data,
    owner_cap::CloneableOwnerCap,
    proof_of_uid::{ProofOfUID, UIDRequirements},
    tagged_output::{Self as tagged_output, TaggedOutput}
};
use nexus_registry::agent_registry::{Self as agent_registry, AgentRegistry};
use nexus_scheduler::{scheduler, task::{Task, TaskPointer}};
use nexus_tool::tool_registry::ToolRegistry;
use std::ascii::String as AsciiString;
use sui::{clock::Clock, coin::Coin, event, sui::SUI, transfer::public_share_object};

//! A small embedded TAP application with one Agent and one onchain Tool vertex.

// === Errors ===

#[error]
const EAlreadyConfigured: vector<u8> = b"The content review Agent is already configured";

#[error]
const EAuthorizationMismatch: vector<u8> = b"The review call is not authorized for this TAP";

#[error]
const EDagMismatch: vector<u8> = b"The supplied DAG does not belong to this TAP";

#[error]
const EPendingReview: vector<u8> = b"A content review Task is already pending";

#[error]
const EReviewTaskMismatch: vector<u8> = b"The Task does not belong to the pending content review";

#[error]
const ESkillMissing: vector<u8> = b"The content review Agent has not been configured";

#[error]
const ETaskMissing: vector<u8> = b"No content review Task is pending";

// === Constants ===

const ACCEPTED_TAG: vector<u8> = b"accepted";
const INPUT_COMMITMENT: vector<u8> = b"content-review-input-v1";
const LENGTH_PORT: vector<u8> = b"length";
const MINIMUM_LENGTH: u64 = 5;
const MINIMUM_LENGTH_PORT: vector<u8> = b"minimum_length";
const PAYMENT_MAX_BUDGET_MIST: u64 = 1_500_000_000;
const REJECTED_TAG: vector<u8> = b"rejected";
const REVIEW_TASK_BUDGET_MIST: u64 = 700_000_000;
const UNCONFIGURED_DAG: address = @0x0;

// === Types ===

/// One time witness for package initialization.
public struct APPLICATION has drop {}

/// Durable state owned by the TAP application.
///
/// The state owns the embedded Agent. Its UID also identifies the review Tool
/// and receives the per vertex authorization grant.
public struct ApplicationState has key, store {
    id: UID,
    dag_id: ID,
    skill_id: option::Option<u64>,
    agent: Agent,
    pending_task_id: option::Option<ID>,
    accepted_count: u64,
    rejected_count: u64,
}

/// Emitted after the application creates and binds its Agent skill.
public struct ApplicationConfiguredEvent has copy, drop {
    state_id: ID,
    agent_id: ID,
    dag_id: ID,
    skill_id: u64,
}

// === Application lifecycle ===

/// Creates the Agent, binds its review DAG and skill, then freezes the DAG.
///
/// The review Tool must already be registered in `tool_registry` under the FQN
/// returned by `review_vertex_fqn`.
public fun setup_agent(
    registry: &mut AgentRegistry,
    state: &mut ApplicationState,
    tool_registry: &ToolRegistry,
    ctx: &mut TxContext,
): (ID, u64, ID) {
    let (dag, owner, agent_id, skill_id) = prepare_agent(registry, state, tool_registry, ctx);
    let dag_id = object::id(&dag);
    dag::finalize(dag, owner);
    (agent_id, skill_id, dag_id)
}

/// Deposits SUI into the embedded Agent payment vault.
public fun fund_agent(state: &mut ApplicationState, coin: Coin<SUI>) {
    agent_interface::deposit_agent_payment_vault(&mut state.agent, coin);
}

/// Creates and schedules one Agent funded content review Task.
public fun schedule_review(
    authority: &RuntimeAuthority,
    registry: &AgentRegistry,
    dag: &DAG,
    tool_registry: &ToolRegistry,
    state: &mut ApplicationState,
    content: vector<u8>,
    network: ID,
    clock: &Clock,
    ctx: &mut TxContext,
): (ID, TaskPointer) {
    let (task, pointer) = prepare_review_task(
        authority,
        registry,
        dag,
        tool_registry,
        state,
        content,
        network,
        clock,
        ctx,
    );
    let task_id = object::id(&task);
    scheduler::share(task);
    (task_id, pointer)
}

/// Cancels work that has not entered execution for the pending review Task.
public fun cancel_review(state: &ApplicationState, task: &mut Task) {
    assert_pending_task(state, task);
    scheduler::cancel_as_agent(task, &state.agent);
}

/// Closes a terminal review Task, refunds its reserve and clears application state.
///
/// An active Task must first finish or be canceled with `cancel_review`.
public fun close_review(state: &mut ApplicationState, task: &mut Task) {
    assert_pending_task(state, task);
    scheduler::close_as_agent(task, &mut state.agent);
    let _ = state.pending_task_id.extract();
}

// === Public views ===

/// Returns the Tool FQN bound to the review DAG vertex.
public fun review_vertex_fqn(): AsciiString {
    b"example.taluslabs.content_review@1".to_ascii_string()
}

/// Returns the stable review vertex name used by the DAG and grants.
public fun review_vertex_name(): AsciiString {
    b"review".to_ascii_string()
}

/// Returns the application state object ID.
public fun state_id(state: &ApplicationState): ID {
    object::id(state)
}

/// Returns the embedded Agent object ID.
public fun agent_id(state: &ApplicationState): ID {
    object::id(&state.agent)
}

/// Returns the review DAG object ID after setup.
public fun dag_id(state: &ApplicationState): ID {
    state.dag_id
}

/// Returns the embedded Agent skill ID after setup.
public fun skill_id(state: &ApplicationState): u64 {
    assert!(state.skill_id.is_some(), ESkillMissing);
    *state.skill_id.borrow()
}

/// Returns the object ID that must be registered as the Tool witness.
public fun tool_witness_id(state: &ApplicationState): ID {
    object::id(state)
}

/// Returns whether one review Task is waiting for application cleanup.
public fun has_pending_review(state: &ApplicationState): bool {
    state.pending_task_id.is_some()
}

/// Returns the pending review Task ID.
public fun pending_task_id(state: &ApplicationState): ID {
    assert!(state.pending_task_id.is_some(), ETaskMissing);
    *state.pending_task_id.borrow()
}

/// Returns the number of accepted reviews.
public fun accepted_count(state: &ApplicationState): u64 {
    state.accepted_count
}

/// Returns the number of rejected reviews.
public fun rejected_count(state: &ApplicationState): u64 {
    state.rejected_count
}

/// Returns the spendable SUI balance in the embedded Agent vault.
public fun agent_balance(state: &ApplicationState): u64 {
    agent_interface::agent_payment_vault_available_balance(&state.agent)
}

// === Tool integration ===

/// Applies the review after authenticating the grant released for this vertex.
public(package) fun review_for_tool(
    state: &mut ApplicationState,
    authorization: ProvenValue<AgentVertexAuthorization>,
    worksheet: &ProofOfUID,
    input_commitment: vector<u8>,
    content: &vector<u8>,
): TaggedOutput {
    assert!(
        interface_authorization::consume_verified_for_worksheet_as_recipient(
            authorization,
            worksheet,
            &state.id,
            input_commitment,
        ),
        EAuthorizationMismatch,
    );

    let length = content.length();
    if (length < MINIMUM_LENGTH) {
        state.rejected_count = state.rejected_count + 1;
        tagged_output::new(copy REJECTED_TAG).with_named_payload(
            copy MINIMUM_LENGTH_PORT,
            data::inline_data_value(MINIMUM_LENGTH.to_string().into_bytes()),
        )
    } else {
        state.accepted_count = state.accepted_count + 1;
        tagged_output::new(copy ACCEPTED_TAG).with_named_payload(
            copy LENGTH_PORT,
            data::inline_data_value(length.to_string().into_bytes()),
        )
    }
}

public(package) fun satisfy_review_requirement(
    state: &ApplicationState,
    requirements: &mut UIDRequirements,
) {
    requirements.satisfy(&state.id);
}

public(package) fun byte_data_values(content: &vector<u8>): vector<data::NexusValue> {
    content.map_ref!(|byte| data::inline_data_value((*byte).to_string().into_bytes()))
}

// === Private functions ===

fun init(_otw: APPLICATION, ctx: &mut TxContext) {
    public_share_object(new(ctx));
}

fun new(ctx: &mut TxContext): ApplicationState {
    ApplicationState {
        id: object::new(ctx),
        dag_id: object::id_from_address(UNCONFIGURED_DAG),
        skill_id: option::none(),
        agent: agent_interface::create_agent_identity(ctx),
        pending_task_id: option::none(),
        accepted_count: 0,
        rejected_count: 0,
    }
}

fun prepare_agent(
    registry: &mut AgentRegistry,
    state: &mut ApplicationState,
    tool_registry: &ToolRegistry,
    ctx: &mut TxContext,
): (DAG, CloneableOwnerCap<dag::OverDAG>, ID, u64) {
    assert!(state.skill_id.is_none(), EAlreadyConfigured);
    agent_registry::attach_embedded_agent(registry, &mut state.agent, ctx);
    let (dag, owner) = create_review_dag(tool_registry, ctx);
    state.dag_id = object::id(&dag);
    let skill_id = agent_registry::register_skill(
        registry,
        &mut state.agent,
        tool_registry,
        &dag,
        b"Reviews content length with one authorized onchain Tool",
        copy INPUT_COMMITMENT,
        payment_interface::payment_policy_agent_funded(PAYMENT_MAX_BUDGET_MIST),
        agent_interface::schedule_once(),
        vector[
            agent_interface::fixed_tool(
                object::id(tool_registry),
                review_vertex_fqn(),
            ),
        ],
        ctx,
    );
    state.skill_id.fill(skill_id);
    let agent_id = object::id(&state.agent);
    event::emit(ApplicationConfiguredEvent {
        state_id: object::id(state),
        agent_id,
        dag_id: object::id(&dag),
        skill_id,
    });
    (dag, owner, agent_id, skill_id)
}

fun create_review_dag(
    tool_registry: &ToolRegistry,
    ctx: &mut TxContext,
): (DAG, CloneableOwnerCap<dag::OverDAG>) {
    let vertex = graph::vertex_from_string(review_vertex_name());
    let (mut dag, mut owner) = dag::new(ctx);
    tool_registry.add_vertex_to_dag(
        &mut dag,
        &mut owner,
        copy vertex,
        graph::vertex_on_chain(review_vertex_fqn()),
    );
    (
        dag
            .with_entry_port(copy vertex, graph::input_port_from_string(b"0".to_ascii_string()))
            .with_entry_port(vertex, graph::input_port_from_string(b"1".to_ascii_string())),
        owner,
    )
}

fun prepare_review_task(
    authority: &RuntimeAuthority,
    registry: &AgentRegistry,
    dag: &DAG,
    tool_registry: &ToolRegistry,
    state: &mut ApplicationState,
    content: vector<u8>,
    network: ID,
    clock: &Clock,
    ctx: &mut TxContext,
): (Task, TaskPointer) {
    assert!(state.skill_id.is_some(), ESkillMissing);
    assert!(state.dag_id == object::id(dag), EDagMismatch);
    assert!(state.pending_task_id.is_none(), EPendingReview);

    let vertex = graph::vertex_from_string(review_vertex_name());
    let state_id = object::id(state);
    let config = agent_interface::new_agent_execution_config(
        object::id(&state.agent),
        network,
        graph::default_entry_group(),
        graph::inputs_to_begin_execution(
            vector[copy vertex, copy vertex],
            vector[
                graph::input_port_from_string(b"0".to_ascii_string()),
                graph::input_port_from_string(b"1".to_ascii_string()),
            ],
            vector[data::one(data::object_value(state_id)), data::many(byte_data_values(&content))],
        ),
        *state.skill_id.borrow(),
        option::none(),
        sui::vec_map::from_keys_values(vector[vertex], vector[state_id]),
        ctx,
    );
    let (mut task, pointer) = scheduler::new_agent_task(
        registry,
        dag,
        tool_registry,
        &mut state.agent,
        config,
        REVIEW_TASK_BUDGET_MIST,
        REVIEW_TASK_BUDGET_MIST,
        scheduler::continue_on_failure(),
        ctx,
    );
    scheduler::schedule_as_agent(
        authority,
        &mut task,
        &state.agent,
        clock.timestamp_ms(),
        option::none(),
        20,
    );
    state.pending_task_id.fill(object::id(&task));
    (task, pointer)
}

fun assert_pending_task(state: &ApplicationState, task: &Task) {
    assert!(state.pending_task_id.is_some(), ETaskMissing);
    assert!(*state.pending_task_id.borrow() == object::id(task), EReviewTaskMismatch);
}

// === Test support ===

/// Creates unshared application state for a unit test.
#[test_only]
public fun new_for_testing(ctx: &mut TxContext): ApplicationState {
    new(ctx)
}

/// Uses the production setup path but returns the DAG before production freezes it.
#[test_only]
public fun prepare_agent_for_testing(
    registry: &mut AgentRegistry,
    state: &mut ApplicationState,
    tool_registry: &ToolRegistry,
    ctx: &mut TxContext,
): (DAG, CloneableOwnerCap<dag::OverDAG>, ID, u64) {
    prepare_agent(registry, state, tool_registry, ctx)
}

/// Uses the production scheduling path while keeping the Task locally owned.
#[test_only]
public fun prepare_review_for_testing(
    authority: &RuntimeAuthority,
    registry: &AgentRegistry,
    dag: &DAG,
    tool_registry: &ToolRegistry,
    state: &mut ApplicationState,
    content: vector<u8>,
    network: ID,
    clock: &Clock,
    ctx: &mut TxContext,
): (Task, TaskPointer) {
    prepare_review_task(
        authority,
        registry,
        dag,
        tool_registry,
        state,
        content,
        network,
        clock,
        ctx,
    )
}

/// Returns the registered skill requirements for unit assertions.
#[test_only]
public fun skill_requirements_for_testing(
    registry: &AgentRegistry,
    state: &ApplicationState,
): SkillRequirement {
    agent_registry::get_skill_requirements(registry, &state.agent, skill_id(state))
}

/// Removes all application test resources after their assertions complete.
#[test_only]
public fun destroy_for_testing(state: ApplicationState) {
    std::unit_test::destroy(state);
}
