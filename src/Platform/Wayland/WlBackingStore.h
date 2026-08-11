#pragma once

#include "../PlatformBackingStore.h"

struct WlBuffer {
    struct wl_buffer *buffer;
    bool isReleased;
    bool destroyMe;
    int width;
    int height;
};
class WlBackingStore: public PlatformBackingStore {
public:
    WlBackingStore() = default;
    virtual ~WlBackingStore() = default;

    virtual void resize(int width, int height) = 0;
    virtual WlBuffer* getBuffer() = 0;
};
