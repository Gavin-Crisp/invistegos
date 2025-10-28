const std = @import("std");

fn get_config_options(b: *std.Build) *std.Build.Step.Options {
    const options = b.addOptions();

    const lcg_bits = b.option(u16, "lcg_bits", "bit width of lcg distribution") orelse 32;
    const lcg_mult = b.option(u65535, "lcg_mult", "multiplier for lcg distribution") orelse 3452;
    const lcg_incr = b.option(u65535, "lcg_incr", "increment for lcg distribution") orelse 10958;

    const crc_bytes = b.option(u6, "crc_bytes", "byte width of crc value") orelse 4;
    const crc_generator = b.option(u65535, "crc_generator", "CRC generator polynomial") orelse 245;

    options.addOption(u16, "lcg_bits", lcg_bits);
    options.addOption(u65535, "lcg_mult", lcg_mult);
    options.addOption(u65535, "lcg_incr", lcg_incr);
    options.addOption(u65535, "crc_bytes", crc_bytes);
    options.addOption(u65535, "crc_generator", crc_generator);

    return options;
}

pub fn build(b: *std.Build) void {
    const options = get_config_options(b);

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.createModule(.{
        .root_source_file = b.path("shared/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    shared.addOptions("config", options);

    const shared_tests = b.addTest(.{ .root_module = shared });
    const run_shared_tests = b.addRunArtifact(shared_tests);

    const test_step = b.step("test", "tun tests");
    test_step.dependOn(&run_shared_tests.step);
}
