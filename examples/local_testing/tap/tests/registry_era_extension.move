#[test_only]
extend module nexus_registry::era;

/// Constructs the Registry storage witness used by local deployment state.
public fun v1_for_testing(): V1 {
    V1()
}
