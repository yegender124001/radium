#pragma once

#include "Platform/PlatformIntegration.h"
#include "linux-dmabuf-unstable-v1.h"
#include "xdg-shell.h"
#include "xdg-decoration-unstable-v1.h"
#include "fractional-scale-v1.h"
#include "viewporter.h"
#include "wlr-layer-shell-unstable-v1.h"
#include <wayland-client-protocol.h>

class Wayland : public PlatformIntegration {
public:
    Wayland();
    ~Wayland() override;

    struct wl_display* display() const { return m_display; }
    struct wl_registry* registry() const { return m_registry; }
    struct wl_compositor* compositor() const { return m_compositor; }
    struct wl_shm* shm() const { return m_shm; }
    struct zwp_linux_dmabuf_v1* dmabuf() const { return m_dmabuf; }
    struct xdg_wm_base* base() const { return m_base; }
    struct zxdg_decoration_manager_v1* decoration() const { return m_decoration; }
    struct wp_fractional_scale_manager_v1* fractional_scale() const { return m_fractional_scale; }
    struct wp_viewporter* viewporter() const { return m_viewporter; }
    struct zwlr_layer_shell_v1* layer_shell() const { return m_layer_shell; }

    void dispatch() override;
private:
    struct wl_display* m_display;
    struct wl_registry* m_registry;
    struct wl_compositor* m_compositor;
    struct wl_shm* m_shm;
    struct zwp_linux_dmabuf_v1* m_dmabuf;
    struct xdg_wm_base* m_base;
    struct zxdg_decoration_manager_v1* m_decoration;
    struct wp_fractional_scale_manager_v1* m_fractional_scale;
    struct wp_viewporter* m_viewporter;
    struct zwlr_layer_shell_v1* m_layer_shell;

    static void registry_global(void* data, struct wl_registry* registry, uint32_t name, const char* interface, uint32_t version);
    static void registry_remove(void* data, struct wl_registry* registry, uint32_t name);
    static struct wl_registry_listener reg_listener;

    static void xdg_wm_base_ping(void* data, struct xdg_wm_base* base, uint32_t serial);
    static struct xdg_wm_base_listener base_listener;

};
