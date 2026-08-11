#include "WlWindow.h"
#include "Platform/Wayland/Surface.h"
#include "Platform/Wayland/WlEGLBackingStore.h"
#include "Platform/Wayland/WlRasterBackingStore.h"

const int DEFAULT_WIDTH = 800;
const int DEFAULT_HEIGHT = 600;

WlWindow::WlWindow()
{
    m_title = "A wayland client";
    m_height = DEFAULT_HEIGHT;
    m_width = DEFAULT_WIDTH;
    m_backingStore = nullptr;
    m_toplevel = nullptr;
    m_visible = false;
}

void WlWindow::setSize(int width, int height)
{
    if (m_backingStore) {
        m_backingStore->resize(width, height);
    }

    if (m_toplevel) {
        m_toplevel->resize(width, height);
    }
    m_width = width;
    m_height = height;
}

void WlWindow::setTitle(const std::string& title)
{
    if (m_toplevel) {
        m_toplevel->setTitle(title);
    }
    m_title = title;
}

int WlWindow::getWidth() const
{
    return m_width;
}

int WlWindow::getHeight() const
{
    return m_height;
}


WlWindow::~WlWindow()
{
    destroyWindow();
    if (m_backingStore) {
        delete m_backingStore;
        m_backingStore = nullptr;
    }
}

void WlWindow::show()
{
    createWindow();
}

void WlWindow::hide()
{
    destroyWindow();
}

bool WlWindow::isVisible() const
{
    return m_visible;
}

void WlWindow::createWindow()
{
    m_toplevel = new XdgToplevel(this);
    m_backingStore = new WlEGLBackingStore(m_toplevel, m_width, m_height);
    // m_backingStore = new WlRasterBackingStore(m_width, m_height);
    m_backingStore->resize(m_width, m_height);
    m_toplevel->setBackingStore(m_backingStore);
    m_toplevel->setTitle(m_title);
    m_visible = true;
}

void WlWindow::destroyWindow()
{
    if (m_backingStore) {
        delete m_backingStore;
        m_backingStore = nullptr;
    }
    if (m_toplevel) {
        delete m_toplevel;
        m_toplevel = nullptr;
        m_visible = false;
    }
}
