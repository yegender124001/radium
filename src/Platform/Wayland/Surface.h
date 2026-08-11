#pragma once

#include "Platform/Wayland/Wayland.h"
#include <wayland-client.h>
#include "WlBackingStore.h"

class Wayland;
class Surface {
public:
    Surface();
    ~Surface();

    struct wl_surface* getSurface() const { return m_surface; }

    void setBackingStore(WlBackingStore *backingStore);
    virtual void resize(int width, int height) = 0;
protected:
    WlBackingStore *m_backingStore = nullptr;
    virtual void configure() = 0;

    void flush();
    struct wl_surface *m_surface;
    Wayland *m_platform;

    int m_width;
    int m_height;
};
