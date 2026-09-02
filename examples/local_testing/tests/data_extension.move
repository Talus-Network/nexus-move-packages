#[test_only]
extend module nexus_primitives::data;

/// Creates an inline [NexusValue] wrapped in one [NexusData] value.
///
/// This helper constructs the value directly because [inline_data_value] and
/// [one] represent published Nexus behavior and abort during local execution.
public fun inline_for_testing(bytes: vector<u8>): NexusData {
    NexusData::One {
        value: NexusValue::InlineData { bytes },
    }
}

/// Returns the byte length of an inline [NexusValue] wrapped in one
/// [NexusData] value.
///
/// Returns zero for every other [NexusData] shape.
public fun inline_length_for_testing(self: &NexusData): u64 {
    match (self) {
        NexusData::One {
            value: NexusValue::InlineData { bytes },
        } => bytes.length(),
        _ => 0,
    }
}
