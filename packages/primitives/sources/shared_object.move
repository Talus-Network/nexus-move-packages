/// Interface for the published [`nexus_primitives::shared_object`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_primitives::shared_object;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Describes how a shared object is passed to an interface Move call.
public struct SharedObjectRef has copy, drop, store {
    /// The ID of the shared object.
    id: sui::object::ID,
    /// Whether the object is passed by mutable reference.
    ref_mut: bool,
}

/// Helper to create `SharedObjectRef` with immutable reference.
public fun shared_object_ref_imm(id: sui::object::ID): SharedObjectRef {
    abort ELocalExecutionUnavailable
}

/// Helper to create `SharedObjectRef` with mutable reference.
public fun shared_object_ref_mut(id: sui::object::ID): SharedObjectRef {
    abort ELocalExecutionUnavailable
}

/// The ID of the referenced shared object.
public fun shared_object_id(self: &SharedObjectRef): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Whether the shared object is passed by mutable reference.
public fun shared_object_ref_mutable(self: &SharedObjectRef): bool {
    abort ELocalExecutionUnavailable
}
