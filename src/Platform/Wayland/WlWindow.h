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
    // void setTitle(const std::string& title) override;
    // void setSize(int width, int height) override;
private:
    XdgToplevel *m_toplevel;
    WlRasterBackingStore *m_backingStore;
    bool m_visible;

    void createWindow();
    void destroyWindow();
};
