const std = @import("std");

const constants = @import("constants.zig");
const header = @import("header.zig");

const ArrayList = std.ArrayList;

const Method = enum {
    GET,
    HEAD,
    PUT,
    POST,
    DELETE,
    LINK,
    UNLINK,

    const Error = error{not_supported};

    fn string(self: Method) []const u8 {
        return switch (self) {
            Method.GET => "GET",
            Method.HEAD => "HEAD",
            Method.PUT => "PUT",
            Method.POST => "POST",
            Method.DELETE => "DELETE",
            Method.LINK => "LINK",
            Method.UNLINK => "UNLINK",
        };
    }

    fn from(method: []const u8) Error!Method {
        return std.meta.stringToEnum(Method, method) orelse Error.not_supported;
    }
};

const RequestType = enum { simple, full };

const RequestError = error{
    InvalidRequest,
};

const RequestLine = struct {
    method: Method,
    resource: []const u8,
    protocol: []const u8,

    fn parse(line: []const u8) RequestError!RequestLine {
        var part = std.mem.split(u8, line, constants.SP);
        const method_str = part.next() orelse return RequestError.InvalidRequest;
        const method = Method.from(method_str) catch return RequestError.InvalidRequest;
        const resource = part.next() orelse return RequestError.InvalidRequest;
        const protocol = part.next() orelse return RequestError.InvalidRequest;

        return .{
            .method = method,
            .resource = resource,
            .protocol = protocol,
        };
    }
};

pub const Request = struct {
    request_line: RequestLine,
    headers: ArrayList(header.Header),

    pub fn parse(request_buffer: []u8) RequestError!Request {
        var lines = std.mem.split(u8, request_buffer, constants.CRLF);
        const request_line_string = lines.next() orelse return RequestError.InvalidRequest;
        const request_line = try RequestLine.parse(request_line_string);

        var headers = ArrayList(header.Header).init(std.heap.page_allocator);
        while (lines.next()) |chunk| {
            const parsed_header = header.Header.parse(chunk);

            if (parsed_header) |val| {
                headers.append(val) catch continue;
                std.debug.print("{}\n", .{val});
            }
        }

        return .{
            .request_line = request_line,
            .headers = headers,
        };
    }
};
