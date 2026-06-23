const Builder = @import("std").Build;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zwc", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
    });

    const main_demo = b.addExecutable(.{
        .name = "events",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/events.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zwc", .module = mod },
            },
        }),
    });
    b.installArtifact(main_demo);
}
