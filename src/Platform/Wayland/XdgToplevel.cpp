#include "XdgToplevel.h"
#include "xdg-decoration-unstable-v1.h"
#include "xdg-shell.h"
#include <wayland-client-protocol.h>
#include <wayland-util.h>

struct xdg_toplevel_listener XdgToplevel::m_listener = {
    .configure = toplevel_configure,
    .close = toplevel_close,
    .configure_bounds = toplevel_configure_bounds,
    .wm_capabilities = toplevel_wm_capabilities,
};

void XdgToplevel::resize(int width, int height) {
  if (width == 0 || height == 0)
    return;


  m_width = width;
  m_height = height;
}

void XdgToplevel::toplevel_configure_bounds(void *data,
                                            struct xdg_toplevel *xdg_toplevel,
                                            int32_t width, int32_t height) {}

void XdgToplevel::toplevel_wm_capabilities(void *data,
                                           struct xdg_toplevel *xdg_toplevel,
                                           struct wl_array *capabilities) {}

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

void XdgToplevel::setTitle(const std::string& title) {
  xdg_toplevel_set_title(m_toplevel, title.c_str());
}
XdgToplevel::XdgToplevel(PlatformWindow *win) : m_win(win) {
  m_width = m_win->getWidth();
  m_height = m_win->getHeight();
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
  m_win->setSize(m_width, m_height);
  xdg_surface_set_window_geometry(m_xdgSurface, 0, 0, m_width, m_height);
  flush();
}
