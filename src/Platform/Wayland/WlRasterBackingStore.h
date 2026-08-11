#pragma once

#include "WlBackingStore.h"
#include <wayland-client.h>
#include <vector>

struct WlRasterBuffer: public WlBuffer {
    void *data;
    size_t size;
};

class WlRasterBackingStore : public WlBackingStore {
public:
  WlRasterBackingStore(int width, int height);
  WlRasterBackingStore() = default;
  ~WlRasterBackingStore() override;

  void resize(int width, int height) override;

  WlBuffer* getBuffer() override;
protected:
  struct wl_shm *shm = nullptr;
  struct wl_shm_pool *pool = nullptr;
  std::vector<WlRasterBuffer*> buffers;

  int m_width;
  int m_height;

  int fd;
  int maxSize;

  void clearBuffers();
  void createBuffers(int width, int height);
};
