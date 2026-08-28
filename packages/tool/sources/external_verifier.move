module nexus_tool::external_verifier;

//! Interface for [`nexus_tool::external_verifier`].
//!
//! Calls resolve to the published package.

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
public native fun new<W: key>(
    tool: sui::object::ID,
    package: sui::object::ID,
    module_name: std::ascii::String,
    function_name: std::ascii::String,
    witness: &W,
): ExternalVerifierRegistration;

/// Appends an immutable shared object argument to this registration.
public native fun add_object<T: key>(self: &mut ExternalVerifierRegistration, object: &T);

/// Returns the configured verifier method.
public native fun method(self: &ExternalVerifier): nexus_interface::verifier::VerifierMethodId;

/// Returns the verifier witness object ID.
public native fun witness(self: &ExternalVerifier): sui::object::ID;

/// Returns the ordered immutable shared object arguments.
public native fun immutable_shared_objects(self: &ExternalVerifier): vector<sui::object::ID>;
