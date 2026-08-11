#include "XdgToplevel.h"
#include "xdg-decoration-unstable-v1.h"
#include "xdg-shell.h"
#include <wayland-client-protocol.h>
#include <wayland-util.h>

const int DEFAULT_WIDTH = 800;
const int DEFAULT_HEIGHT = 600;

struct xdg_toplevel_listener XdgToplevel::m_listener = {
    .configure = toplevel_configure,
    .close = toplevel_close,
    .configure_bounds = toplevel_configure_bounds,
    .wm_capabilities = toplevel_wm_capabilities,
};

void XdgToplevel::toplevel_configure_bounds(void *data,
					     struct xdg_toplevel *xdg_toplevel,
					     int32_t width,
					     int32_t height) {

}

void XdgToplevel::toplevel_wm_capabilities(void *data,
					   struct xdg_toplevel *xdg_toplevel,
					   struct wl_array *capabilities) {

}

void XdgToplevel::toplevel_configure(void *data,
                                     struct xdg_toplevel *xdg_toplevel,
                                     int32_t width, int32_t height,
                                     struct wl_array *states) {
  if (width == 0 || height == 0)
    return;
  auto toplevel = static_cast<XdgToplevel *>(data);
  if (width == toplevel->m_width && height == toplevel->m_height)
    return;
  toplevel->m_width = width;
  toplevel->m_height = height;
}

void XdgToplevel::toplevel_close(void *data,
                                 struct xdg_toplevel *xdg_toplevel) {
  auto toplevel = static_cast<XdgToplevel *>(data);
  toplevel->m_win->hide();
}

XdgToplevel::XdgToplevel(PlatformWindow *win): m_win(win) {
  m_width = DEFAULT_WIDTH;
  m_height = DEFAULT_HEIGHT;
  m_toplevel = xdg_surface_get_toplevel(m_xdgSurface);
  if (m_platform->decoration())
    m_decor = zxdg_decoration_manager_v1_get_toplevel_decoration(
        m_platform->decoration(), m_toplevel);
  xdg_toplevel_add_listener(m_toplevel, &m_listener, this);
  wl_surface_commit(m_surface);
}

XdgToplevel::~XdgToplevel() {
  if (m_decor)
    zxdg_toplevel_decoration_v1_destroy(m_decor);
  xdg_toplevel_destroy(m_toplevel);
}

void XdgToplevel::configure() {
  m_backingStore->resize(m_width, m_height);
  flush();
}
