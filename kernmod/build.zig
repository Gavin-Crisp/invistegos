const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    const kdir_opt = b.option([]const u8, "kdir", "Directory of kernel to build against");

    const impl_obj = try createImplObj(b, optimize);

    createImplStep(b, impl_obj);
    const kernmod_step = try createKernmodStep(b, impl_obj, kdir_opt);
    createUtilitySteps(b, optimize);

    b.getInstallStep().dependOn(kernmod_step);
}

fn createImplStep(b: *std.Build, impl_obj: *std.Build.Step.Compile) void {
    const impl_step = b.step("impl", "zig code");
    const install_impl = b.addInstallArtifact(impl_obj, .{
        .dest_dir = .{ .override = .{ .custom = "obj" } }
    });
    impl_step.dependOn(&install_impl.step);
}

fn createKernmodStep(b: *std.Build, impl_obj: *std.Build.Step.Compile, kdir_opt: ?[]const u8) !*std.Build.Step {
    const kernmod_step = b.step("kernmod", "Invistegos kernel module");

    const kdir = kdir_opt orelse {
        kernmod_step.dependOn(&b.addFail("Requires -Dkdir").step);
        return kernmod_step;
    };

    const write = b.addWriteFiles();
    _ = write.addCopyFile(b.path("build/Makefile"), "Makefile");
    _ = write.addCopyFile(b.path("build/interface.c"), "interface.c");
    _ = write.addCopyFile(impl_obj.getEmittedBin(), "implementation.o");
    _ = write.add(".implementation.o.cmd", "implementation.o: root.zig");
    _ = write.addCopyFile(b.path("src/root.zig"), "root.zig");
    write.step.dependOn(&impl_obj.step);

    const run_make = b.addSystemCommand(&.{"make", b.fmt("KDIR={s}", .{kdir})});
    run_make.setCwd(write.getDirectory());
    run_make.step.dependOn(&write.step);

    const install_ko = b.addInstallFileWithDir(try write.getDirectory().join(b.allocator, "invistegos.ko"), .prefix, "invistegos.ko");
    install_ko.step.dependOn(&run_make.step);
    kernmod_step.dependOn(&install_ko.step);

    return kernmod_step;
}

fn createImplObj(b: *std.Build, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const opt, const warn_release = if (optimize == .Debug) .{ .ReleaseFast, true }
        else .{ optimize, false };

    const impl_target = init: {
        var impl_target_query = try std.Build.parseTargetQuery(.{
            .arch_os_abi = "x86_64-freestanding-gnu",
        });
        // The linux kernel doesn't preserve sse/avx registers across interrupts, so
        // things that might use them need to be disabled.
        impl_target_query.cpu_features_sub = std.Target.x86.featureSet(&.{ .avx, .mmx, .sse2, .sse, .x87 });
        break :init b.resolveTargetQuery(impl_target_query);
    };

    const impl_obj = b.addObject(.{
        .name = "implementation",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = impl_target,
            .optimize = opt,
            // Kernel modules don't have stable addresses at link time
            .pic = true,
            .strip = true,
            .code_model = .kernel,
            .stack_protector = false,
            .stack_check = false,
            // Kernel disables this
            .red_zone = false,
            .omit_frame_pointer = false,
        }),
    });

    const core_dep = b.dependency("core", .{
        .target = impl_target,
        .optimize = optimize,
    });
    impl_obj.root_module.addImport("core", core_dep.module("core"));

    impl_obj.bundle_compiler_rt = false;
    impl_obj.bundle_ubsan_rt = false;
    impl_obj.lto = .none;

    if (warn_release) {
        const warn_command = b.addSystemCommand(&.{ "echo", "Cannot build in debug mode, selecting default fast release\n\n" });
        impl_obj.step.dependOn(&warn_command.step);
    }

    return impl_obj;
}

fn createUtilitySteps(b: *std.Build, optimize: std.builtin.OptimizeMode) void {
    // Test
    const test_step = b.step("test", "Run tests");
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = b.standardTargetOptions(.{}),
            .optimize = optimize,
        }),
    });
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);

    // Clean
    const clean_step = b.step("clean", "Remove build artifacts");
    const clean_command = b.addSystemCommand(&[_][]const u8{ "sh", "-c", "rm -rf zig-out .zig-cache zigko.ko zigko.mod.c zigko.mod.o zigko.o modules.order Module.symvers .*.cmd *.ko *.mod *.mod.c *.mod.o *.o" });
    clean_step.dependOn(&clean_command.step);

    // Format
    const fmt_step = b.step("fmt", "Check formatting");
    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
            "build.zig.zon",
        },
    });
    fmt_step.dependOn(&fmt.step);
}
