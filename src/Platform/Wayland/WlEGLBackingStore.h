#pragma once

#include "Platform/Wayland/Surface.h"
#include "Platform/Wayland/Wayland.h"
#include "WlBackingStore.h"
#include <wayland-egl-core.h>
#include <EGL/egl.h>
#include "App.h"


class WlEGLBackingStore : public WlBackingStore {
public:
    WlEGLBackingStore(Surface *srfc, int width, int height);
    ~WlEGLBackingStore();

    void resize(int width, int height) override;
    WlBuffer* getBuffer() override;
    void present(struct wl_surface *surface) override;
    void swapBuffers();
    void makeCurrent();

    protected:
        EGLDisplay m_eglDisplay;
        EGLSurface m_eglSurface;
        EGLContext m_eglContext;
        int m_width;
        int m_height;
        App* m_app;
        Wayland* client;
        struct wl_egl_window* m_win;
};
