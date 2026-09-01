/// Interface for the published [`nexus_primitives::proof_of_uid`] module.
///
/// Function calls resolve to the published package during network execution.
/// The local bodies in this repository abort with
/// [`ELocalExecutionUnavailable`]. This lets Move tests load the module and
/// add extensions without reproducing published Nexus behavior.
#[allow(unused_variable, unused_type_parameter)]
module nexus_primitives::proof_of_uid;

/// Abort reason used when a local test invokes published Nexus behavior.
#[error]
const ELocalExecutionUnavailable: vector<u8> =
    b"Nexus functions require the published Testnet or Mainnet package";

/// Hot potato that can collect stamps.
///
/// If [ProofOfUID] contains an [ID] stamp it means that the corresponding [UID]
/// has been referenced in [stamp] method.
public struct ProofOfUID {
    /// Only the [UID] that created this proof in [new] can consume it or
    /// convert it through [into_requirements].
    from_uid: sui::object::ID,
    /// Optionally, the creator of the proof can also prove the type of the [UID].
    ///
    /// Some nexus components may require this information to be present.
    from_type: std::option::Option<std::type_name::TypeName>,
    /// Stampers can attach arbitrary data to their stamp.
    stamps: sui::vec_map::VecMap<sui::object::ID, vector<u8>>,
}

/// A [ProofOfUID] that can be completed after every required [UID] participates.
///
/// Requirements are removed only by presenting the matching [UID]. Once no
/// requirements remain, any caller can [complete] the value. The wrapped proof
/// stays available for read only authorization checks during this process.
public struct UIDRequirements {
    proof: ProofOfUID,
    remaining: sui::vec_set::VecSet<sui::object::ID>,
}

/// Creates an empty proof bound to the given UID.
public fun new(uid: &sui::object::UID): ProofOfUID {
    abort ELocalExecutionUnavailable
}

/// Creates an empty proof bound to the given UID and recording the object's type.
/// Aborts if the UID does not match the object's ID.
public fun new_with_type<T: key>(uid: &sui::object::UID, o: &T): ProofOfUID {
    abort ELocalExecutionUnavailable
}

/// Consumes the proof and returns its stamps.
/// Aborts unless the given UID is the one that created the proof.
public fun consume(
    self: ProofOfUID,
    uid: &sui::object::UID,
): sui::vec_map::VecMap<sui::object::ID, vector<u8>> {
    abort ELocalExecutionUnavailable
}

/// Add a stamp to the proof with some data.
public fun stamp_with_data(self: &mut ProofOfUID, uid: &sui::object::UID, data: vector<u8>) {
    abort ELocalExecutionUnavailable
}

/// Add a stamp to the proof.
public fun stamp(self: &mut ProofOfUID, uid: &sui::object::UID) {
    abort ELocalExecutionUnavailable
}

/// Removes the stamp for the given UID.
/// Aborts if no such stamp exists.
public fun unstamp(self: &mut ProofOfUID, uid: &sui::object::UID) {
    abort ELocalExecutionUnavailable
}

/// Borrows the map of stamps keyed by stamper ID.
public fun stamps(self: &ProofOfUID): &sui::vec_map::VecMap<sui::object::ID, vector<u8>> {
    abort ELocalExecutionUnavailable
}

/// The number of stamps on the proof.
public fun stamps_len(self: &ProofOfUID): u64 {
    abort ELocalExecutionUnavailable
}

/// Whether the proof carries a stamp for the given ID.
public fun has_stamp(self: &ProofOfUID, of_uid: sui::object::ID): bool {
    abort ELocalExecutionUnavailable
}

/// Whether the proof carries a stamp for the given ID with exactly the given data.
public fun has_stamp_with_data(
    self: &ProofOfUID,
    of_uid: sui::object::ID,
    data: &vector<u8>,
): bool {
    abort ELocalExecutionUnavailable
}

/// Returns the data attached to the given ID's stamp, or none if absent.
public fun read_stamp_data_of_id(
    self: &ProofOfUID,
    of_uid: sui::object::ID,
): std::option::Option<vector<u8>> {
    abort ELocalExecutionUnavailable
}

/// The ID of the UID that created the proof.
public fun created_from(self: &ProofOfUID): sui::object::ID {
    abort ELocalExecutionUnavailable
}

/// The recorded type of the creating object, if it was provided at construction.
public fun type_name(self: &ProofOfUID): std::option::Option<std::type_name::TypeName> {
    abort ELocalExecutionUnavailable
}

/// Converts this proof into requirements authorized by its creating [UID].
///
/// Each ID in `remaining` must later be removed through [satisfy]. The
/// conversion is one way and the proof can only be recovered through
/// [complete].
public fun into_requirements(
    self: ProofOfUID,
    uid: &sui::object::UID,
    remaining: sui::vec_set::VecSet<sui::object::ID>,
): UIDRequirements {
    abort ELocalExecutionUnavailable
}

/// Removes the requirement for the given [UID].
///
/// Records an empty stamp when the UID is required. Does nothing if the UID is
/// not required or has already participated.
public fun satisfy(self: &mut UIDRequirements, uid: &sui::object::UID) {
    abort ELocalExecutionUnavailable
}

/// Borrows the wrapped [ProofOfUID] for authorization checks.
public fun proof(self: &UIDRequirements): &ProofOfUID {
    abort ELocalExecutionUnavailable
}

/// Completes the requirements and returns the stamps collected before conversion.
///
/// Aborts while any required [UID] has not participated.
public fun complete(self: UIDRequirements): sui::vec_map::VecMap<sui::object::ID, vector<u8>> {
    abort ELocalExecutionUnavailable
}
