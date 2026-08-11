#include "Surface.h"
#include "App.h"
#include "Platform/Wayland/Wayland.h"
#include "Platform/Wayland/WlBackingStore.h"
#include <stdexcept>

Surface::Surface() {
    m_platform = static_cast<Wayland *>(App::getInstance()->getPlatform());
    m_surface = wl_compositor_create_surface(m_platform->compositor());
    if (m_surface == nullptr) {
        throw std::runtime_error("Failed to create surface");
    }
}

Surface::~Surface() {
    if (m_surface) {
        wl_surface_destroy(m_surface);
    }
}

void Surface::setBackingStore(WlBackingStore *backingStore) {
    m_backingStore = backingStore;
}

void Surface::flush() {
    WlBuffer* buff = m_backingStore->getBuffer();
    wl_surface_attach(m_surface, buff->buffer, 0, 0);
    wl_surface_damage_buffer(m_surface, 0, 0, buff->width, buff->height);
    wl_surface_commit(m_surface);
}
