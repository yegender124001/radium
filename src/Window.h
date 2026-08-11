#pragma once

class PlatformWindow;
class App;
class Window {
public:
    Window();
    ~Window();

    void show();
    void hide();
    bool isVisible() const;

    void setSize(int width, int height);
    int getWidth() const;
    int getHeight() const;


private:
    PlatformWindow* m_platformWindow = nullptr;
    App* m_app;
};
