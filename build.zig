const std = @import("std");
const builtin = @import("builtin");

const include_dir = switch (builtin.target.os.tag) {
    .linux => "/usr/include",
    .windows => "C:\\Program Files\\PostgreSQL\\14\\include",
    .macos => "/opt/homebrew/opt/libpq",
    else => "/usr/include",
};

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    b.addSearchPrefix(include_dir);

    const opts = .{ .target = target, .optimize = optimize };
    const postgres_module = b.dependency("postgres", opts).module("postgres");

    const db_uri = b.option(
        []const u8,
        "db",
        "Specify the database url",
    ) orelse "postgresql://postgresql:postgresql@localhost:5432/mydb";

    const db_options = b.addOptions();
    db_options.addOption([]const u8, "db_uri", db_uri);

    const exe = b.addExecutable(.{
        .name = "import-zig-tryout",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addOptions("build_options", db_options);
    exe.addModule("postgres", postgres_module);
    exe.linkSystemLibrary("pq");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = .Debug,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
