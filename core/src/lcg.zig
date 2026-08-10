const config = @import("config");
const core = @import("root.zig");
const std = @import("std");

pub const DeviceIndex = core.DeviceIndex;
pub const PhysicalIndex = core.PhysicalIndex;
pub const ShuffledIndex = core.ShuffledIndex;
pub const cluster_size = config.lcg_cluster_size;

pub const PhysicalClusterIndex = enum (u64) { _ };
pub const ShuffledClusterIndex = enum (u64) { _ };

pub fn shuffleCluster(index: ShuffledClusterIndex, clusters: u64) PhysicalClusterIndex {
    const index_int = @intFromEnum(index);

    var result = index_int;
    for (0..config.lcg_iterations) |_| {
        result = (index_int *% config.lcg_mult +% config.lcg_incr) % clusters;
    }

    return @enumFromInt(result);
}

pub fn indexCluster(index: u64) u64 {
    return index / cluster_size;
}

pub fn indexOffset(index: u64) u64 {
    return index % cluster_size;
}

pub fn clusterBeginning(index: u64) u64 {
    return index * cluster_size;
}

pub fn spanClusters(index: u64, span_len: u64) u64 {
    const first_cluster: u64 = indexCluster(index);
    const last_cluster: u64 = indexCluster(index + span_len - 1);

    return last_cluster - first_cluster + 1;
}

pub fn map(index: ShuffledIndex, sectors: u64) PhysicalIndex {
    const index_int = @intFromEnum(index);
    std.debug.assert(index_int < sectors);

    const cluster: ShuffledClusterIndex = @enumFromInt(indexCluster(index_int));
    const offset = indexOffset(index_int);
    const clusters = (sectors / cluster_size) + 1;

    const physical_cluster_int = @intFromEnum(shuffleCluster(cluster, clusters));

    return @enumFromInt(physical_cluster_int + offset);
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

