const std = @import("std");

/// Registry Configuration Setup Utility
pub fn main() !void {
    std.debug.print("\n╔════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║         Registry Configuration Setup Utility            ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════════╝\n\n", .{});

    std.debug.print("📦 NPM Registry Setup:\n", .{});
    std.debug.print("  1. Create npm account at https://www.npmjs.com/signup\n", .{});
    std.debug.print("  2. Generate auth token: npm token create --read-only\n", .{});
    std.debug.print("  3. Store in ~/.npmrc or set NPM_TOKEN environment variable\n\n", .{});

    std.debug.print("🐳 Docker Registry Setup:\n", .{});
    std.debug.print("  1. Create Docker Hub account at https://hub.docker.com/\n", .{});
    std.debug.print("  2. Generate token at https://hub.docker.com/settings/security\n", .{});
    std.debug.print("  3. Login: docker login -u USERNAME -p TOKEN\n\n", .{});

    std.debug.print("🐙 GitHub Container Registry Setup:\n", .{});
    std.debug.print("  1. Create GitHub account at https://github.com/join\n", .{});
    std.debug.print("  2. Generate token at https://github.com/settings/tokens\n", .{});
    std.debug.print("  3. Login: docker login ghcr.io -u USERNAME -p TOKEN\n\n", .{});

    std.debug.print("✅ Registry setup completed!\n\n", .{});
}
