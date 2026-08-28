module nexus_primitives::proof_of_uid;

//! Interface for [`nexus_primitives::proof_of_uid`].
//!
//! Calls resolve to the published package.

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
public native fun new(uid: &sui::object::UID): ProofOfUID;

/// Creates an empty proof bound to the given UID and recording the object's type.
/// Aborts if the UID does not match the object's ID.
public native fun new_with_type<T: key>(uid: &sui::object::UID, o: &T): ProofOfUID;

/// Consumes the proof and returns its stamps.
/// Aborts unless the given UID is the one that created the proof.
public native fun consume(
    self: ProofOfUID,
    uid: &sui::object::UID,
): sui::vec_map::VecMap<sui::object::ID, vector<u8>>;

/// Add a stamp to the proof with some data.
public native fun stamp_with_data(self: &mut ProofOfUID, uid: &sui::object::UID, data: vector<u8>);

/// Add a stamp to the proof.
public native fun stamp(self: &mut ProofOfUID, uid: &sui::object::UID);

/// Removes the stamp for the given UID.
/// Aborts if no such stamp exists.
public native fun unstamp(self: &mut ProofOfUID, uid: &sui::object::UID);

/// Borrows the map of stamps keyed by stamper ID.
public native fun stamps(self: &ProofOfUID): &sui::vec_map::VecMap<sui::object::ID, vector<u8>>;

/// The number of stamps on the proof.
public native fun stamps_len(self: &ProofOfUID): u64;

/// Whether the proof carries a stamp for the given ID.
public native fun has_stamp(self: &ProofOfUID, of_uid: sui::object::ID): bool;

/// Whether the proof carries a stamp for the given ID with exactly the given data.
public native fun has_stamp_with_data(
    self: &ProofOfUID,
    of_uid: sui::object::ID,
    data: &vector<u8>,
): bool;

/// Returns the data attached to the given ID's stamp, or none if absent.
public native fun read_stamp_data_of_id(
    self: &ProofOfUID,
    of_uid: sui::object::ID,
): std::option::Option<vector<u8>>;

/// The ID of the UID that created the proof.
public native fun created_from(self: &ProofOfUID): sui::object::ID;

/// The recorded type of the creating object, if it was provided at construction.
public native fun type_name(self: &ProofOfUID): std::option::Option<std::type_name::TypeName>;

/// Converts this proof into requirements authorized by its creating [UID].
///
/// Each ID in `remaining` must later be removed through [satisfy]. The
/// conversion is one way and the proof can only be recovered through
/// [complete].
public native fun into_requirements(
    self: ProofOfUID,
    uid: &sui::object::UID,
    remaining: sui::vec_set::VecSet<sui::object::ID>,
): UIDRequirements;

/// Removes the requirement for the given [UID].
///
/// Records an empty stamp when the UID is required. Does nothing if the UID is
/// not required or has already participated.
public native fun satisfy(self: &mut UIDRequirements, uid: &sui::object::UID);

/// Borrows the wrapped [ProofOfUID] for authorization checks.
public native fun proof(self: &UIDRequirements): &ProofOfUID;

/// Completes the requirements and returns the stamps collected before conversion.
///
/// Aborts while any required [UID] has not participated.
public native fun complete(
    self: UIDRequirements,
): sui::vec_map::VecMap<sui::object::ID, vector<u8>>;
