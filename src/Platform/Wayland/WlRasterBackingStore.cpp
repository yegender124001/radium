#include "WlRasterBackingStore.h"
#include "Platform/Wayland/Wayland.h"
#include <App.h>
#include <cstdint>
#include <fcntl.h>
#include <limits>
#include <stdexcept>
#include <sys/mman.h>
#include <unistd.h>
#include <wayland-client-protocol.h>
#include <wayland-client.h>

const int BUFFERS = 2;

namespace {
size_t bufferSize(int width, int height) {
  return static_cast<size_t>(width) * static_cast<size_t>(height) * 4u;
}

size_t checkedPoolSize(int width, int height) {
  if (width <= 0 || height <= 0) {
    throw std::invalid_argument("WlRasterBackingStore: invalid dimensions");
  }
  const size_t pool = bufferSize(width, height) * BUFFERS;
  if (pool > static_cast<size_t>(std::numeric_limits<int32_t>::max())) {
    throw std::overflow_error("WlRasterBackingStore: size exceeds protocol limit");
  }
  return pool;
}
}

void buffer_release(void *data, struct wl_buffer *buffer) {
    WlRasterBuffer *wlbuffer = static_cast<WlRasterBuffer*>(data);
    wlbuffer->isReleased = true;

    if (wlbuffer->destroyMe) {
        delete wlbuffer;
    }
}

static struct wl_buffer_listener buffer_listener = {
    .release = buffer_release,
};

WlBuffer* WlRasterBackingStore::getBuffer() {
    for (auto buffer : buffers) {
        if (buffer->isReleased) {
            buffer->isReleased = false;
            return buffer;
        }
    }
    return nullptr;
}

WlRasterBackingStore::~WlRasterBackingStore() {
    clearBuffers();
    unmap();
    if (pool)
        wl_shm_pool_destroy(pool);
    if (fd >= 0)
        close(fd);
}

WlRasterBackingStore::WlRasterBackingStore(int width, int height):m_width(width), m_height(height) {
    App *app = App::getInstance();
    Wayland *waylandClient = static_cast<Wayland*>(app->getPlatform());
    shm = waylandClient->shm();

    maxSize = checkedPoolSize(width, height);

    fd = memfd_create("radium-client",0);
    if (fd < 0) {
        throw std::runtime_error("Failed to create memfd for radium client");
    }

    if (ftruncate(fd, static_cast<off_t>(maxSize)) != 0) {
        close(fd);
        fd = -1;
        throw std::runtime_error("Failed to size shm fd");
    }
    pool = wl_shm_create_pool(shm, fd, static_cast<int32_t>(maxSize));

    map();
    createBuffers(width, height);
}

void WlRasterBackingStore::map() {
    m_data = mmap(nullptr, maxSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (m_data == MAP_FAILED) {
        m_data = nullptr;
        throw std::runtime_error("Failed to mmap shm region");
    }
    mappedSize = maxSize;
}

void WlRasterBackingStore::unmap() {
    if (m_data != nullptr) {
        munmap(m_data, mappedSize);
        m_data = nullptr;
        mappedSize = 0;
    }
}

void WlRasterBackingStore::createBuffers(int width, int height) {
    const size_t size = bufferSize(width, height);
    buffers.reserve(BUFFERS);

    for (int i = 0; i < BUFFERS; i++) {
        struct wl_buffer *buffer = wl_shm_pool_create_buffer(
            pool,
            static_cast<int32_t>(i * size),
            width,
            height,
            static_cast<int32_t>(width * 4),
            WL_SHM_FORMAT_ARGB8888
        );
        if (buffer == nullptr) {
            throw std::runtime_error("Failed to create wl_shm buffer");
        }

        uint8_t* ptr = static_cast<uint8_t*>(m_data) + i * size;

        auto wlbuffer = new WlRasterBuffer;
        wlbuffer->data = ptr;
        wlbuffer->size = size;
        wlbuffer->isReleased = true;
        wlbuffer->destroyMe = false;
        wlbuffer->width = width;
        wlbuffer->height = height;
        wlbuffer->buffer = buffer;

        wl_buffer_add_listener(buffer, &buffer_listener, wlbuffer);

        buffers.push_back(wlbuffer);
    }
}

void WlRasterBackingStore::present(struct wl_surface *surface) {
    WlBuffer *buff = getBuffer();
    if (buff != nullptr) {
        wl_surface_attach(surface, buff->buffer, 0, 0);
        wl_surface_damage_buffer(surface, 0, 0, buff->width, buff->height);
        wl_surface_commit(surface);
    }
}

void WlRasterBackingStore::clearBuffers() {
    for (auto &wlbuffer : buffers) {
        if (wlbuffer->isReleased) {
            wl_buffer_destroy(wlbuffer->buffer);
            delete wlbuffer;
        } else {
            wlbuffer->destroyMe = true;
        }
    }
    buffers.clear();
}

void WlRasterBackingStore::resize(int width, int height) {
    if (width == 0 || height == 0) return;

    if (width == m_width && height == m_height) {
        return;
    }

    const size_t newSize = checkedPoolSize(width, height);

    if (newSize > maxSize) {
        if (ftruncate(fd, static_cast<off_t>(newSize)) != 0) {
            throw std::runtime_error("Failed to resize shm fd");
        }
        wl_shm_pool_resize(pool, static_cast<int32_t>(newSize));
        unmap();
        maxSize = newSize;
        map();
    }

    clearBuffers();

    createBuffers(width, height);

    m_width = width;
    m_height = height;
}
