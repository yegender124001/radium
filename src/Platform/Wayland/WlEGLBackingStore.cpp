#include "WlEGLBackingStore.h"

#include <EGL/egl.h>
#include <EGL/eglplatform.h>
#include <wayland-egl.h>

WlEGLBackingStore::WlEGLBackingStore(Surface *srfc, int width, int height) {
  m_app = App::getInstance();
  client = static_cast<Wayland *>(m_app->getPlatform());

  m_eglDisplay = client->eglDisplay();
  m_eglContext = client->eglContext();
  EGLConfig config = client->eglConfig();
  m_win = wl_egl_window_create(srfc->getSurface(), width, height);

  m_eglSurface = eglCreateWindowSurface(m_eglDisplay, config,
                                        (EGLNativeWindowType)m_win, nullptr);


}

void WlEGLBackingStore::makeCurrent() {
  eglMakeCurrent(m_eglDisplay, m_eglSurface, m_eglSurface, m_eglContext);
}

void WlEGLBackingStore::swapBuffers() {
  eglSwapBuffers(m_eglDisplay, m_eglSurface);
}

void WlEGLBackingStore::resize(int width, int height) {
  wl_egl_window_resize(m_win, width, height, 0, 0);
}

WlEGLBackingStore::~WlEGLBackingStore() {
  if (m_eglDisplay != EGL_NO_DISPLAY) {
    if (m_eglSurface != EGL_NO_SURFACE) {
      eglDestroySurface(m_eglDisplay, m_eglSurface);
    }
  }
  if (m_win) {
    wl_egl_window_destroy(m_win);
  }
}

WlBuffer *WlEGLBackingStore::getBuffer() {
  return nullptr;
}
