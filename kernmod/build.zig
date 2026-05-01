const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});

    //
    // # Tests
    //

    const test_target = b.standardTargetOptions(.{});

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = test_target,
            .optimize = optimize,
        }),
    });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);

    //
    // # Kernmod
    //

    var kernmod_target_query = try std.Build.parseTargetQuery(.{
        .arch_os_abi = "x86_64-freestanding-gnu",
    });
    // The linux kernel doesn't preserve sse/avx registers across interrupts, so
    // things that might use them need to be disabled.
    kernmod_target_query.cpu_features_sub = std.Target.x86.featureSet(&.{ .avx, .mmx, .sse2, .sse, .x87 });
    const kernmod_target = b.resolveTargetQuery(kernmod_target_query);

    const kernmod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = kernmod_target,
        .optimize = optimize,
        // Kernel modules don't have stable addresses at link time
        .pic = true,
    });

    const core_dep = b.dependency("core", .{
        .target = kernmod_target,
        .optimize = optimize,
    });
    kernmod.addImport("core", core_dep.module("core"));

    const kernmod_obj = b.addObject(.{
        .name = "kernmod",
        .root_module = kernmod,
    });
    kernmod_obj.root_module.code_model = .kernel;
    // Kernel disables this, so I need to aswell
    kernmod_obj.root_module.red_zone = false;
    // __zig_probe_stack requires compiler rt, which is disabled
    kernmod_obj.root_module.stack_check = false;

    const install_kernmod = b.addInstallArtifact(kernmod_obj, .{ .dest_dir = .{ .override = .bin } });
    b.getInstallStep().dependOn(&install_kernmod.step);

    const kernmod_step = b.step("kernmod", "");
    kernmod_step.dependOn(&install_kernmod.step);
}

