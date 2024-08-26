const std = @import("std");

const testing = std.testing;

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

    const Error = error{ NoHeaderName, NoHeaderValue };

    pub fn new(name: []const u8, value: []const u8) Header {
        return .{ .name = name, .value = value };
    }

    pub fn parse(line: []const u8) Error!Header {
        var parts = std.mem.split(u8, line, ":");

        const key = parts.next() orelse return Error.NoHeaderName;
        const value = parts.rest();

        const parsed_name = std.mem.trim(u8, key, " ");
        const parsed_value = std.mem.trim(u8, value, " ");

        if (parsed_name.len == 0) {
            return Error.NoHeaderName;
        }

        if (parsed_value.len == 0) {
            return Error.NoHeaderValue;
        }

        return Header.new(parsed_name, parsed_value);
    }

    pub fn string(self: Header) ?[]const u8 {
        if (self.name.len == 0 or self.value.len == 0) {
            return null;
        }
        return std.fmt.allocPrint(std.heap.page_allocator, "{s}: {s}", .{
            self.name, self.value,
        }) catch null;
    }
};

test "Test header parsing" {
    const valid_header = try Header.parse("Accept: */*");
    try testing.expect(std.mem.eql(u8, valid_header.name, "Accept"));
    try testing.expect(std.mem.eql(u8, valid_header.value, "*/*"));

    const valid_with_multi_colon = try Header.parse("Host: localhost:8080");
    try testing.expect(std.mem.eql(u8, valid_with_multi_colon.name, "Host"));
    try testing.expect(std.mem.eql(u8, valid_with_multi_colon.value, "localhost:8080"));

    const invalid_no_name = Header.parse("");
    try testing.expectError(Header.Error.NoHeaderName, invalid_no_name);

    const invalid_space_for_name = Header.parse(" ");
    try testing.expectError(Header.Error.NoHeaderName, invalid_space_for_name);

    const invalid_value_no_header = Header.parse(": localhost:8080");
    try testing.expectError(Header.Error.NoHeaderName, invalid_value_no_header);

    const invalid_no_value = Header.parse("Accept: ");
    try testing.expectError(Header.Error.NoHeaderValue, invalid_no_value);
}

test "Creating header string" {
    const header = Header{ .name = "Content-Type", .value = "text/plain" };
    try testing.expect(std.mem.eql(u8, header.string() orelse "", "Content-Type: text/plain"));

    const invalid_header = Header{ .name = "", .value = "" };
    try testing.expect(invalid_header.string() == null);
}
