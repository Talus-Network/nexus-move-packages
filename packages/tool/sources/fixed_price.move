module nexus_tool::fixed_price;

//! Interface for [`nexus_tool::fixed_price`].
//!
//! Calls resolve to the published package.

/// Private construction witness for this policy.
public struct Policy has drop {}

/// Creates an Invocation for the price snapshotted by its execution.
public native fun get_invocation(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    request: nexus_interface::payment::InvocationRequest,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::invocation::Invocation;

/// Collects finalized fixed price Invocations under Tool owner authority.
public native fun collect(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    invocations: vector<sui::transfer::Receiving<nexus_tool::invocation::Invocation>>,
): sui::balance::Balance<sui::sui::SUI>;
