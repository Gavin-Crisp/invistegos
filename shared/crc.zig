// TODO: account for endianess

const generator_polynomial: Crc = 37;
const crc_size_bytes = 2;

pub const Crc = @Type(.{ .int = .{ .bits = crc_size_bytes * 8, .signedness = .unsigned } });

const crc_bits = @typeInfo(Crc).int.bits;
const high_bit = 1 << (crc_bits - 1);
const remainder_init: Crc = @import("std").math.maxInt(Crc);

const crc_table = blk: {
    @setEvalBranchQuota(10000);
    var table: [256]Crc = undefined;

    for (0..table.len) |i| {
        table[i] = check_byte(i);
    }

    break :blk table;
};

fn check_byte(byte: u8) Crc {
    var remainder = @as(Crc, byte) << (crc_bits - 8);

    for (0..8) |_| {
        remainder =
            if (remainder & high_bit != 0)
                (remainder << 1) ^ generator_polynomial
            else
                remainder << 1;
    }

    return remainder;
}

pub fn check_message(message: []const u8) Crc {
    var remainder = remainder_init;

    for (message) |message_byte| {
        const table_index: u8 = message_byte ^ @as(u8, @truncate(remainder >> (crc_bits - 8)));
        remainder = (remainder << 8) ^ crc_table[table_index];
    }

    return remainder;
}

test crc_table {
    const expectEqual = @import("std").testing.expectEqual;

    try expectEqual(0, crc_table[0]);
    try expectEqual(generator_polynomial, crc_table[1]);
}

test check_message {
    const std = @import("std");

    const message = "lol. lmao, even.";
    const crc = check_message(message);
    const crc_bytes: [crc_size_bytes]u8 = @bitCast(crc);

    var appended: [message.len + crc_size_bytes]u8 = undefined;
    @memcpy(appended[0..message.len], message);
    for (0..crc_size_bytes) |i| {
        appended[message.len + i] = crc_bytes[crc_size_bytes - 1 - i];
    }

    const check_crc = check_message(&appended);

    try std.testing.expectEqual(0, check_crc);
}
