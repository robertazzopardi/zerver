const std = @import("std");

const posix = std.posix;
const net = std.net;

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

    pub fn serve(self: *Server) !void {
        var socklen = self.address.getOsSockLen();

        var buffer: [1024]u8 = undefined;

        while (true) {
            const s = try posix.accept(self.socket, &self.address.any, &socklen, 0);
            defer posix.close(s);

            const rec = try posix.recv(s, &buffer, 0);
            std.debug.print("{s}\n", .{buffer[0..rec]});

            const res = "HTTP/1.0 200 OK\n\nHello World";
            const rb = try posix.send(s, res, 0);
            std.debug.print("Sent {d} bytes\n\n", .{rb});
        }

        posix.close(self.socket);
    }
};

pub fn main() !void {
    var server = try Server.new("127.0.0.1", 8000);

    try server.serve();
}
