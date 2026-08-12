#include "Wayland.h"
#include "linux-dmabuf-unstable-v1.h"
#include "xdg-shell.h"
#include <cassert>
#include <cstring>
#include <stdexcept>
#include <wayland-client-core.h>
#include <wayland-client-protocol.h>

void Wayland::dispatch() { wl_display_dispatch(m_display); }

namespace {
uint32_t clampVersion(uint32_t offered, uint32_t supported) {
  return offered < supported ? offered : supported;
}
}

struct xdg_wm_base_listener Wayland::base_listener = {
    .ping = Wayland::xdg_wm_base_ping,
};

void Wayland::xdg_wm_base_ping(void *data, struct xdg_wm_base *base,
                               uint32_t serial) {
  xdg_wm_base_pong(base, serial);
}

struct wl_registry_listener Wayland::reg_listener = {
    .global = Wayland::registry_global,
    .global_remove = Wayland::registry_remove,
};

void Wayland::registry_global(void *data, struct wl_registry *registry,
                              uint32_t name, const char *interface,
                              uint32_t version) {
  Wayland *wayland = static_cast<Wayland *>(data);
  if (strcmp(interface, "wl_compositor") == 0) {
    wayland->m_compositor = static_cast<struct wl_compositor *>(
        wl_registry_bind(registry, name, &wl_compositor_interface,
                         clampVersion(version, 1)));
  }
  if (strcmp(interface, "wl_shm") == 0) {
    wayland->m_shm = static_cast<struct wl_shm *>(
        wl_registry_bind(registry, name, &wl_shm_interface,
                         clampVersion(version, 1)));
  }
  if (strcmp(interface, zwp_linux_dmabuf_v1_interface.name) == 0) {
    wayland->m_dmabuf =
        static_cast<struct zwp_linux_dmabuf_v1 *>(wl_registry_bind(
            registry, name, &zwp_linux_dmabuf_v1_interface,
            clampVersion(version, 1)));
  }
  if (strcmp(interface, xdg_wm_base_interface.name) == 0) {
    wayland->m_base = static_cast<struct xdg_wm_base *>(
        wl_registry_bind(registry, name, &xdg_wm_base_interface,
                         clampVersion(version, 1)));
    xdg_wm_base_add_listener(wayland->m_base, &Wayland::base_listener, wayland);
  }
  if (strcmp(interface, zxdg_decoration_manager_v1_interface.name) == 0) {
    wayland->m_decoration =
        static_cast<struct zxdg_decoration_manager_v1 *>(wl_registry_bind(
            registry, name, &zxdg_decoration_manager_v1_interface,
            clampVersion(version, 1)));
  }
  if (strcmp(interface, wp_fractional_scale_manager_v1_interface.name) == 0) {
    wayland->m_fractional_scale =
        static_cast<struct wp_fractional_scale_manager_v1 *>(wl_registry_bind(
            registry, name, &wp_fractional_scale_manager_v1_interface,
            clampVersion(version, 1)));
  }
  if (strcmp(interface, wp_viewporter_interface.name) == 0) {
    wayland->m_viewporter = static_cast<struct wp_viewporter *>(
        wl_registry_bind(registry, name, &wp_viewporter_interface,
                         clampVersion(version, 1)));
  }
  if (strcmp(interface, zwlr_layer_shell_v1_interface.name) == 0) {
    wayland->m_layer_shell =
        static_cast<struct zwlr_layer_shell_v1 *>(wl_registry_bind(
            registry, name, &zwlr_layer_shell_v1_interface,
            clampVersion(version, 1)));
  }
}

void Wayland::registry_remove(void *data, struct wl_registry *registry,
                              uint32_t name) {}

Wayland::Wayland() {
  m_display = wl_display_connect(nullptr);
  if (m_display == nullptr) {
    throw std::runtime_error("Failed to connect to Wayland display");
  }

  m_registry = wl_display_get_registry(m_display);
  if (m_registry == nullptr) {
    throw std::runtime_error("Failed to get Wayland registry");
  }

  wl_registry_add_listener(m_registry, &reg_listener, this);
  wl_display_roundtrip(m_display);

  initEGL();
}

void Wayland::initEGL() {
  m_eglDisplay = eglGetDisplay(m_display);
  assert(m_eglDisplay != EGL_NO_DISPLAY && "Failed to get EGL display");

  EGLint major, minor;
  if (!eglInitialize(m_eglDisplay, &major, &minor)) {
    assert(false && "Failed to initialize EGL");
  }

  const EGLint configAttribs[] = {
      EGL_SURFACE_TYPE,
      EGL_WINDOW_BIT,
      EGL_RED_SIZE,
      8,
      EGL_GREEN_SIZE,
      8,
      EGL_BLUE_SIZE,
      8,
      EGL_ALPHA_SIZE,
      8,
      EGL_RENDERABLE_TYPE,
      EGL_OPENGL_ES2_BIT,
      EGL_NONE,
  };

  EGLint numConfigs;
  if (!eglChooseConfig(m_eglDisplay, configAttribs, &m_eglConfig, 1,
                       &numConfigs) ||
      numConfigs == 0) {
    assert(false && "Failed to choose EGL config");
  }

  const EGLint contextAttribs[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      2,
      EGL_NONE,
  };

  m_eglContext = eglCreateContext(m_eglDisplay, m_eglConfig, EGL_NO_CONTEXT,
                                  contextAttribs);
  assert(m_eglContext != EGL_NO_CONTEXT && "Failed to create EGL context");
}

void Wayland::deinitEGL() {
  if (m_eglDisplay != EGL_NO_DISPLAY) {
    eglMakeCurrent(m_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE,
                   EGL_NO_CONTEXT);
    if (m_eglContext != EGL_NO_CONTEXT) {
      eglDestroyContext(m_eglDisplay, m_eglContext);
    }
    eglTerminate(m_eglDisplay);
  }
}

Wayland::~Wayland() {
  deinitEGL();
  if (m_layer_shell)
    zwlr_layer_shell_v1_destroy(m_layer_shell);
  if (m_fractional_scale)
    wp_fractional_scale_manager_v1_destroy(m_fractional_scale);
  if (m_decoration)
    zxdg_decoration_manager_v1_destroy(m_decoration);
  if (m_base)
    xdg_wm_base_destroy(m_base);
  if (m_viewporter)
    wp_viewporter_destroy(m_viewporter);
  if (m_dmabuf)
    zwp_linux_dmabuf_v1_destroy(m_dmabuf);
  if (m_shm)
    wl_shm_destroy(m_shm);
  if (m_compositor)
    wl_compositor_destroy(m_compositor);
  if (m_registry)
    wl_registry_destroy(m_registry);
  if (m_display)
    wl_display_disconnect(m_display);
}

// void WaylandPlatform::createWindow(PlatformWindow* window) {

// }
