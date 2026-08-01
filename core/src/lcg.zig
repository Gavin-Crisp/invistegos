const config = @import("config");
const core = @import("root.zig");
const std = @import("std");

pub const Index = core.Index;
pub const PhysicalIndex = core.PhysicalIndex;
pub const ShuffledIndex = core.ShuffledIndex;
pub const cluster_size = config.lcg_cluster_size;

pub const ClusterIndex = Index;

pub fn shuffleCluster(index: ClusterIndex, clusters: u64) ClusterIndex {
    var result = (index *% config.lcg_mult +% config.lcg_incr) % clusters;
    for (0..config.lcg_iterations) |_| result = shuffleCluster(result, clusters);

    return result;
}

pub fn indexCluster(index: Index) u64 {
    return index / cluster_size;
}

pub fn indexOffset(index: Index) u64 {
    return index % cluster_size;
}

pub fn clusterBeginning(index: ClusterIndex) Index {
    return index * cluster_size;
}

pub fn spanClusters(index: Index, span_len: u64) u64 {
    const first_cluster: ClusterIndex = index / cluster_size;
    const last_cluster: ClusterIndex = (index + span_len - 1) / cluster_size;

    return last_cluster - first_cluster + 1;
}

pub fn map(index: ShuffledIndex, sectors: u64) PhysicalIndex {
    std.debug.assert(index < sectors);

    const cluster: ClusterIndex = indexCluster(index);
    const offset = indexOffset(index);
    const clusters = (sectors / cluster_size) + 1;

    return shuffleCluster(cluster, clusters) + offset;
}

test map {
    const sample_sectors = 1024 * 1024;
    const sample_offset =  0;
    const device_size = 100 * 2 * 1024 * 1024;

    const expected_gap: f128 = device_size / @as(f128, @floatFromInt(sample_sectors + 1));
    const average_gap = init: {
        var gap: f128 = 0;
        var indices: [sample_sectors]u64 = undefined;

        for (0..indices.len) |i| indices[i] = map(i + sample_offset, device_size);
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

