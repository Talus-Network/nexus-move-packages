/// Interface for the published [`nexus_tool::external_verifier`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_tool::external_verifier;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Concrete external call target and its ordered immutable shared object IDs.
public struct ExternalVerifier has copy, drop, store {
    method: nexus_interface::verifier::VerifierMethodId,
    witness: sui::object::ID,
    immutable_shared_objects: vector<sui::object::ID>,
}

/// Builder consumed when an external verifier is registered for a Tool.
public struct ExternalVerifierRegistration {
    method: nexus_interface::verifier::VerifierMethodId,
    witness: sui::object::ID,
    immutable_shared_objects: vector<sui::object::ID>,
}

/// Creates a registration with [`witness`] as immutable object zero.
public fun new<W: key>(
    tool: sui::object::ID,
    package: sui::object::ID,
    module_name: std::ascii::String,
    function_name: std::ascii::String,
    witness: &W,
): ExternalVerifierRegistration {
    abort ELocalExecutionUnavailable
}

/// Appends an immutable shared object argument to this registration.
public fun add_object<T: key>(self: &mut ExternalVerifierRegistration, object: &T) {
    abort ELocalExecutionUnavailable
}

/// Returns the configured verifier method.
public fun method(self: &ExternalVerifier): nexus_interface::verifier::VerifierMethodId {
    abort ELocalExecutionUnavailable
}

/// Returns the verifier witness object ID.
public fun witness(self: &ExternalVerifier): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// Returns the ordered immutable shared object arguments.
public fun immutable_shared_objects(self: &ExternalVerifier): vector<sui::object::ID> {
    abort ELocalExecutionUnavailable
}
