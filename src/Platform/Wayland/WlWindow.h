#pragma once

#include "../PlatformWindow.h"
#include "XdgToplevel.h"
#include "WlRasterBackingStore.h"


class WlWindow : public PlatformWindow
{
public:
    WlWindow();
    ~WlWindow() override;

    void show() override;
    void hide() override;
    bool isVisible() const override;
    void setTitle(const std::string& title) override;
    void setSize(int width, int height) override;
    int getWidth() const override;
    int getHeight() const override;

private:
    int m_width;
    int m_height;
    XdgToplevel *m_toplevel;
    WlRasterBackingStore *m_backingStore;
    bool m_visible;
    std::string m_title;

    void createWindow();
    void destroyWindow();
};
