#pragma once

class PlatformIntegration {
public:
  PlatformIntegration();
  virtual ~PlatformIntegration();

  // virtual void createWindow(PlatformWindow*) = 0;

  virtual void dispatch() = 0;
};
