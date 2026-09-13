const config = @import("config");
const core = @import("root.zig");
const std = @import("std");

pub const PhysicalIndex = core.PhysicalIndex;
pub const PhysicalClusterIndex = core.PhysicalClusterIndex;
pub const ShuffledIndex = core.ShuffledIndex;
pub const ShuffledClusterIndex = core.ShuffledClusterIndex;
pub const cluster_size = config.lcg_cluster_size;

pub fn lcgCluster(index: ShuffledClusterIndex, clusters: u64) PhysicalClusterIndex {
    const index_int = @intFromEnum(index);

    var result = index_int;
    for (0..config.lcg_iterations) |_| {
        result = (index_int *% config.lcg_mult +% config.lcg_incr) % clusters;
    }

    return @enumFromInt(result);
}

pub fn map(index: ShuffledIndex, sectors: u64) PhysicalIndex {
    std.debug.assert(index.to() < sectors);

    const cluster = index.cluster();
    const offset = index.clusterOffset();
    const clusters = (sectors / cluster_size) + 1;

    const physical_cluster = lcgCluster(cluster, clusters);

    return .from(physical_cluster.to() + offset);
}

test map {
    const sample_sectors = 1024 * 1024;
    const sample_offset =  0;
    const device_size = 100 * 2 * 1024 * 1024;

    const expected_gap: f128 = device_size / @as(f128, @floatFromInt(sample_sectors + 1));
    const average_gap = init: {
        var gap: f128 = 0;
        var indices: [sample_sectors]u64 = undefined;

        for (0..indices.len) |i| {
            const index: ShuffledIndex = @enumFromInt(i + sample_offset);
            indices[i] = @intFromEnum(map(index, device_size));
        }
        std.mem.sort(u64, &indices, {}, std.sort.asc(u64));

        var pairs = std.mem.window(u64, &indices, 2, 1);
        while (pairs.next()) |pair| gap += @floatFromInt(pair[1] - pair[0]);

        break :init gap / (sample_sectors - 1);
    };
    const uniformity = 100 - if (average_gap > expected_gap) blk: {
        break :blk average_gap - expected_gap;
    } else blk: {
        break :blk expected_gap - average_gap;
    } / expected_gap * 100;

    _ = uniformity;
    // std.debug.print("Uniformity: {:.4}%", .{ uniformity });
}

