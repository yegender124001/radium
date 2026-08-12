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
    m_toplevel = std::make_unique<XdgToplevel>(this);
    m_backingStore = std::make_unique<WlEGLBackingStore>(m_toplevel.get(), m_width, m_height);
    m_toplevel->setBackingStore(m_backingStore.get());
    m_toplevel->setTitle(m_title);
    m_visible = true;
}

void WlWindow::destroyWindow()
{
    m_visible = false;
    m_backingStore.reset();
    m_toplevel.reset();
}
