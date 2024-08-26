const std = @import("std");

const constants = @import("constants.zig");
const header = @import("header.zig");

const fmt = std.fmt;
const heap = std.heap;
const ArrayList = std.ArrayList;

pub const Status = enum(u9) {
    OK = 200,
    Created = 201,
    Accepted = 202,
    NonAuthoritativeInformation = 203,
    NoContent = 204,
    MultipleChoices = 300,
    MovedPermanently = 301,
    MovedTemporarily = 302,
    SeeOther = 303,
    NotModified = 304,
    BadRequest = 400,
    Unauthorized = 401,
    PaymentRequired = 402,
    Forbidden = 403,
    NotFound = 404,
    MethodNotAllowed = 405,
    NoneAcceptable = 406,
    ProxyAuthenticationRequired = 407,
    RequestTimeout = 408,
    Conflict = 409,
    Gone = 410,
    AuthorizationRefused = 411,
    InternalServerError = 500,
    NotImplemented = 501,
    BadGateway = 502,
    ServiceUnavailable = 503,
    GatewayTimeout = 504,

    fn reason(self: Status) []const u8 {
        return switch (@intFromEnum(self)) {
            200 => "OK",
            201 => "Created",
            202 => "Accepted",
            203 => "Non-Authoritative Information",
            204 => "No Content",
            300 => "Multiple Choices",
            301 => "Moved Permanently",
            302 => "Moved Temporarily",
            303 => "See Other",
            304 => "Not Modified",
            400 => "Bad Request",
            401 => "Unauthorized",
            402 => "Payment Required",
            403 => "Forbidden",
            404 => "Not Found",
            405 => "Method Not Allowed",
            406 => "None Acceptable",
            407 => "Proxy Authentication Required",
            408 => "Request Timeout",
            409 => "Conflict",
            410 => "Gone",
            411 => "Authorization Refused",
            500 => "Internal Server Error",
            501 => "Not Implemented",
            502 => "Bad Gateway",
            503 => "Service Unavailable",
            504 => "Gateway Timeout",
            else => unreachable,
        };
    }
};

const StatusLine = struct {
    version: []const u8,
    status: Status,

    fn new(status: Status) StatusLine {
        return .{
            .version = "HTTP/1.0",
            .status = status,
        };
    }

    fn build(self: StatusLine) []const u8 {
        const buf = std.fmt.allocPrint(std.heap.page_allocator, "{s} {d} {s}", .{
            self.version,
            @intFromEnum(self.status),
            self.status.reason(),
        }) catch "format failed";

        return buf;
    }
};

pub const Response = struct {
    status_line: StatusLine,
    headers: ArrayList(header.Header),
    body: []const u8,

    pub fn new(status: Status, body: []const u8) Response {
        const headers = ArrayList(header.Header).init(heap.page_allocator);
        return .{
            .status_line = StatusLine.new(status),
            .headers = headers,
            .body = body,
        };
    }

    pub fn build(self: Response) []const u8 {
        const buf = std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}{s}{s}{s}{s}{s}", .{
            self.status_line.build(),
            constants.CRLF,
            "Content-Type: text/plain",
            constants.CRLF,
            constants.CRLF,
            self.body,
            constants.CRLF,
        }) catch "format failed";

        return buf;
    }
};
