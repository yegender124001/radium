const std = @import("std");
const rad = @import("radium");
const cairo = @import("cairo");

fn draw_red(e: *rad.Element, ctx: *cairo.Context) void {
    ctx.setSourceRGB(1, 0, 0);
    ctx.rectangle(0, 0, e.width, e.height);
    ctx.fill();
}

fn draw_green(e: *rad.Element, ctx: *cairo.Context) void {
    ctx.setSourceRGB(0, 1, 0);
    ctx.rectangle(0, 0, e.width, e.height);
    ctx.fill();
}

fn draw_blue(e: *rad.Element, ctx: *cairo.Context) void {
    ctx.setSourceRGB(0, 0, 1);
    ctx.rectangle(0, 0, e.width, e.height);
    ctx.fill();
}

fn draw_yellow(e: *rad.Element, ctx: *cairo.Context) void {
    ctx.setSourceRGB(1, 1, 0);
    ctx.rectangle(0, 0, e.width, e.height);
    ctx.fill();
}

fn draw_magenta(e: *rad.Element, ctx: *cairo.Context) void {
    ctx.setSourceRGB(1, 0, 1);
    ctx.rectangle(0, 0, e.width, e.height);
    ctx.fill();
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    try rad.init(gpa);
    defer rad.shutdown(gpa);

    var win: rad.RasterWindow = undefined;
    try win.init(gpa);
    defer win.deinit();

    win.backgroundColor = .{
        .r = 0,
        .g = 0.4,
        .b = 0.3,
        .a = 0.5,
    };

    var element: rad.Element = .{
        .userdata = @ptrCast(&win),
    };
    defer element.deinit(gpa);
    win.setRootElement(&element);

    var element2: rad.Element = .{
        .x = 100,
        .y = 100,
        .width = 100,
        .height = 100,
        .pDraw = draw_red,
    };
    defer element2.deinit(gpa);
    _ = try element.children.append(gpa, &element2);

    var element3: rad.Element = .{
        .x = 210,
        .y = 100,
        .width = 100,
        .height = 100,
        .pDraw = draw_green,
    };
    defer element3.deinit(gpa);
    _ = try element.children.append(gpa, &element3);

    var element4: rad.Element = .{
        .x = 320,
        .y = 100,
        .width = 100,
        .height = 100,
        .pDraw = draw_blue,
    };
    defer element4.deinit(gpa);
    _ = try element.children.append(gpa, &element4);

    var element5: rad.Element = .{
        .x = 100,
        .y = 210,
        .width = 100,
        .height = 100,
        .pDraw = draw_yellow,
    };
    defer element5.deinit(gpa);
    _ = try element.children.append(gpa, &element5);

    var element6: rad.Element = .{
        .x = 210,
        .y = 210,
        .width = 210,
        .height = 100,
        .pDraw = draw_magenta,
    };
    defer element6.deinit(gpa);
    _ = try element.children.append(gpa, &element6);

    win.setTitle("Example Program 1");
    try win.show();
    defer win.hide();

    try rad.run();
}
