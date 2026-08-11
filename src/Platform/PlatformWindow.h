#pragma once

class PlatformWindow {
public:
  PlatformWindow() = default;
  virtual ~PlatformWindow() = default;

  virtual void show() = 0;
  virtual void hide() = 0;
  virtual bool isVisible() const = 0;
  // virtual void setTitle(const std::string& title) = 0;
  // virtual void setSize(int width, int height) = 0;
};
