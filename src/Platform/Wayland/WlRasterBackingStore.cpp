#include "WlRasterBackingStore.h"
#include "Platform/Wayland/Wayland.h"
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <wayland-client-protocol.h>
#include <wayland-client.h>
#include <App.h>

const int BUFFERS = 2;

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
    wl_shm_pool_destroy(pool);
    close(fd);
}

WlRasterBackingStore::WlRasterBackingStore(int width, int height):m_width(width), m_height(height) {
    App *app = App::getInstance();
    Wayland *waylandClient = static_cast<Wayland*>(app->getPlatform());
    shm = waylandClient->shm();

    fd = memfd_create("radium-client",0);

    maxSize = width * height * 4 * BUFFERS;
    ftruncate(fd, maxSize);
    pool = wl_shm_create_pool(shm, fd, maxSize);

    createBuffers(width, height);

}

void WlRasterBackingStore::createBuffers(int width, int height) {
    buffers.reserve(BUFFERS);

    for (int i = 0; i < BUFFERS; i++) {
        struct wl_buffer *buffer = wl_shm_pool_create_buffer(
            pool,
            i * width * height * 4,
            width,
            height,
            width * 4,
            WL_SHM_FORMAT_ARGB8888
        );

        uint8_t* ptr = static_cast<uint8_t*>(mmap(nullptr, width * height * 4, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0));
        ptr += i * width * height * 4;

        auto wlbuffer = new WlRasterBuffer;
        wlbuffer->data = ptr;
        wlbuffer->isReleased = true;
        wlbuffer->destroyMe = false;
        wlbuffer->width = width;
        wlbuffer->height = height;
        wlbuffer->buffer = buffer;

        wl_buffer_add_listener(buffer, &buffer_listener, wlbuffer);

        buffers.push_back(wlbuffer);
    }
}

void WlRasterBackingStore::clearBuffers() {
    for (auto &wlbuffer : buffers) {
        if (wlbuffer->isReleased) {
            wl_buffer_destroy(wlbuffer->buffer);
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

    const int newSize = width * height * 4 * BUFFERS;

    if (newSize > maxSize) {
        ftruncate(fd, newSize);
        wl_shm_pool_resize(pool, newSize);
        maxSize = newSize;
    }

    clearBuffers();

    createBuffers(width, height);
}
