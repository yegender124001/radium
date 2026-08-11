#pragma once

#include "Surface.h"

struct xdg_surface_listener;
class XdgSurface: public Surface {
public:
    XdgSurface();
    virtual ~XdgSurface() ;

protected:
    struct xdg_surface *m_xdgSurface;
    Wayland *m_platform;


    virtual void configure() = 0;

    static struct xdg_surface_listener m_listener;
    static void configure_xdg_srfc(void *data, struct xdg_surface *xdg_surface, uint32_t serial);
};
