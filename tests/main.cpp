#include <App.h>
#include <Window.h>

int main() {
    App* app = App::getInstance();

    Window window;

    window.show();

    app->run();
    app->shutdown();
    return 0;
}
