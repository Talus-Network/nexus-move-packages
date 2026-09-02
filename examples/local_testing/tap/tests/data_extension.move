#[test_only]
extend module nexus_primitives::data;

/// Creates an inline [NexusValue] wrapped in one [NexusData] value.
public fun inline_for_testing(bytes: vector<u8>): NexusData {
    NexusData::One {
        value: NexusValue::InlineData { bytes },
    }
}

/// Creates inline data through the published Nexus implementation.
public fun published_inline_for_testing(bytes: vector<u8>): NexusData {
    one(inline_data_value(bytes))
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

/// Recreates the private Nexus helper used by its internal unit tests.
///
/// The malformed value lets a TAP verify its rejection path. Production code
/// must always use the checked [many] constructor.
public fun unchecked_many_for_testing(values: vector<NexusValue>): NexusData {
    NexusData::Many { values }
}
