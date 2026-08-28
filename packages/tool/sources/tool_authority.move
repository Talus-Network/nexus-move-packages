module nexus_tool::tool_authority;

//! Interface for [`nexus_tool::tool_authority`].
//!
//! Calls resolve to the published package.

/// Capability role that grants full ownership of one Tool.
public struct OverTool has drop {}
