module nexus_tool::tool_registry;

//! Interface for [`nexus_tool::tool_registry`].
//!
//! Calls resolve to the published package.

/// Location and invocation identity of an off chain or on chain Tool.
public enum ToolRef has copy, drop, store {
    Http {
        url: vector<u8>,
    },
    Sui {
        package_address: address,
        module_name: std::ascii::String,
        tool_witness_id: sui::object::ID,
    },
}

/// Shared registry of tools, tracking timeouts, verifier methods, and collateral policy.
public struct ToolRegistry has key {
    id: sui::object::UID,
}

/// Version one stored layout for [`ToolRegistry`].
public struct ToolRegistryInnerV1 has store {
    /// Current FQN to stable Tool ID membership.
    tool_ids: sui::linked_table::LinkedTable<std::ascii::String, sui::object::ID>,
    /// Current stable Tool ID membership for submission time liveness checks.
    registered_tools: sui::table::Table<sui::object::ID, bool>,
    /// Immutable protocol schema for each currently registered Tool ID.
    meta_schemas: sui::table::Table<sui::object::ID, nexus_interface::meta_schema::MetaSchema>,
    /// Timeout by Tool FQN for execution time lookup without loading each derived Tool object.
    timeouts: sui::linked_table::LinkedTable<std::ascii::String, u64>,
    /// The one verified mode supported by each configured off chain Tool.
    verifier_support: sui::table::Table<
        sui::object::ID,
        nexus_interface::verifier::ToolVerifierSupport,
    >,
    /// External verifier configuration by stable Tool ID.
    external_verifiers: sui::table::Table<
        sui::object::ID,
        nexus_tool::external_verifier::ExternalVerifier,
    >,
    /// Invocation price in MIST by Tool FQN.
    invocation_costs_mist: sui::table::Table<std::ascii::String, u64>,
    /// Registered on chain tool witness IDs by FQN.
    on_chain_tool_witnesses: sui::linked_table::LinkedTable<std::ascii::String, sui::object::ID>,
    /// On chain tools whose execute function requires workflow vertex
    /// authorization cap as the first argument.
    workflow_authorization_cap_first: sui::linked_table::LinkedTable<std::ascii::String, bool>,
    /// How much [US] (in base units) to lock to register a tool.
    us_collateral_to_lock: u64,
    /// How long is the collateral locked for in milliseconds after unregistering.
    ///
    /// Copied to tool upon registration.
    lock_duration_ms: u64,
}

/// Generic derived object that holds information about a tool. On chain and
/// off chain tools are differentiated based on [`ToolRef`]
public struct Tool has key, store {
    id: sui::object::UID,
}

/// Version one stored layout for [`Tool`].
public struct ToolInnerV1 has store {
    registry: sui::object::ID,
    /// Fully qualified name of the tool.
    fqn: std::ascii::String,
    /// On chain package reference or off chain HTTP endpoint.
    ref: ToolRef,
    /// Description of the tool.
    description: vector<u8>,
    /// Immutable protocol schema used for registration, DAG construction, and execution.
    meta_schema: nexus_interface::meta_schema::MetaSchema,
    /// Verification status set by the slashing authority.
    ///
    /// Tools are registered as unverified by default.
    verified: bool,
    /// To register a tool one must lock [ToolRegistry::us_collateral_to_lock]
    /// [US].
    vault: sui::balance::Balance<talus::us::US>,
    /// True when an on chain tool's execute function expects
    /// nexus_primitives::authorization::ProvenValue<nexus_interface::authorization::AgentVertexAuthorization> as its first argument.
    workflow_authorization_cap_first: bool,
    /// Collateral lock duration in milliseconds after unregistration.
    lock_duration_ms: u64,
    /// Timestamp when the Tool was registered.
    registered_at_ms: u64,
    /// Unregistration timestamp, used to enforce the lock before the creator can reclaim collateral.
    unregistered_at_ms: std::option::Option<u64>,
}

