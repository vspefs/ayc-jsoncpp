pub fn build(b: *std.Build) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer if (gpa.deinit() == .leak) @panic("memory leak");

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const alloc = arena.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.dependency("src", .{});
    const secure_memory = b.option(bool, "secure", "If on, the library zeroes any memory that it has allocated before it frees its memory. (default: false)") orelse false;
    const build_static = b.option(bool, "static", "build static library (default: true)") orelse true;
    const build_shared = b.option(bool, "shared", "build shared library (default: false)") orelse false;

    var defines = std.ArrayList([]const u8).init(alloc);
    var cargs = std.ArrayList([]const u8).init(alloc);
    try cargs.appendSlice(&.{
        "-std=c++11",
        "-fno-sanitize=undefined",
    });

    const compiler_features = try std.json.parseFromSliceLeaky(
        struct {
            have_memset_s: bool,
            have_clocale: bool,
            have_localeconv: bool,
            lconv_size: usize, // 0 means `lconv` does not exist
            have_decimal_point: bool,
        },
        alloc,
        blk: {
            const detector = b.dependency("detector", .{}).builder.build_root.handle;
            var detecting = std.process.Child.init(&.{ b.graph.zig_exe, "build", "run" }, alloc);
            detecting.cwd_dir = detector;
            detecting.stdout_behavior = .Pipe;
            _ = try detecting.spawn();
            const ret = try detecting.stdout.?.readToEndAlloc(alloc, 1024);
            _ = try detecting.wait();
            break :blk ret;
        },
        .{},
    );

    if (compiler_features.have_memset_s) {
        try defines.append("-DHAVE_MEMSET_S=1");
    }
    if (!(compiler_features.have_clocale and compiler_features.have_localeconv and compiler_features.have_decimal_point and compiler_features.lconv_size != 0)) {
        try defines.append("-DJSONCPP_NO_LOCALE_SUPPORT");
    }
    if (secure_memory) {
        try defines.append("-DJSONCPP_USE_SECURE_MEMORY=1");
    }

    const version = b.addConfigHeader(
        .{
            .style = .{ .cmake = dep.path("version.in") },
            .include_path = "version",
        },
        .{ .JSONCPP_VERSION = "1.9.7" },
    );
    _ = version;

    const mod = b.addModule("sources", .{
        .optimize = optimize,
        .target = target,
        .link_libcpp = true,
    });
    mod.addIncludePath(dep.path("include"));
    mod.addIncludePath(dep.path("src/lib_json"));
    mod.addCSourceFiles(.{
        .files = &.{
            "json_reader.cpp",
            "json_value.cpp",
            "json_writer.cpp",
        },
        .flags = try std.mem.concat(alloc, []const u8, &.{ cargs.items, defines.items }),
        .root = dep.path("src/lib_json"),
    });

    if (build_static) {
        const static = b.addStaticLibrary(.{
            .name = "jsoncpp",
            .root_module = mod,
        });
        static.installHeadersDirectory(dep.path("include"), "", .{});
        b.getInstallStep().dependOn(&b.addInstallArtifact(static, .{}).step);
    }

    if (build_shared) {
        const shared = b.addSharedLibrary(.{
            .name = "jsoncpp",
            .root_module = mod,
        });
        shared.installHeadersDirectory(dep.path("include"), "", .{});
        b.getInstallStep().dependOn(&b.addInstallArtifact(shared, .{}).step);
    }
}

const std = @import("std");
