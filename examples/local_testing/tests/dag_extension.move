#[test_only]
extend module nexus_interface::dag;

use nexus_interface::era;
use nexus_primitives::{object_state, owner_cap::CloneableOwnerCap};

/// Marks a test DAG final while keeping it locally owned for later assertions.
///
/// Production uses `finalize`, which freezes the DAG. This fixture recreates
/// only the state produced by the removed Nexus test helper.
public fun finalize_for_testing(self: &mut DAG, owner: CloneableOwnerCap<OverDAG>) {
    assert!(owner.is_for(self));
    object_state::inner_mut<era::V1, DAGInnerV1>(&mut self.id).finalized = true;
    owner.destroy();
}
