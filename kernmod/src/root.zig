const core = @import("core");
const linux = @import("linux.zig");

/// Initializes ti
pub export fn invistegos_impl_ctr(ti: *linux.DmTarget, argc: c_uint, argv: **c_char) callconv(.c) c_int {
    _ = ti;
    _ = argc;
    _ = argv;

    return 0;
}

/// Frees ti.private
pub export fn invistegos_impl_dtr(ti: *linux.DmTarget) callconv(.c) void {
    _ = ti;
}

pub export fn invistegos_impl_map(ti: *linux.DmTarget, bi: *linux.Bio) callconv(.c) c_int {
    _ = ti;
    _ = bi;

    return 0;
}