/// Authority over policy, verification, and collateral in one [`ToolRegistry`].
public struct ToolRegistryAdminCap has key, store {
    id: sui::object::UID,
    registry: sui::object::ID,
}

/// Emitted when a new [ToolRegistry] is created.
public struct ToolRegistryCreatedEvent has copy, drop {
    registry: sui::object::ID,
}

/// Emitted when a tool is registered or re registered.
public struct ToolRegisteredEvent has copy, drop {
    tool: sui::object::ID,
    fqn: std::ascii::String,
}

/// Emitted when a tool is unregistered.
public struct ToolUnregisteredEvent has copy, drop {
    tool: sui::object::ID,
    fqn: std::ascii::String,
}

/// Emitted when a tool's collateral is slashed.
public struct ToolSlashedEvent has copy, drop {
    tool: sui::object::ID,
    fqn: std::ascii::String,
    /// Amount of US collateral in base units slashed.
    amount: u64,
}

/// Emitted when a tool's verification status changes.
public struct ToolVerificationStatusChangedEvent has copy, drop {
    tool: sui::object::ID,
    fqn: std::ascii::String,
    verified: bool,
}

/// Emitted when a tool's metadata, URL, timeout, or verifier methods are updated.
public struct ToolUpdatedEvent has copy, drop {
    tool: sui::object::ID,
    fqn: std::ascii::String,
}

/// Emitted when a Tool external verifier is registered.
public struct ExternalVerifierRegisteredEvent has copy, drop {
    registry: sui::object::ID,
    tool: sui::object::ID,
    method: nexus_interface::verifier::VerifierMethodId,
    witness: sui::object::ID,
}

/// Registers a new off chain HTTP Tool with an immutable schema and invocation price.
/// The registry enforces FQN uniqueness, schema validity, and timeout bounds; URL and FQN conventions remain caller/SDK responsibilities.
///
/// # Collateral
///
/// To prevent spamming, we lock [ToolRegistry.us_collateral_to_lock]
/// [US] as collateral.
/// If the tool is unregistered, the collateral is available after
/// [ToolRegistry.lock_duration_ms] milliseconds.
///
/// # Slashing
///
/// The registry administrator may call [`slash_off_chain_tool`] when the Tool
/// fails to uphold its registered contract.
///
/// # Owner Cap
///
/// The returned Tool owner capability must be transferred or otherwise consumed.
///
/// # Payment Tickets
///
/// The returned payment capability controls invocation price and tickets.
public native fun register_off_chain_tool(
    self: &mut ToolRegistry,
    fqn: std::ascii::String,
    url: vector<u8>,
    description: vector<u8>,
    meta_schema: nexus_interface::meta_schema::MetaSchema,
    timeout_ms: u64,
    invocation_cost_mist: u64,
    pay_with: &mut sui::coin::Coin<talus::us::US>,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): (
    Tool,
    nexus_primitives::owner_cap::CloneableOwnerCap<nexus_tool::tool_authority::OverTool>,
    nexus_primitives::owner_cap::CloneableOwnerCap<nexus_tool::tool_cashier::OverToolCashier>,
);

/// Registers a new on chain Tool with an immutable schema and invocation price.
///
/// Onchain Tools are published as separate Move modules. They must expose a
/// public `execute` function that consumes [`UIDRequirements`] followed by an
/// owned `OnchainToolResult`. Workflow Tools may precede those arguments with
/// an owned `ProvenValue<AgentVertexAuthorization>`. Public visibility lets the
/// current Scheduler compose an older Tool package in one transaction. The
/// Tool must satisfy its UID requirement and finalize the result in that same
/// transaction.
///
/// # Owner Cap
///
/// The returned Tool owner capability must be transferred or otherwise consumed.
public native fun register_on_chain_tool(
    self: &mut ToolRegistry,
    package_address: address,
    module_name: std::ascii::String,
    fqn: std::ascii::String,
    description: vector<u8>,
    meta_schema: nexus_interface::meta_schema::MetaSchema,
    timeout_ms: u64,
    tool_witness_id: sui::object::ID,
    invocation_cost_mist: u64,
    pay_with: &mut sui::coin::Coin<talus::us::US>,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): (
    Tool,
    nexus_primitives::owner_cap::CloneableOwnerCap<nexus_tool::tool_authority::OverTool>,
    nexus_primitives::owner_cap::CloneableOwnerCap<nexus_tool::tool_cashier::OverToolCashier>,
);

