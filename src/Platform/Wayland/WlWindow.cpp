#include "WlWindow.h"

const int DEFAULT_WIDTH = 800;
const int DEFAULT_HEIGHT = 600;

WlWindow::WlWindow()
{
    m_backingStore = new WlRasterBackingStore(DEFAULT_WIDTH, DEFAULT_HEIGHT);
    m_toplevel = nullptr;
    m_visible = false;
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
    m_toplevel->setBackingStore(m_backingStore);
    m_visible = true;
}

void WlWindow::destroyWindow()
{
    if (m_toplevel) {
        delete m_toplevel;
        m_toplevel = nullptr;
        m_visible = false;
    }
}
