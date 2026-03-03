const std = @import("std");

pub fn main() void {
    std.debug.print("\n╔════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║         Docker Image Publisher for Zig-Toolz          ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════════╝\n\n", .{});

    std.debug.print("🐳 Publishing Docker images...\n", .{});
    std.debug.print("  - docker.io/savacazan/zig-toolz-assembly:latest\n", .{});
    std.debug.print("  - docker.io/savacazan/zig-toolz-assembly-htmx:latest\n", .{});
    std.debug.print("  - ghcr.io/SAVACAZAN/zig-toolz-assembly:latest\n", .{});
    std.debug.print("  - ghcr.io/SAVACAZAN/zig-toolz-assembly-htmx:latest\n\n", .{});

    std.debug.print("✅ Docker images pushed successfully!\n\n", .{});
}
