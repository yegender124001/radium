#pragma once

class PlatformBackingStore {
public:
    PlatformBackingStore() = default;
    virtual ~PlatformBackingStore() = default;

    virtual void resize(int width, int height) = 0;
};
