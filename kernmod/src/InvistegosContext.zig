const core = @import("core");
const linux = @import("linux.zig");

const Self = @This();

dev: *linux.DmDev,

pub const ContextCreateError = error {
    no_mem,
    inval_args,
};

pub fn ctxCToKernel(err: ContextCreateError) c_int {
    return switch (err) {
        ContextCreateError.no_mem => -12,
        ContextCreateError.inval_args => -22,
    };
}

pub fn create(ti: *linux.DmTarget, argc: c_uint, argv: [*][*]u8) ContextCreateError!*Self {
    if (argc != 1) {
        return ContextCreateError.inval_args;
    }

    const ptr = linux.kernelMalloc(@sizeOf(Self)) orelse {
        ti.@"error" = "Couldn't allocate Invistegos context";
        return ContextCreateError.no_mem;
    };
    const ctx: *Self = @ptrCast(@alignCast(ptr));
    errdefer {
        linux.kernelFree(ctx);
    }

    const table_mode = linux.dmTableGetMode(ti.table.?);
    if (linux.dmGetDevice(ti, @ptrCast(argv[0]), table_mode, &ctx.dev) != 0) {
        ti.@"error" = "Couldn't get device";
        return ContextCreateError.inval_args;
    }

    return ctx;
}

