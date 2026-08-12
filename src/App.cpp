#include "App.h"
#include "Platform/Wayland/Wayland.h"
#include "Window.h"
#include <algorithm>

App::App() {
    m_platform = static_cast<PlatformIntegration*>(new Wayland());
}

App::~App() {
    delete m_platform;
}

App* App::getInstance() {
    static App instance;
    return &instance;
}

void App::createWindow(Window* window) {
    m_windows.push_back(window);
}

void App::destroyWindow(Window* window) {
    auto it = std::find(m_windows.begin(), m_windows.end(), window);
    if (it != m_windows.end()) {
        m_windows.erase(it);
    }
}

void App::shutdown() {
}

void App::run() {
    int shownWindows = 0;
    while (true) {
        shownWindows = 0;
        for (Window* window : m_windows) {
            if (window->isVisible()) {
                shownWindows++;
            }
        }
        if (shownWindows == 0) {
            break;
        }
        m_platform->dispatch();
    }

}
