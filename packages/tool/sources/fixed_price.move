/// Interface for the published [`nexus_tool::fixed_price`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_tool::fixed_price;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Private construction witness for this policy.
public struct Policy has drop {}

/// Creates an Invocation for the price snapshotted by its execution.
public fun get_invocation(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    request: nexus_interface::payment::InvocationRequest,
    ctx: &mut sui::tx_context::TxContext,
): nexus_tool::invocation::Invocation {
    abort ELocalExecutionUnavailable
}

/// Collects finalized fixed price Invocations under Tool owner authority.
public fun collect(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    invocations: vector<sui::transfer::Receiving<nexus_tool::invocation::Invocation>>,
): sui::balance::Balance<sui::sui::SUI> {
    abort ELocalExecutionUnavailable
}
