const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.createModule(.{
        .root_source_file = b.path("shared/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const shared_tests = b.addTest(.{ .root_module = shared });
    const run_shared_tests = b.addRunArtifact(shared_tests);

    const test_step = b.step("test", "tun tests");
    test_step.dependOn(&run_shared_tests.step);
}
