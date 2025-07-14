const std = @import("std");
const Builder = std.Build;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("zwc", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const main_mod = b.createModule(
        .{
            .target = target,
            .root_source_file = b.path("examples/events.zig"),
            .optimize = optimize,
            //.version = .{ .major = version.major, .minor = version.minor, .patch = version.patch },
        },
    );
    main_mod.addImport("zwc", lib_mod);

    const lib = b.addLibrary(.{
        //.linkage = .static,
        .name = "zwc",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const main_demo = b.addExecutable(.{
        .name = "test",
        .root_module = main_mod,
    });
    b.installArtifact(main_demo);

    const run_cmd = b.addRunArtifact(main_demo);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const demo_step = b.step("demo", "Run demo");
    demo_step.dependOn(&run_cmd.step);
}
