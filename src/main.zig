const std = @import("std");

const server = @import("server.zig");
const logging = @import("logging.zig");

pub const std_options = .{
    // Set the log level to info
    .log_level = .info,

    // Define logFn to override the std implementation
    .logFn = logging.logger_fn,
};

pub fn main() !void {
    var s = try server.Server.new("127.0.0.1", 8000);

    try s.serve();
}
