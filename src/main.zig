const std = @import("std");

const server = @import("server.zig");

pub fn main() !void {
    var s = try server.Server.new("127.0.0.1", 8000);

    try s.serve();
}
