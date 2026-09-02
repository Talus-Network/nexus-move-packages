#[test_only]
module nexus_local_testing::application_tests;

use nexus_local_testing::application::{Self as application, ReviewState};
use nexus_primitives::data;
use nexus_primitives::tagged_output;
use nexus_scheduler::task;
use std::unit_test::assert_eq;
use sui::test_scenario;
use sui::transfer::public_share_object;

const ALICE: address = @0xA11CE;

#[test]
fun complete_flow_accepts_and_rejects_canonical_inputs() {
    let ctx = &mut tx_context::dummy();
    let schema = application::schema();
    schema.assert_valid_for_tool(false);
    let mut state = application::new(5, ctx);

    let accepted_input = application::prepare_input(&schema, b"hello Nexus");
    assert!(schema.conforms_complete_input(&vector[copy accepted_input]));
    let accepted = application::review(&mut state, &accepted_input);
    assert!(schema.conforms_raw_output(&accepted));
    assert_eq!(*tagged_output::tag(&accepted), b"accepted");
    assert_eq!(
        accepted.payload_inline_bytes_for_testing(b"content"),
        b"hello Nexus",
    );

    let rejected_input = application::prepare_input(&schema, b"no");
    assert!(schema.conforms_complete_input(&vector[copy rejected_input]));
    let rejected = application::review(&mut state, &rejected_input);
    assert!(schema.conforms_raw_output(&rejected));
    assert_eq!(*tagged_output::tag(&rejected), b"rejected");
    assert_eq!(
        rejected.payload_inline_bytes_for_testing(b"reason"),
        b"content is too short",
    );

    assert_eq!(application::accepted_count(&state), 1);
    assert_eq!(application::rejected_count(&state), 1);
    application::destroy_for_testing(state);
}

#[test]
fun extension_fixture_exercises_invalid_input_path() {
    let ctx = &mut tx_context::dummy();
    let schema = application::schema();
    let malformed = data::unchecked_many_for_testing(vector[]);
    let mut state = application::new(1, ctx);

    assert!(!schema.conforms_complete_input(&vector[copy malformed]));
    let output = application::review(&mut state, &malformed);
    assert_eq!(*tagged_output::tag(&output), b"rejected");
    assert_eq!(application::rejected_count(&state), 1);

    application::destroy_for_testing(state);
}

#[test]
fun state_persists_across_transaction_boundaries() {
    let mut scenario = test_scenario::begin(ALICE);
    public_share_object(application::new(5, scenario.ctx()));

    scenario.next_tx(ALICE);
    let mut state: ReviewState = scenario.take_shared();
    let schema = application::schema();
    let input = application::prepare_input(&schema, b"first review");
    let output = application::review(&mut state, &input);
    assert!(schema.conforms_raw_output(&output));
    test_scenario::return_shared(state);

    scenario.next_tx(ALICE);
    let state: ReviewState = scenario.take_shared();
    assert_eq!(application::accepted_count(&state), 1);
    assert_eq!(application::rejected_count(&state), 0);
    application::destroy_for_testing(state);

    scenario.end();
}

#[test]
fun extension_calls_published_nexus_functions() {
    let value = data::published_inline_for_testing(b"hello Nexus");

    assert_eq!(value.inline_data_bytes().destroy_some(), b"hello Nexus");
}

#[test]
fun extensions_compose_across_nexus_packages() {
    let (status, value) = task::active_with_data_for_testing(b"composed");

    assert!(status.is_active_for_testing());
    assert_eq!(value.inline_data_bytes().destroy_some(), b"composed");
}

#[test, expected_failure(
    major_status = 4016,
    location = nexus_primitives::data,
)]
fun published_constructor_rejects_an_empty_collection() {
    data::many(vector[]);
}
