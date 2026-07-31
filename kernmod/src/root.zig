const linux = @import("linux.zig");
const interop = @import("interop.zig");
const InvistegosContext = @import("InvistegosContext.zig");
const ContextCreateError = InvistegosContext.ContextCreateError;

/// Initializes ti
pub export fn invistegos_impl_ctr(ti: *linux.DmTarget, argc: c_uint, argv: [*][*]u8) callconv(.c) c_int {
    const context = InvistegosContext.create(interop.k_alloc, ti, argc, argv)
        catch |err| return InvistegosContext.convertCtxErr(err);

    ti.private = @ptrCast(context);

    return 0;
}

/// Frees ti.private
pub export fn invistegos_impl_dtr(ti: *linux.DmTarget) callconv(.c) void {
    const context: *InvistegosContext = @ptrCast(@alignCast(ti.private));
    context.destroy(interop.k_alloc, ti);
}

pub export fn invistegos_impl_map(ti: *linux.DmTarget, bi: *linux.Bio) callconv(.c) c_int {
    _ = ti;
    _ = bi;

    return 0;
}
