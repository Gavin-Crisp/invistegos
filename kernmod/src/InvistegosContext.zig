const core = @import("core");
const linux = @import("linux.zig");
const interop = @import("interop.zig");
const std = @import("std");
const LinuxErr = interop.LinuxErr;

const Self = @This();

dev: *linux.DmDev,

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

pub fn create(alloc: std.mem.Allocator, ti: *linux.DmTarget, argc: c_uint, argv: [*][*]u8) ContextCreateError!*Self {
    if (argc != 1) {
        return ContextCreateError.InvalidArgs;
    }

    const ctx = alloc.create(Self) catch {
        ti.@"error" = "Couldn't allocate Invistegos context";
        return ContextCreateError.NoMemory;
    };
    errdefer alloc.destroy(ctx);

    const table_mode = linux.dmTableGetMode(ti.table.?);
    if (linux.dmGetDevice(ti, @ptrCast(argv[0]), table_mode, &ctx.dev) != 0) {
        ti.@"error" = "Couldn't get device";
        return ContextCreateError.InvalidArgs;
    }

    return ctx;
}

pub fn destroy(self: *Self, alloc: std.mem.Allocator, ti: *linux.DmTarget) void {
    linux.dmPutDevice(ti, self.dev);
    alloc.destroy(self);
}

