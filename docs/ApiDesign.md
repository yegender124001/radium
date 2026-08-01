# API Design
First I want to have some examples that I think shows how the API should be like

> **ⓘ NOTE:**<br>
> It's just the design. Not actual function it might have. And things are expected and surely change.
#### Hello World
```zig
const rad = @import("radium");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    try rad.init(init.gpa, init.args);
    defer rad.deinit();
    
    const win = try rad.Window.init();
    defer win.deinit();

    const label = try rad.Label.init("Hello World");
    defer label.deinit();

    win.setRootElement(label.element);
    win.setVisible(true);
    
    try rad.run();
}
```
#### Button
This example demostrate how signals are going to work.
```zig
const rad = @import("radium");
const std = @import("std");

fn buttonClick(btn: *rad.Button, data: ?*anyopaque) void {
    const msg = rad.MessageBox.init(.Info, "Hello World") catch return;
    defer msg.deinit();
}

pub fn main(init: std.process.Init) !void {
    try rad.init(init.gpa, init.args);
    defer rad.deinit();
    
    const win = try rad.Window.init();
    defer win.deinit();

    const button = try rad.Button.init("Click me");
    defer button.deinit();

    button.clicked.connect(null, null, buttonClick);

    win.setRootElement(button.element);
    win.setVisible(true);
    
    try rad.run();
}
```

## Components of the Radium
1. Element
2. Layout
3. Signals
<!---
  1. [Element](#Element)
  2. [Layout](#Layout)
  3. [Signals](#Signals)


## Element
Each of the UI component like a button or label is an element. So, it's planned to defined like
```zig
pub const VTable = struct {
    // Functions for getting, setting size, position
}
```

## Layouts

## Signals
-->
