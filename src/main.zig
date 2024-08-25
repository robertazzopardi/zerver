const std = @import("std");
const r = @import("root.zig");

const posix = std.posix;
const net = std.net;
const ArrayList = std.ArrayList;

const CRLF = "\r\n";
const SP = " ";

const Server = struct {
    address: net.Address,
    socket: posix.socket_t,

    fn new(ip: []const u8, port: u16) !Server {
        var address = try net.Address.parseIp4(ip, port);
        const socket = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, posix.IPPROTO.TCP);

        try posix.setsockopt(socket, posix.SOL.SOCKET, posix.SO.REUSEADDR, "true");
        try posix.bind(socket, &address.any, address.getOsSockLen());
        try posix.listen(socket, 1);

        return .{
            .address = address,
            .socket = socket,
        };
    }

    fn serve(self: *Server) !void {
        var socklen = self.address.getOsSockLen();

        var buffer: [1024]u8 = undefined;

        while (true) {
            const connection = try posix.accept(self.socket, &self.address.any, &socklen, 0);
            defer posix.close(connection);

            const rec_size = try posix.recv(connection, &buffer, 0);
            std.debug.print("{s}\n", .{buffer[0..rec_size]});

            _ = try Request.parse(buffer[0..rec_size]);

            const server_response = "HTTP/1.0 200 OK\n\nHello World";
            const sent_bytes = try posix.send(connection, server_response, 0);
            std.debug.print("Sent {d} bytes\n\n", .{sent_bytes});
        }

        posix.close(self.socket);
    }
};

const RequestType = enum { simple, full };

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

const Header = struct {
    name: []const u8,
    value: []const u8,

    fn parse(line: []const u8) ?Header {
        var parts = std.mem.split(u8, line, ":");
        const name = parts.next() orelse return null;
        const value = parts.next() orelse return null;
        return .{
            .name = name,
            .value = value,
        };
    }
};

const RequestError = error{
    InvalidRequest,
};

const RequestLine = struct {
    method: Method,
    resource: []const u8,
    protocol: []const u8,

    fn parse(line: []const u8) RequestError!RequestLine {
        var part = std.mem.split(u8, line, SP);
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

const Request = struct {
    request_line: RequestLine,
    headers: ArrayList(Header),

    fn parse(request: []u8) RequestError!Request {
        var lines = std.mem.split(u8, request, CRLF);
        const request_line_string = lines.next() orelse return RequestError.InvalidRequest;
        const request_line = try RequestLine.parse(request_line_string);

        var headers = ArrayList(Header).init(std.heap.page_allocator);
        while (lines.next()) |chunk| {
            const header = Header.parse(chunk);

            if (header) |val| {
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

const Response = struct {};

pub fn main() !void {
    var server = try Server.new("127.0.0.1", 8000);

    try server.serve();
}
