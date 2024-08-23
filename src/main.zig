const std = @import("std");
const posix = std.posix;

pub fn main() !void {
    var sockaddr = try std.net.Address.parseIp4("127.0.0.1", 8080);
    var socklen = sockaddr.getOsSockLen();

    const socket = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, posix.IPPROTO.TCP);
    defer posix.close(socket);
    try posix.setsockopt(socket, posix.SOL.SOCKET, posix.SO.REUSEADDR, "true");
    try posix.bind(socket, &sockaddr.any, socklen);
    try posix.listen(socket, 1);

    var buffer: [1024]u8 = undefined;
    while (true) {
        const s = try posix.accept(socket, &sockaddr.any, &socklen, 0);
        defer posix.close(s);

        const rec = try posix.recv(s, &buffer, 0);
        std.debug.print("Received {d} bytes: {s}\n", .{ rec, buffer[0..rec] });

        const res = "HTTP/1.0 200 OK\n\nHello World";
        const rb = try posix.send(s, res, 0);
        std.debug.print("Sent {d} bytes\n\n", .{rb});
    }
}
