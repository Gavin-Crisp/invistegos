const std = @import("std");

fn get_config(b: *std.Build) *std.Build.Step.Options {
    const config = b.addOptions();

    const lcg_bits = b.option(u16, "lcg_bits", "bit width of lcg distribution") orelse 32;
    const lcg_mult = b.option(u64, "lcg_mult", "multiplier for lcg distribution") orelse 3452;
    const lcg_incr = b.option(u64, "lcg_incr", "increment for lcg distribution") orelse 10958;

    const crc_bytes = b.option(u8, "crc_bytes", "byte width of crc value") orelse 4;
    const crc_generator = b.option(u256, "crc_generator", "CRC generator polynomial") orelse 245;

    const d_nodes = b.option(u64, "d_nodes", "number of data sectors in ldpc scheme") orelse 8;
    const c_nodes = b.option(u64, "c_nodes", "number of check sectors in ldpc scheme") orelse 8;
    const ldpc_girth = b.option(u8, "ldpc_girth", "minimum cycle length in ldpc scheme") orelse 4;

    config.addOption(u16, "lcg_bits", lcg_bits);
    config.addOption(u64, "lcg_mult", lcg_mult);
    config.addOption(u64, "lcg_incr", lcg_incr);
    config.addOption(u8, "crc_bytes", crc_bytes);
    config.addOption(u256, "crc_generator", crc_generator);
    config.addOption(u64, "d_nodes", d_nodes);
    config.addOption(u64, "c_nodes", c_nodes);
    config.addOption(u8, "ldpc_girth", ldpc_girth);

    return config;
}

pub fn build(b: *std.Build) void {
    const config = get_config(b);

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const core = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    core.addOptions("config", config);

    const tests = b.addTest(.{ .root_module = core });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "run tests");
    test_step.dependOn(&run_tests.step);
}
