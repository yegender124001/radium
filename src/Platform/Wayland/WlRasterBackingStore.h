#pragma once

#include "WlBackingStore.h"
#include <cstddef>
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
  void present(struct wl_surface *surface) override;

  WlBuffer* getBuffer() override;
protected:
  struct wl_shm *shm = nullptr;
  struct wl_shm_pool *pool = nullptr;
  std::vector<WlRasterBuffer*> buffers;

  int m_width = 0;
  int m_height = 0;

  int fd = -1;
  size_t maxSize = 0;
  void *m_data = nullptr;
  size_t mappedSize = 0;

  void clearBuffers();
  void createBuffers(int width, int height);
  void map();
  void unmap();
};
