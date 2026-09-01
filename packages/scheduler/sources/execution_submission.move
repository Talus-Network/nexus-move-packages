/// Interface for the published [`nexus_scheduler::execution_submission`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_scheduler::execution_submission;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Commits one verified offchain Tool result through the current runtime.
public fun commit_off_chain_tool_result_for_walk(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    network_auth: &nexus_registry::network_auth::NetworkAuth,
    worksheet: nexus_primitives::proof_of_uid::ProofOfUID,
    stamp: nexus_interface::authorization::AgentVertexAuthorizationStamp,
    verdict: nexus_interface::verifier::VerificationVerdict,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    walk_index: u64,
    expected_vertex: nexus_interface::graph::RuntimeVertex,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}

/// Prepares the authenticated worksheet for one Tool result submission.
public fun prepare_tool_result_submission_worksheet(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    agent_registry: &nexus_registry::agent_registry::AgentRegistry,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    network_auth: &nexus_registry::network_auth::NetworkAuth,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    execution: &mut nexus_workflow::execution::DAGExecution,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    walk_index: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): (
    nexus_primitives::proof_of_uid::ProofOfUID,
    nexus_interface::authorization::AgentVertexAuthorizationStamp,
) {
    abort ELocalExecutionUnavailable
}

/// Releases the authorization grant bound to one onchain Tool walk.
public fun release_vertex_authorization_for_onchain_walk(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    worksheet: &nexus_primitives::proof_of_uid::ProofOfUID,
    stamp: &nexus_interface::authorization::AgentVertexAuthorizationStamp,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    walk_index: u64,
): nexus_primitives::authorization::ProvenValue<
    nexus_interface::authorization::AgentVertexAuthorization,
> {
    abort ELocalExecutionUnavailable
}

/// Creates the result object and requirements for one onchain Tool walk.
public fun create_on_chain_tool_result_for_walk(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    worksheet: nexus_primitives::proof_of_uid::ProofOfUID,
    stamp: &nexus_interface::authorization::AgentVertexAuthorizationStamp,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    walk_index: u64,
    expected_vertex: nexus_interface::graph::RuntimeVertex,
    ctx: &mut sui::tx_context::TxContext,
): (
    nexus_primitives::proof_of_uid::UIDRequirements,
    nexus_interface::onchain_tool_result::OnchainToolResult,
) {
    abort ELocalExecutionUnavailable
}

/// Consumes and settles one finalized onchain Tool result through the current runtime.
public fun consume_on_chain_tool_result_for_walk(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    result: nexus_interface::onchain_tool_result::OnchainToolResult,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    priority_fee_vault: &nexus_registry::priority_fee_vault::PriorityFeeVault,
    walk_index: u64,
    expected_vertex: nexus_interface::graph::RuntimeVertex,
    tool_witness_id: sui::object::ID,
    commit_gas_charge: u64,
    settlement_gas_charge: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    abort ELocalExecutionUnavailable
}
