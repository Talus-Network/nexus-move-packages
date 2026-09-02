#[test_only]
extend module nexus_primitives::tagged_output;

/// Returns one inline payload so application tests can make focused assertions.
public fun payload_inline_bytes_for_testing(
    self: &TaggedOutput,
    name: vector<u8>,
): vector<u8> {
    self.named_payload.get(&name).inline_data_bytes().destroy_some()
}
