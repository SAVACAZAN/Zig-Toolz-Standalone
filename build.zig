const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Automation scripts build step
    const automation_step = b.step("automation", "Build all automation scripts");

    // Define all automation scripts (48 total)
    const automation_scripts = [_][]const u8{
        // Publishing & Registries (7)
        "registry-setup",
        "npm-publish",
        "docker-push",
        "github-release",
        "package-dist",
        "version-publish",
        "publish-all",
        // Setup & Initialization (4)
        "init-project",
        "setup-ci",
        "env-setup",
        "install-deps",
        // Testing & Quality (5)
        "lint-all",
        "format-code",
        "integration-test",
        "smoke-test",
        "performance-bench",
        // Security & Scanning (4)
        "security-scan",
        "security-audit",
        "dependency-check",
        "api-security-test",
        // Monitoring & Maintenance (5)
        "logs-search",
        "metrics-collect",
        "db-migrate",
        "update-deps",
        "clean-artifacts",
        // Analysis & Reporting (3)
        "changelog-gen",
        "code-stats",
        "health-report",
        // Kubernetes & Orchestration (6)
        "k8s-deploy",
        "k8s-rollback",
        "k8s-scale",
        "helm-upgrade",
        "pod-logs",
        "k8s-health",
        // Multi-Region Deployment (4)
        "region-failover",
        "geo-health-check",
        "replica-sync",
        "traffic-split",
        // Advanced Monitoring (5)
        "alert-rules-push",
        "dashboard-deploy",
        "slo-report",
        "trace-analyze",
        "uptime-monitor",
        // Infrastructure as Code (5)
        "terraform-plan",
        "infra-drift",
        "secret-rotate",
        "env-validate",
        "config-diff",
    };

    inline for (automation_scripts) |script_name| {
        const script_exe = b.addExecutable(.{
            .name = script_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(
                    b.fmt("src/automation/{s}.zig", .{script_name}),
                ),
                .target = target,
                .optimize = optimize,
            }),
        });
        b.installArtifact(script_exe);
        automation_step.dependOn(&script_exe.step);
    }

    // Default step: build automation tools
    const default_step = b.step("default", "Build all automation tools");
    default_step.dependOn(automation_step);
    b.default_step = default_step;
}