#include "XdgSurface.h"
#include "App.h"
#include "xdg-shell.h"
#include "stdexcept"

struct xdg_surface_listener XdgSurface::m_listener = {
    .configure = configure_xdg_srfc,
};

void XdgSurface::configure_xdg_srfc(void *data, struct xdg_surface *xdg_surface, uint32_t serial) {
    auto *surface = static_cast<XdgSurface *>(data);
    xdg_surface_ack_configure(xdg_surface, serial);
    surface->configure();
}

XdgSurface::XdgSurface() {
    m_platform = static_cast<Wayland *>(App::getInstance()->getPlatform());
    m_xdgSurface = xdg_wm_base_get_xdg_surface(m_platform->base(), m_surface);
    if (m_xdgSurface == nullptr) {
        throw std::runtime_error("Failed to get xdg surface");
    }
    xdg_surface_add_listener(m_xdgSurface, &m_listener, this);
}

XdgSurface::~XdgSurface() {
    if (m_xdgSurface)
        xdg_surface_destroy(m_xdgSurface);
}
