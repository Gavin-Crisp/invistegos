const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});

    createUtilitySteps(b, optimize);

    const impl_obj = try createImplObj(b, optimize);
    const kernmod_step = try compileKernmod(b, impl_obj);
    b.getInstallStep().dependOn(kernmod_step);
}

fn compileKernmod(b: *std.Build, impl_obj: *std.Build.Step.Compile) !*std.Build.Step {
    const kernmod_step = b.step("kernmod", "Invistegos kernel module");

    const write = b.addWriteFiles();
    _ = write.addCopyFile(b.path("build/Makefile"), "Makefile");
    _ = write.addCopyFile(b.path("build/interface.c"), "interface.c");
    _ = write.addCopyFile(impl_obj.getEmittedBin(), "implementation.o");
    _ = write.add(".implementation.o.cmd", "implementation.o: src/root.zig");
    _ = write.addCopyDirectory(b.path("src"), "src", .{});
    write.step.dependOn(&impl_obj.step);

    const run_make = b.addSystemCommand(&.{"make"});
    run_make.setCwd(write.getDirectory());
    run_make.step.dependOn(&write.step);

    const install_ko = b.addInstallFileWithDir(try write.getDirectory().join(b.allocator, "invistegos.ko"), .prefix, "invistegos.ko");
    install_ko.step.dependOn(&run_make.step);
    kernmod_step.dependOn(&install_ko.step);

    return kernmod_step;
}

fn createImplObj(b: *std.Build, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
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
            .optimize = optimize,
            // Kernel modules don't have stable addresses at link time
            .pic = true,
        }),
    });

    const core_dep = b.dependency("core", .{
        .target = impl_target,
        .optimize = optimize,
    });
    impl_obj.root_module.addImport("core", core_dep.module("core"));
    impl_obj.bundle_compiler_rt = false;
    impl_obj.want_lto = false;
    impl_obj.root_module.code_model = .kernel;
    // Kernel disables this, so I need to aswell
    impl_obj.root_module.red_zone = false;
    // __zig_probe_stack requires compiler rt, which is disabled
    impl_obj.root_module.stack_check = false;
    impl_obj.root_module.stack_protector = false;
    impl_obj.root_module.omit_frame_pointer = false;
    impl_obj.root_module.strip = true;

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
