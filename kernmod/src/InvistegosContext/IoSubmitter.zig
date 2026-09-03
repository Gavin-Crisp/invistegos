const core = @import("core");
const linux = @import("../linux.zig");
const lcg = core.lcg;

const Self = @This();
// TODO: calculate with PAGE_SIZE
const sectors_per_page = 2048; // 512 bytes /sector * 2048 sectors = 1MiB per page

dev: *linux.DmDev,

pub fn init(self: *Self, dev: *linux.DmDev) void {
    self.dev = dev;
}

pub fn deinit(self: *Self, ti: *linux.DmTarget) void {
    linux.dmPutDevice(ti, self.dev);
}

pub fn read(self: Self, index: lcg.ShuffledIndex, out_buf: []core.Sector) void {
    _ = self;
    _ = index;
    _ = out_buf;
}

pub fn write(self: Self, index: lcg.ShuffledIndex, data: []core.Sector) !void {
    const bio = try createRequestBios(self.dev.bdev.?, index, data.len);
    bio.opf = @intFromEnum(linux.ReqOp.write);

    var next_bio: ?*linux.Bio = bio;
    var remaining_start = 0;
    while (next_bio) |current_bio| : (next_bio = current_bio.next) {
        for (0..current_bio.iter.size) |i_vec| {
            const io_vec = current_bio.io_vec.?[i_vec];
            const page_address = linux.pageAddress(io_vec.page.?);
            const remaining_end = @min(data.len, remaining_start + sectors_per_page);

            @memcpy(page_address, data[remaining_start..remaining_end]);
            remaining_start = remaining_end;
        }
    }

    linux.submitBio(bio);
}

pub fn sendFlush(self: Self) !void {
    const bio = linux.bioAlloc(self.dev.bdev.?, 1, @intFromEnum(linux.ReqOp.flush), 0) orelse return error.OOM;
    linux.submitBio(bio);
}

fn createRequestBios(bdev: *linux.BlockDevice, index: lcg.ShuffledIndex, sectors: u64) !*linux.Bio {
    const index_int = @intFromEnum(index);
    const first_cluster_size = lcg.cluster_size - lcg.indexOffset(index_int);
    const root_bio = try createDeshuffledBio(bdev, index_int, first_cluster_size);

    var last_bio = root_bio;
    var span_start = index_int + first_cluster_size;
    var span_size = sectors - first_cluster_size;
    while (span_size > 0) {
        const size = @min(span_size, lcg.cluster_size);
        const new_bio = try createDeshuffledBio(bdev, span_start, size);

        linux.bioChain(new_bio, last_bio);
        last_bio = new_bio;
        span_start += size;
        span_size -= size;
    }

    return root_bio;
}

fn createDeshuffledBio(bdev: *linux.BlockDevice, start: u64, size: u64) !*linux.Bio {
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

