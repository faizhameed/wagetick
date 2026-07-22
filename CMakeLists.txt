cmake_minimum_required(VERSION 3.21)
project(WageTick VERSION 1.3.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Homebrew installs Qt modules separately; use the cellar prefix so all
# components (qtbase + qtdeclarative + qtsvg) are visible to find_package.
if(APPLE)
    if(EXISTS "/opt/homebrew")
        list(PREPEND CMAKE_PREFIX_PATH "/opt/homebrew")
    elseif(EXISTS "/usr/local")
        list(PREPEND CMAKE_PREFIX_PATH "/usr/local")
    endif()
endif()

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Network
    Qml
    Quick
    QuickControls2
    QuickEffects
    Svg
)

qt_standard_project_setup(REQUIRES 6.5)

set(WAGETICK_SOURCES
    src/main.cpp
    src/WageTimer.cpp
    src/WageTimer.h
    src/UpdateChecker.cpp
    src/UpdateChecker.h
    resources.qrc
)

# macOS app icon (.icns → Contents/Resources + CFBundleIconFile)
set(WAGETICK_MAC_ICON "${CMAKE_CURRENT_SOURCE_DIR}/resources/AppIcon.icns")
if(APPLE AND EXISTS "${WAGETICK_MAC_ICON}")
    list(APPEND WAGETICK_SOURCES "${WAGETICK_MAC_ICON}")
    set_source_files_properties("${WAGETICK_MAC_ICON}" PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
endif()

qt_add_executable(WageTick ${WAGETICK_SOURCES})

target_include_directories(WageTick PRIVATE src)

target_compile_definitions(WageTick PRIVATE
    WAGETICK_VERSION="${PROJECT_VERSION}"
    WAGETICK_GITHUB_REPO="faizhameed/wagetick"
)

target_link_libraries(WageTick PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickEffects
    Qt6::Svg
)

if(APPLE)
    set_target_properties(WageTick PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "WageTick"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.wagetick.app"
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
        MACOSX_BUNDLE_LONG_VERSION_STRING ${PROJECT_VERSION}
        MACOSX_BUNDLE_INFO_STRING "Live wage timer — watch earnings tick every second"
        MACOSX_BUNDLE_COPYRIGHT "Copyright © WageTick contributors"
        MACOSX_BUNDLE_ICON_FILE "AppIcon.icns"
        OUTPUT_NAME "WageTick"
    )
endif()

# Ensure QML style/plugins are linked for a relocatable app
qt_import_qml_plugins(WageTick)

install(TARGETS WageTick
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)
