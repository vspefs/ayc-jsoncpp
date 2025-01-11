pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .optimize = optimize,
        .target = target,
        .link_libcpp = true,
    });
    mod.addCSourceFile(.{
        .file = b.path("src/main.cpp"),
        .flags = &.{"-std=c++26"},
    });

    const exe = b.addExecutable(.{
        .name = "exe",
        .root_module = mod,
    });

    const run = b.addRunArtifact(exe);
    run.step.dependOn(&exe.step);

    const run_step = b.step("run", "run the detector");
    run_step.dependOn(&run.step);
}

const std = @import("std");
