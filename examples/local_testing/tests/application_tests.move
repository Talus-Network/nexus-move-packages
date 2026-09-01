#[test_only]
module nexus_local_testing::application_tests;

use nexus_local_testing::application;
use nexus_primitives::data;
use nexus_scheduler::task;
use std::unit_test::assert_eq;

/// Expected local error from every existing Nexus interface function.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

#[test]
fun extensions_construct_nexus_values() {
    let value = data::inline_for_testing(b"hello");
    let status = task::active_for_testing();
    let observation = application::observe(value, status, true);

    assert!(observation.is_accepted());
    assert_eq!(observation.value().inline_length_for_testing(), 5);
    assert!(observation.status().is_active_for_testing());
}

/// Confirms that an existing Nexus function aborts during local execution.
#[test, expected_failure(abort_code = ELocalExecutionUnavailable, location = data)]
fun published_constructor_aborts_locally() {
    data::inline_data_value(b"hello");
}
