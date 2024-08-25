const std = @import("std");

const request = @import("request.zig");

const posix = std.posix;
const net = std.net;

pub const Server = struct {
    address: net.Address,
    socket: posix.socket_t,

    pub fn new(ip: []const u8, port: u16) !Server {
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

    pub fn serve(self: *Server) !void {
        var socklen = self.address.getOsSockLen();

        var buffer: [1024]u8 = undefined;

        while (true) {
            const connection = try posix.accept(self.socket, &self.address.any, &socklen, 0);
            defer posix.close(connection);

            const rec_size = try posix.recv(connection, &buffer, 0);
            std.debug.print("{s}\n", .{buffer[0..rec_size]});

            _ = try request.Request.parse(buffer[0..rec_size]);

            const server_response = "HTTP/1.0 200 OK\n\nHello World";
            const sent_bytes = try posix.send(connection, server_response, 0);
            std.debug.print("Sent {d} bytes\n\n", .{sent_bytes});
        }

        posix.close(self.socket);
    }
};
