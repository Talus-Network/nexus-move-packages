#[test_only]
extend module nexus_tool::era;

/// Constructs the Tool storage witness used by local deployment state.
public fun v1_for_testing(): V1 {
    V1()
}
