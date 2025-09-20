pub const mult = 80285479;
pub const incr = 33276689;

pub fn lcg(comptime T: type, seed: T) T {
    return mult *% seed +% incr;
}

pub fn lcg_map(comptime T: type, index: T, limit: T) T {
    if (index >= limit)
        return index;

    // Applied thrice at a minimum because lcg is not especially random
    var ret = lcg(T, lcg(T, lcg(T, index)));

    while (ret >= limit) {
        ret = lcg(T, ret);
    }

    return ret;
}

test "LCG" {
    const std = @import("std");
    const print = std.debug.print;

    print("Mapping sectors 0..10 of 50GiB device with lcp_map32\n\n", .{});
    for (0..10) |index| {
        print("{}\n", .{lcg_map(u32, @intCast(index), 2 * 1024 * 1024 * 50)});
    }

    print("\nMapping sectors 100..110 of 2TiB device with lcp_map36\n\n", .{});
    for (100..110) |index| {
        print("{}\n", .{lcg_map(u36, @intCast(index), 2 * 1024 * 1024 * 1024 * 2)});
    }
}
