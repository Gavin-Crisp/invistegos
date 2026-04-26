const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b;
    std.debug.print("{s}", .{ "Project level build" });
}
