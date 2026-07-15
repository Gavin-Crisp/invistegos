const core = @import("core");

const dm_target = struct {};
const bio = struct {};

pub export fn invistegos_impl_ctr(dm: *dm_target, argc: c_uint, argv: **c_char) c_int {
    _ = dm;
    _ = argc;
    _ = argv;

    return 0;
}

pub export fn invistegos_impl_dtr(dm: *dm_target) void {
    _ = dm;
}

pub export fn invistegos_impl_map(dm: *dm_target, bi: *bio) c_int {
    _ = dm;
    _ = bi;

    return 0;
}