/// Registers an on chain Tool whose `execute` function requires a vertex authorization value first.
///
/// The caller/SDK must set this only after normalized signature analysis proves
/// execute takes `nexus_primitives::authorization::ProvenValue<nexus_interface::authorization::AgentVertexAuthorization>` first.
public native fun register_on_chain_tool_with_workflow_authorization_cap(
    self: &mut ToolRegistry,
    package_address: address,
    module_name: std::ascii::String,
    fqn: std::ascii::String,
    description: vector<u8>,
    meta_schema: nexus_interface::meta_schema::MetaSchema,
    timeout_ms: u64,
    tool_witness_id: sui::object::ID,
    invocation_cost_mist: u64,
    pay_with: &mut sui::coin::Coin<talus::us::US>,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): (
    Tool,
    nexus_primitives::owner_cap::CloneableOwnerCap<nexus_tool::tool_authority::OverTool>,
    nexus_primitives::owner_cap::CloneableOwnerCap<nexus_tool::tool_cashier::OverToolCashier>,
);

/// Atomically retires a Tool from every live registry lookup and verifier record.
public native fun unregister(
    self: &mut Tool,
    registry: &mut ToolRegistry,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    clock: &sui::clock::Clock,
);

/// Registers a previously unregistered [`Tool`] again.
///
/// Rebuilds base registry state with the current collateral and lock policy,
/// a fresh timeout, and no verifier support.
public native fun reregister_tool(
    self: &mut Tool,
    registry: &mut ToolRegistry,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    pay_with: &mut sui::coin::Coin<talus::us::US>,
    timeout_ms: u64,
);

/// Return collateral to a tool owner.
public native fun claim_collateral(
    self: &mut Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    clock: &sui::clock::Clock,
): sui::balance::Balance<talus::us::US>;

/// Returns a new [CloneableOwnerCap] for the given tool but with the given
/// generic type that doesn't have any permissions within this module.
/// Works for both off chain and on chain Tools.
///
/// See also [assert_tool_owner_generic].
public native fun deescalate<T: drop>(
    self: &Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    witness: T,
    ctx: &mut sui::tx_context::TxContext,
): nexus_primitives::owner_cap::CloneableOwnerCap<T>;

/// Creates delegated cashier administration from full [`Tool`] ownership.
public native fun delegate_cashier_admin(
    self: &Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    ctx: &mut sui::tx_context::TxContext,
): nexus_primitives::owner_cap::CloneableOwnerCap<nexus_tool::tool_cashier::OverToolCashier>;

/// Assert that the owner cap is for the given tool but allows any generic
/// type to be used.
///
/// See also [deescalate].
public native fun assert_tool_owner_generic<T>(
    self: &Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<T>,
);

/// Returns whether the collateral lock duration has elapsed since the tool was unregistered.
///
/// Returns `false` if the tool is still registered.
public native fun did_unregister_period_pass(self: &Tool, clock: &sui::clock::Clock): bool;

/// Returns whether the tool is currently registered (not unregistered).
public native fun is_registered(self: &Tool): bool;

/// Returns whether the tool has been marked verified by the slashing authority.
public native fun is_verified(self: &Tool): bool;

/// Assert that a tool is registered and not unregistered.
public native fun assert_tool_registered(self: &Tool);

