#include "osx_platform.h"

int main(int argc, char** argv)
{
    OSX_App app = osx_create_app();
    OSX_Window window = osx_create_window(app);

    while (!osx_window_closing(window))
    {
        osx_pump_events();
    }

    osx_destroy_window(window);
    osx_destroy_app(app);

    return 0;
}