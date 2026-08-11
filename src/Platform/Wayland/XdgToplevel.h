#pragma once

#include "Platform/PlatformWindow.h"
#include "XdgSurface.h"
#include "xdg-decoration-unstable-v1.h"
#include <wayland-util.h>

struct xdg_toplevel;
class XdgToplevel : public XdgSurface {
public:
    XdgToplevel(PlatformWindow *win);
    ~XdgToplevel() override;

    void resize(int width, int height) override;
    void setTitle(const std::string& title);
protected:
    struct xdg_toplevel *m_toplevel;
    struct zxdg_toplevel_decoration_v1 *m_decor = nullptr;
    PlatformWindow *m_win;

    void configure() override;
    static struct xdg_toplevel_listener m_listener;
    static void toplevel_configure(void *data,
			  struct xdg_toplevel *xdg_toplevel,
			  int32_t width,
			  int32_t height,
			  struct wl_array *states);
    static void toplevel_close(void *data, struct xdg_toplevel *xdg_toplevel);

    static void toplevel_configure_bounds(void *data,
					  struct xdg_toplevel *xdg_toplevel,
					  int32_t width,
					  int32_t height);
    static void toplevel_wm_capabilities(void *data,
					 struct xdg_toplevel *xdg_toplevel,
					 struct wl_array *capabilities);
};