/// Returns the fully qualified name of the tool.
public native fun fqn(self: &Tool): std::ascii::String;

/// Asserts a DAG vertex is bound to this registry's exact Tool ID and immutable schema.
public native fun assert_registered_vertex(
    self: &ToolRegistry,
    dag_object: &nexus_interface::dag::DAG,
    vertex: nexus_interface::graph::Vertex,
);

/// Asserts every DAG vertex still matches this registry's live Tool state.
public native fun assert_registered_dag(
    self: &ToolRegistry,
    dag_object: &nexus_interface::dag::DAG,
);

/// Returns the configured timeout (in milliseconds) for the tool with the given FQN.
public native fun tool_timeout_ms(self: &ToolRegistry, fqn: std::ascii::String): u64;

/// Build the timeout window for a runtime DAG vertex.
public native fun walk_timeout_ms_for_runtime_vertex(
    self: &ToolRegistry,
    dag_object: &nexus_interface::dag::DAG,
    vertex: nexus_interface::graph::RuntimeVertex,
): u64;

/// Return whether a tool FQN is registered in this registry.
public native fun contains_tool(self: &ToolRegistry, fqn: std::ascii::String): bool;

public native fun contains_tool_id(self: &ToolRegistry, tool_id: sui::object::ID): bool;

public native fun tool_id(self: &ToolRegistry, fqn: std::ascii::String): sui::object::ID;

/// Returns the current invocation price in MIST for a registered Tool.
public native fun invocation_cost_mist(self: &ToolRegistry, fqn: std::ascii::String): u64;

/// Records the current Tool price on an execution payment.
///
/// An unregistered Tool is snapshotted with a zero price so callers can
/// preserve a complete execution snapshot before liveness is checked.
public native fun snapshot_invocation_cost(
    self: &ToolRegistry,
    execution_payment: &mut nexus_interface::payment::ExecutionPayment,
    fqn: std::ascii::String,
);

/// Sets the invocation price in MIST using delegated [`OverToolCashier`] authority.
public native fun set_invocation_cost_mist(
    self: &mut ToolRegistry,
    tool: &Tool,
    cashier_admin: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_cashier::OverToolCashier,
    >,
    cost: u64,
);

public native fun verifier_support(
    self: &ToolRegistry,
    tool_id: sui::object::ID,
): std::option::Option<nexus_interface::verifier::ToolVerifierSupport>;

public native fun supports_verifier_mode(
    self: &ToolRegistry,
    tool_id: sui::object::ID,
    mode: nexus_interface::verifier::ToolVerifierMode,
): bool;

/// Adds a DAG vertex bound to this registry's current stable Tool ID and immutable schema.
public native fun add_vertex_to_dag(
    self: &ToolRegistry,
    dag_object: &mut nexus_interface::dag::DAG,
    dag_owner: &mut nexus_primitives::owner_cap::CloneableOwnerCap<nexus_interface::dag::OverDAG>,
    vertex: nexus_interface::graph::Vertex,
    kind: nexus_interface::graph::VertexKind,
);

/// Selects a per vertex mode after checking the Tool's one global support value.
public native fun set_registered_vertex_verifier_mode(
    self: &ToolRegistry,
    dag_object: &mut nexus_interface::dag::DAG,
    dag_owner: &mut nexus_primitives::owner_cap::CloneableOwnerCap<nexus_interface::dag::OverDAG>,
    vertex: nexus_interface::graph::Vertex,
    mode: nexus_interface::verifier::ToolVerifierMode,
);

/// Owner authorized initial registration of one External verifier.
public native fun register_external_verifier(
    self: &mut ToolRegistry,
    tool: &Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    registration: nexus_tool::external_verifier::ExternalVerifierRegistration,
);

/// Returns whether a Tool has external verifier configuration.
public native fun has_external_verifier(self: &ToolRegistry, tool: sui::object::ID): bool;

