const config = @import("config");
const core = @import("root.zig");
const std = @import("std");

pub fn lcg(seed: u64, limit: u64) u64 {
    return (seed *% config.lcg_mult +% config.lcg_incr) % limit;
}

/// 
pub fn lcg_map(index: core.ShuffledIndex, limit: u64) core.PhysicalIndex {
    std.debug.assert(index < limit);
    
    var ret = lcg(index, limit);

    for (0..config.lcg_iterations) |_| ret = lcg(ret, limit);

    return ret;
}

test lcg_map {
    const sample_sectors = 2 * 1024 * 1024;
    const sample_offset =  0;
    const device_size = 100 * 2 * 1024 * 1024;

    const expected_gap: f128 = device_size / @as(f128, @floatFromInt(sample_sectors + 1));
    const average_gap = init: {
        var gap: f128 = 0;
        var indices: [sample_sectors]u64 = undefined;

        for (0..indices.len) |i| indices[i] = lcg_map(i + sample_offset, device_size);
        std.mem.sort(u64, &indices, {}, std.sort.asc(u64));

        var pairs = std.mem.window(u64, &indices, 2, 1);
        while (pairs.next()) |pair| gap += @floatFromInt(pair[1] - pair[0]);

        break :init gap / (sample_sectors - 1);
    };
    const uniformity = if (average_gap > expected_gap) blk: {
        break :blk expected_gap / average_gap;
    } else blk: {
        break :blk average_gap / expected_gap;
    } * 100;

    try std.testing.expect(uniformity >= 99);
}
