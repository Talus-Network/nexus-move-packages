module nexus_tool::invocation;

//! Interface for [`nexus_tool::invocation`].
//!
//! Calls resolve to the published package.

/// Typed reserve key for policy witness [P].
public struct ReserveKey<phantom P: drop>() has copy, drop, store;

/// Exact policy authorization for one Tool invocation.
///
/// The missing [store] ability ensures that only this module can transfer or
/// receive an [Invocation].
public struct Invocation has key {
    id: sui::object::UID,
    execution_id: address,
    vertex_key: vector<u8>,
    tool_id: sui::object::ID,
    cashier_id: sui::object::ID,
    beneficiary: nexus_interface::payment::PaymentSourceKind,
    policy: std::type_name::TypeName,
    sources: vector<sui::object::ID>,
    amount: u64,
    refund_to: std::option::Option<address>,
    funds: sui::balance::Balance<sui::sui::SUI>,
}

/// Consumes a canonical request and creates one Invocation under policy [P].
public native fun new_invocation<P: drop>(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    request: nexus_interface::payment::InvocationRequest,
    _: P,
    sources: vector<sui::object::ID>,
    amount: u64,
    ctx: &mut sui::tx_context::TxContext,
): Invocation;

/// Creates one Invocation carrying the exact policy reserve restored on refund.
public native fun new_invocation_with_reserve<P: drop, R: store>(
    cashier: &nexus_tool::tool_cashier::ToolCashier,
    request: nexus_interface::payment::InvocationRequest,
    policy: P,
    reserve: R,
    refund_to: address,
    sources: vector<sui::object::ID>,
    amount: u64,
    ctx: &mut sui::tx_context::TxContext,
): Invocation;

/// Returns the object ID of [Invocation].
public native fun id(self: &Invocation): sui::object::ID;

/// Returns the execution authorized by [Invocation].
public native fun execution_id(self: &Invocation): address;

/// Returns the runtime vertex key authorized by [Invocation].
public native fun vertex_key(self: &Invocation): vector<u8>;

/// Returns the Tool authorized by [Invocation].
public native fun tool(self: &Invocation): sui::object::ID;

/// Returns the cashier selected by [Invocation].
public native fun cashier(self: &Invocation): sui::object::ID;

/// Returns the payment source eligible for [Invocation].
public native fun beneficiary(self: &Invocation): nexus_interface::payment::PaymentSourceKind;

/// Returns the address that receives a policy reserve after refund.
public native fun refund_address(self: &Invocation): address;

/// Returns the policy witness type that created [Invocation].
public native fun policy(self: &Invocation): std::type_name::TypeName;

/// Returns the exact economic sources used by [Invocation].
public native fun sources(self: &Invocation): vector<sui::object::ID>;

/// Returns the SUI obligation selected by [Invocation].
public native fun amount(self: &Invocation): u64;

/// Places [Invocation] under its execution after consuming its exact lock receipt.
public native fun place(
    invocation: Invocation,
    receipt: nexus_interface::payment::InvocationLockReceipt,
);

/// Receives an [Invocation] owned by its execution.
public native fun receive(
    execution: &mut sui::object::UID,
    receiving: sui::transfer::Receiving<Invocation>,
): Invocation;

/// Receives a refunded [Invocation] at its recorded policy account.
public native fun receive_refund(
    account: &mut sui::object::UID,
    receiving: sui::transfer::Receiving<Invocation>,
): Invocation;

/// Resolves [Invocation] using the exact terminal receipt from its payment.
///
/// Finalization joins the recorded SUI and sends the completed Invocation to
/// its cashier. Refund sends a reserved Invocation to its beneficiary or
/// destroys an Invocation with no reserved resource.
public native fun resolve(
    invocation: Invocation,
    paid: sui::balance::Balance<sui::sui::SUI>,
    receipt: nexus_interface::payment::InvocationSettlementReceipt,
);

/// Receives completed Invocations created by configless policy witness [P].
public native fun collect<P: drop>(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    _: P,
    invocations: vector<sui::transfer::Receiving<Invocation>>,
): sui::balance::Balance<sui::sui::SUI>;

/// Receives completed Invocations and returns their exact policy reserves.
public native fun collect_with_reserve<P: drop, R: store>(
    cashier: &mut nexus_tool::tool_cashier::ToolCashier,
    owner_cap: &nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    _: P,
    invocations: vector<sui::transfer::Receiving<Invocation>>,
): (sui::balance::Balance<sui::sui::SUI>, vector<R>);

/// Recovers the exact policy reserve from a refunded [Invocation].
///
/// An Invocation has no [store] ability, so only the address that received the
/// refund can supply it and only this function can unpack it.
public native fun claim_refund<P: drop, R: store>(invocation: Invocation, _: P): R;
