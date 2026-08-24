const core = @import("core");
const linux = @import("../linux.zig");
const lcg = core.lcg;

const Self = @This();

workqueue: *opaque {},

pub fn init(self: *Self) void {
    _ = self;
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn readGroup(self: Self, group: opaque {}) void {
    _ = self;
    _ = group;
}

pub fn writeGroup(self: Self, group: opaque {}) void {
    _ = self;
    _ = group;
}

fn createRequestBios(index: lcg.ShuffledIndex, sectors: u64) !*linux.Bio {
    const index_int = @intFromEnum(index);
    const first_cluster_size = lcg.cluster_size - lcg.indexOffset(index_int);
    const root_bio = try createDeshuffledBio(index_int, first_cluster_size);

    var last_bio = root_bio;
    var span_start = index_int + first_cluster_size;
    var span_size = sectors - first_cluster_size;
    while (span_size > 0) {
        const size = @min(span_size, lcg.cluster_size);
        const new_bio = try createDeshuffledBio(span_start, size);

        linux.bioChain(new_bio, last_bio);
        last_bio = new_bio;
        span_start += size;
        span_size -= size;
    }

    return root_bio;
}

fn createDeshuffledBio(bdev: *linux.BlockDevice, start: u64, size: u64) !*linux.Bio {
    // TODO: calculate optimal sectors per page.
    const sectors_per_page = 2048; // 1MiB per page
    const page_count = (size + sectors_per_page - 1) / sectors_per_page;
    const physical_index = lcg.map(start, linux.blockDeviceNrSectors(bdev));
    // FIXME: Flags
    const bio = linux.bioAlloc(bdev, page_count, 0, 0) orelse return error.OOM;
    bio.iter.sector = physical_index;

    var remaining_sectors = size;
    while (remaining_sectors > 0) {
        const new_page_sectors = @min(sectors_per_page, remaining_sectors);
        // FIXME: Flags
        const page: *linux.Page = linux.allocPage(0);

        linux.bioAddPage(bio, page, new_page_sectors, 0);
        remaining_sectors -= new_page_sectors;
    }

    return bio;
}

