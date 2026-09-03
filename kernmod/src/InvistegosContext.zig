const core = @import("core");
const linux = @import("linux.zig");
const interop = @import("interop.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const IoSubmitter = @import("InvistegosContext/IoSubmitter.zig");
const LinuxErr = interop.LinuxErr;

const Self = @This();

alloc: Allocator,
io_submitter: IoSubmitter,

pub fn create(alloc: Allocator, ti: *linux.DmTarget, argc: c_uint, argv: [*][*]u8) ContextCreateError!*Self {
    if (argc != 1) {
        return ContextCreateError.InvalidArgs;
    }

    const ctx = alloc.create(Self) catch {
        ti.@"error" = "Couldn't allocate Invistegos context";
        return ContextCreateError.NoMemory;
    };
    errdefer alloc.destroy(ctx);

    const table_mode = linux.dmTableGetMode(ti.table.?);
    var dev: *linux.DmDev = undefined;
    if (linux.dmGetDevice(ti, @ptrCast(argv[0]), table_mode, &dev) != 0) {
        ti.@"error" = "Couldn't get device";
        return ContextCreateError.InvalidArgs;
    }
    ctx.io_submitter.init(dev);
    errdefer ctx.io_submitter.deinit(ti);

    return ctx;
}

pub fn destroy(self: *Self, ti: *linux.DmTarget) void {
    self.io_submitter.deinit(ti);
    self.alloc.destroy(self);
}

pub fn triggerFlush(self: Self) !void {
    // # Flush cache
    // TODO

    // # Flush underlying
    try self.io_submitter.sendFlush();
}

pub const ContextCreateError = error {
    NoMemory,
    InvalidArgs,
};

pub fn convertCtxErr(err: ContextCreateError) c_int {
    return switch (err) {
        ContextCreateError.NoMemory => LinuxErr.nomem,
        ContextCreateError.InvalidArgs => LinuxErr.inval,
    };
}

