#pragma once
#include <vector>

class PlatformIntegration;
class Window;
class App {
public:
    static App* getInstance();
    void shutdown();
    void run();
    PlatformIntegration* getPlatform() { return m_platform; };
    void createWindow(Window*);
private:
    App();
    ~App();
    PlatformIntegration* m_platform;
    std::vector<Window*> m_windows;
};
