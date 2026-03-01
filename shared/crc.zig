const config = @import("config");
const shared = @import("root.zig");

const EdcSector = shared.EdcSector;
const EccNode = shared.EccNode;
const CheckValue = shared.CheckValue;

const high_bit = 1 << (config.crc_bits - 1);
const remainder_init = @import("std").math.maxInt(CheckValue);

const crc_table = blk: {
    @setEvalBranchQuota(10000);
    var table: [256]CheckValue = undefined;

    for (0..table.len) |i| {
        var remainder = @as(CheckValue, i) << (config.crc_bits - 8);

        for (0..8) |_| {
            remainder =
                if (remainder & high_bit != 0)
                    (remainder << 1) ^ config.crc_generator
                else
                    remainder << 1;
        }

        table[i] = remainder;
    }

    break :blk table;
};

pub fn validate_sector(sector: EdcSector) ?EccNode {
    const new_check_value: CheckValue = generate_check_value(sector.ecc_node);

    if (sector.check_value == new_check_value) {
        return sector.ecc_node;
    } else {
        return null;
    }
}

pub fn sign_node(node: EccNode) EdcSector {
    return EdcSector{ .ecc_node = node, .check_value = generate_check_value(node) };
}

fn generate_check_value(node: EccNode) CheckValue {
    const node_bytes = @import("std").mem.asBytes(&node);

    var remainder: CheckValue = remainder_init;

    for (node_bytes) |byte| {
        const table_index: u8 = byte ^ @as(u8, @intCast(remainder >> (config.crc_bits - 8)));
        remainder = (remainder << 8) ^ crc_table[table_index];
    }

    return remainder;
}

test crc_table {
    const expectEqual = @import("std").testing.expectEqual;

    try expectEqual(0, crc_table[0]);
    try expectEqual(config.crc_generator, crc_table[1]);
}
