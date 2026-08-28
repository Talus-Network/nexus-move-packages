module nexus_scheduler::execution_settlement;

//! Interface for [`nexus_scheduler::execution_settlement`].
//!
//! Calls resolve to the published package.

/// Aborts an execution whose active walk has expired.
public native fun abort_expired_execution(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);

/// Records gas and settles one committed Tool result as the responsible leader.
public native fun settle_committed_tool_result_for_walk_by_leader(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    priority_fee_vault: &nexus_registry::priority_fee_vault::PriorityFeeVault,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    walk_index: u64,
    expected_vertex: nexus_interface::graph::RuntimeVertex,
    failed_onchain_tool_reason: std::option::Option<vector<u8>>,
    commit_tx_digest: vector<u8>,
    commit_gas_charge: u64,
    settlement_gas_charge: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);

/// Records one leader's committed Tool result gas charge.
public native fun record_committed_tool_result_gas_charge_by_leader(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    leader_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_registry::leader_cap::OverNetwork,
    >,
    walk_index: u64,
    expected_vertex: nexus_interface::graph::RuntimeVertex,
    failed_onchain_tool_reason: std::option::Option<vector<u8>>,
    commit_tx_digest: vector<u8>,
    commit_gas_charge: u64,
    settlement_gas_charge: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);

/// Refills one execution payment from a coin.
public native fun refill_tap_execution_payment(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    execution: &mut nexus_workflow::execution::DAGExecution,
    coin: sui::coin::Coin<sui::sui::SUI>,
    ctx: &mut sui::tx_context::TxContext,
);

/// Refills one execution payment from its Agent vault.
public native fun refill_tap_execution_payment_from_agent_vault(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    agent: &mut nexus_interface::agent::Agent,
    execution: &mut nexus_workflow::execution::DAGExecution,
    amount: u64,
);

/// Settles one committed Tool result after its permissionless deadline.
public native fun settle_committed_tool_result_for_walk(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    priority_fee_vault: &nexus_registry::priority_fee_vault::PriorityFeeVault,
    walk_index: u64,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);

/// Removes an invalid Tool result after its cleanup deadline.
public native fun cleanup_broken_onchain_tool_result(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    result: nexus_interface::onchain_tool_result::OnchainToolResult,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    walk_index: u64,
    tool_witness_id: sui::object::ID,
    clock: &sui::clock::Clock,
);

/// Consumes and settles a permissionless onchain Tool result.
public native fun settle_onchain_tool_result_for_walk(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    tool_registry: &nexus_tool::tool_registry::ToolRegistry,
    result: nexus_interface::onchain_tool_result::OnchainToolResult,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    priority_fee_vault: &nexus_registry::priority_fee_vault::PriorityFeeVault,
    walk_index: u64,
    expected_vertex: nexus_interface::graph::RuntimeVertex,
    tool_witness_id: sui::object::ID,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);

/// Emits requests for active walks whose payment is ready.
public native fun emit_payment_ready_walk_requests(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    dag: &nexus_interface::dag::DAG,
    execution: &mut nexus_workflow::execution::DAGExecution,
    leader_registry: &nexus_registry::leader::LeaderRegistry,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
);
