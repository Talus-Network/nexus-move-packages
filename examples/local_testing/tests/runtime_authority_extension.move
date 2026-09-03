#[test_only]
extend module nexus_kernel::runtime_authority;

/// Creates an empty authority root for local scheduling tests.
///
/// Scheduling only reads the work admission marker. Testnet uses the shared
/// authority from the active Nexus deployment.
public fun new_for_testing(ctx: &mut TxContext): RuntimeAuthority {
    RuntimeAuthority {
        id: object::new(ctx),
        scheduler_upgrade_cap: option::none(),
        current_runtime: option::none(),
        current_runtime_package: option::none(),
        paused: false,
    }
}