/// Returns the external verifier method configured for a Tool.
public native fun external_verifier_method(
    self: &ToolRegistry,
    tool: sui::object::ID,
): nexus_interface::verifier::VerifierMethodId;

/// Returns the witness configured for a Tool external verifier.
public native fun external_verifier_witness(
    self: &ToolRegistry,
    tool: sui::object::ID,
): sui::object::ID;

/// Returns the immutable shared objects configured for a Tool external verifier.
public native fun external_verifier_objects(
    self: &ToolRegistry,
    tool: sui::object::ID,
): vector<sui::object::ID>;

/// Return whether the registered on chain tool requires workflow authorization
/// cap as its first execute argument.
public native fun on_chain_tool_takes_workflow_authorization_cap_first(
    self: &ToolRegistry,
    fqn: std::ascii::String,
): bool;

/// Return whether a DAG runtime vertex requires a workflow authorization grant for execution.
public native fun vertex_requires_authorization_grant(
    self: &ToolRegistry,
    dag_object: &nexus_interface::dag::DAG,
    vertex: nexus_interface::graph::RuntimeVertex,
): bool;

/// Assert that `witness_id` is the witness registered for an on chain tool.
public native fun assert_on_chain_tool_witness(
    self: &ToolRegistry,
    fqn: std::ascii::String,
    witness_id: sui::object::ID,
);

public native fun on_chain_tool_witness_id(
    self: &ToolRegistry,
    fqn: std::ascii::String,
): sui::object::ID;

/// Sets the collateral in US base units required to register a Tool.
public native fun set_us_collateral_to_lock(
    self: &mut ToolRegistry,
    admin: &ToolRegistryAdminCap,
    new_us_collateral_to_lock: u64,
);

/// Sets the collateral lock duration in milliseconds after Tool removal.
public native fun set_lock_duration_ms(
    self: &mut ToolRegistry,
    admin: &ToolRegistryAdminCap,
    new_duration_ms: u64,
);

/// Takes the given amount of collateral from a [`Tool`].
///
/// If the remaining vault is below the requirement configured by
/// [`set_us_collateral_to_lock`], an active [`Tool`] is retired. A retired
/// [`Tool`] keeps its original retirement time.
public native fun slash(
    self: &mut Tool,
    registry: &mut ToolRegistry,
    admin: &ToolRegistryAdminCap,
    amount: u64,
    clock: &sui::clock::Clock,
): sui::balance::Balance<talus::us::US>;

/// Set a tool's verification status.
public native fun set_verified(
    self: &mut Tool,
    registry: &ToolRegistry,
    admin: &ToolRegistryAdminCap,
    verified: bool,
);

/// Update the URL of an off chain (HTTP) tool.
///
/// The tool must be registered and the caller must hold the owner cap.
public native fun update_off_chain_tool_url(
    self: &mut Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    new_url: vector<u8>,
);

/// Updates the package address of an active on chain Tool using its bound owner capability.
public native fun migrate_on_chain_tool_package(
    self: &mut Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    target_package: address,
);

/// Updates the mutable description of a registered Tool.
///
/// The registration time [`MetaSchema`] remains immutable because DAG bindings and the registry
/// snapshot rely on that exact schema. Description changes require renewed verification.
public native fun update_tool_metadata(
    self: &mut Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    description: vector<u8>,
);

/// Update a tool timeout.
///
/// The tool must be registered and the caller must hold the owner cap.
public native fun update_tool_timeout(
    self: &Tool,
    registry: &mut ToolRegistry,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
    timeout_ms: u64,
);

/// Declares registered key verifier support for a Tool.
///
/// Verification still requires live Tool and Leader key bindings.
public native fun configure_registered_key_support(
    registry: &mut ToolRegistry,
    tool: &Tool,
    owner_cap: &mut nexus_primitives::owner_cap::CloneableOwnerCap<
        nexus_tool::tool_authority::OverTool,
    >,
);
