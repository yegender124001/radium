#include "Window.h"
#include "App.h"
#include "Platform/PlatformWindow.h"
#include "Platform/Wayland/WlWindow.h"

Window::Window():m_app(App::getInstance()) {
    m_app->createWindow(this);
    m_platformWindow = static_cast<PlatformWindow*>(new WlWindow());
}

void Window::show() {
    m_platformWindow->show();
}

bool Window::isVisible() const {
    return m_platformWindow->isVisible();
}

void Window::setSize(int width, int height) {
    m_platformWindow->setSize(width, height);
}

int Window::getWidth() const {
    return m_platformWindow->getWidth();
}

int Window::getHeight() const {
    return m_platformWindow->getHeight();
}

void Window::hide() {
    m_platformWindow->hide();
}

Window::~Window() {
    delete m_platformWindow;
}
