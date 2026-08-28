module nexus_primitives::shared_object;

//! Interface for [`nexus_primitives::shared_object`].
//!
//! Calls resolve to the published package.

/// Describes how a shared object is passed to an interface Move call.
public struct SharedObjectRef has copy, drop, store {
    /// The ID of the shared object.
    id: sui::object::ID,
    /// Whether the object is passed by mutable reference.
    ref_mut: bool,
}

/// Helper to create `SharedObjectRef` with immutable reference.
public native fun shared_object_ref_imm(id: sui::object::ID): SharedObjectRef;

/// Helper to create `SharedObjectRef` with mutable reference.
public native fun shared_object_ref_mut(id: sui::object::ID): SharedObjectRef;

/// The ID of the referenced shared object.
public native fun shared_object_id(self: &SharedObjectRef): sui::object::ID;

/// Whether the shared object is passed by mutable reference.
public native fun shared_object_ref_mutable(self: &SharedObjectRef): bool;
