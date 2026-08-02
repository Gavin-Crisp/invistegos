const linux = @import("linux.zig");
const interop = @import("interop.zig");
const InvistegosContext = @import("InvistegosContext.zig");
const ContextCreateError = InvistegosContext.ContextCreateError;

/// Initializes ti
pub export fn invistegos_impl_ctr(ti: *linux.DmTarget, argc: c_uint, argv: [*][*]u8) callconv(.c) c_int {
    const context = InvistegosContext.create(interop.k_alloc, ti, argc, argv)
        catch |err| return InvistegosContext.convertCtxErr(err);

    ti.num_flush_bios = 1;
    ti.num_discard_bios = 1;
    ti.num_write_zeroes_bios = 1;
    ti.num_secure_erase_bios = 1;
    ti.private = @ptrCast(context);

    return 0;
}

/// Frees ti.private
pub export fn invistegos_impl_dtr(ti: *linux.DmTarget) callconv(.c) void {
    const context: *InvistegosContext = @ptrCast(@alignCast(ti.private));
    context.destroy(interop.k_alloc, ti);
}

/// Returns -
/// * < 0: error
/// * = 0: The target will handle the io by resubmitting it later
/// * = 1: simple remap complete
/// * = 2: The target wants to push back the io
/// * = 3: Delay requeue (also push back but later?)
/// * = 4: The target wants to complete the I/O
pub export fn invistegos_impl_map(ti: *linux.DmTarget, bi: *linux.Bio) callconv(.c) c_int {
    const context: *InvistegosContext = @ptrCast(@alignCast(ti.private));

    switch (linux.bioOp(bi)) {
        .read => {},
        .write => {},
        .flush => {
            linux.bioSetDev(bi, context.dev.bdev.?);
            return 1;
        },
        .discard => {},
        .secure_erase => {},
        .write_zeroes => {},
        else => return 4,
    }

    return 0;
}
