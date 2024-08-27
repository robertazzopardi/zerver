const std = @import("std");

const request = @import("request.zig");
const response = @import("response.zig");
const logging = @import("logging.zig");

const posix = std.posix;
const net = std.net;
const testing = std.testing;

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
        // std.log.info("Server listening on {s}:{d}\n", .{ self.address.in.sa, self.address.getPort() });

        var socklen = self.address.getOsSockLen();

        var req_buffer: [1024]u8 = undefined;

        while (true) {
            const connection = try posix.accept(self.socket, &self.address.any, &socklen, 0);
            defer posix.close(connection);

            const rec_size = try posix.recv(connection, &req_buffer, 0);

            const req = try request.Request.parse(req_buffer[0..rec_size]);

            var res = response.Response.new(response.Status.OK, "Hello World");
            try res.set_header("Content-Type", "text/plain");
            _ = try posix.send(connection, res.build(), 0);

            Server.log_request(req, res);
        }

        self.close();
    }

    fn log_request(req: request.Request, res: response.Response) void {
        const host = req.get_header("Host") orelse "-";
        const request_line = req.request_line.string() orelse "-";
        const response_status = @intFromEnum(res.status_line.status);
        const bytes_returned = res.body.len;
        std.log.info("{s}\n", .{logging.common_log(host, request_line, response_status, bytes_returned)});
    }

    pub fn handle() void {}

    pub fn close(self: Server) void {
        posix.close(self.socket);
    }
};
