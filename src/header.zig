const std = @import("std");

pub const Header = struct {
    // Request-Header = Accept
    //  Accept-Charset
    //  Accept-Encoding
    //  Accept-Language
    //  Authorization
    //  From
    //  If-Modified-Since
    //  Orig-URI
    //  Referer
    //  User-Agent
    name: []const u8,
    value: []const u8,

    pub fn parse(line: []const u8) ?Header {
        var parts = std.mem.split(u8, line, ":");
        const name = parts.next() orelse return null;
        const value = parts.next() orelse return null;
        return .{
            .name = name,
            .value = value,
        };
    }
};
