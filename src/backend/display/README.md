# Platform Abstraction Layer
I wanted to plan about the platform abstraction layer to have some good
implementation. This library is going to be used for making applications,
layer shell surfaces and a compositor. So, I need to address things required.
This is what I compiled and I hope it's complete:
### 1. A platform global interface
  - One per backed
  - Stores the wayland globals like wl_display, wl_registry, wl_compositor etc.
### 2. A platform surface or window interface
  - This is one per window
  - Stores wl_surface, it's role or related things needed.
  - This doesn't have a rendring pipeline. As it's attached later
### 3. A platform screen interface
  - One per the screen
  - It helps to assist on which screen the window is visible or display on specific screen.
  - On wayland you get it from wl_output
### 4. A platform rendering pipeline interface
  - It's purpose is to decouple the rendring from the surface to allow us to have some different types of backing stores.

--------------------------------------------------------------------
If it was C++. I would do it with inheritance. But as I decided to use zig I designed it this below purposed way.

## Platform Manager
It will manage the available platforms for radium. And I will have wayland as hard coded platform and for dynamic platform I would expose the api with plugin kinda like this
```zig
pub const Platforms = union(enum) {
    Wayland: *wayland,
    Plugin: *plugin,
};
```
If we decide to add a new platform we will add it to this union and external projects should use Plugin.

## Platform
Entry point for the platform implementation. It's going to initialize platform and create surfaces and emits a signal when the platform fd have event and dispatch that.
```zig
pub const VTable = struct {
    deinit: *const fn(*anyopaque) void, // To deinit the platform
    createSurface: *const fn(*Window) *anyopaque, // [1] Discussed below
};
```

## Platform Surface
User might create a window like this:
```zig
const win = try Window.init(allocator);
```
Under the init function it's supposed to create a window structure and pass it to the `createSurface` to the **Platform**. and the returned pointer will be stored as platform surface data.

**Window** is itself just a container of the properties. And when it's set to visible it create a surface on basis of these properties and on hidden it will destroy the surface.

I think it's should be defined as:
```zig
pub const VTable = struct {
    deinit: *const fn (*anyopaque) void,
    resize: *const fn (*anyopaque, i32, i32) void,
    title: ?*const fn (*anyopaque, String) void,
    ...
}
```

## Platform Screen
It's self explanatory.
