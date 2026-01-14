cmake_minimum_required(VERSION 3.16)
project(online_store_exam)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)

# ===========================
# macOS + Homebrew fix (Apple Silicon)
# ===========================
if(APPLE)
    # Homebrew prefix (Apple Silicon)
    set(HOMEBREW_PREFIX "/opt/homebrew")

    # Force pkg-config from Homebrew (NOT system one)
    set(PKG_CONFIG_EXECUTABLE "${HOMEBREW_PREFIX}/bin/pkg-config")

    if(NOT EXISTS "${PKG_CONFIG_EXECUTABLE}")
        message(FATAL_ERROR "Homebrew pkg-config not found at: ${PKG_CONFIG_EXECUTABLE}")
    endif()

    # Crucial: libpqxx depends on libpq
    # libpq.pc is in /opt/homebrew/opt/libpq/lib/pkgconfig
    set(ENV{PKG_CONFIG_PATH}
            "${HOMEBREW_PREFIX}/opt/libpq/lib/pkgconfig:"
            "${HOMEBREW_PREFIX}/lib/pkgconfig:"
            "${HOMEBREW_PREFIX}/share/pkgconfig"
    )

    message(STATUS "PKG_CONFIG_EXECUTABLE = ${PKG_CONFIG_EXECUTABLE}")
    message(STATUS "PKG_CONFIG_PATH = $ENV{PKG_CONFIG_PATH}")
endif()

# ===========================
# Find libpqxx with pkg-config
# ===========================
find_package(PkgConfig REQUIRED)
pkg_check_modules(PQXX REQUIRED IMPORTED_TARGET libpqxx)

add_executable(online_store
        src/main.cpp
        src/StoreService.cpp
        src/User.cpp
        src/Admin.cpp
        src/Manager.cpp
        src/Customer.cpp
        src/Order.cpp
        include/CardPayment.h
        include/WalletPayment.h
        include/SBPPayment.h
        include/ReportService.h
        src/ReportService.cpp
)


# Link using imported target => fixes -L/-l issues on macOS
target_link_libraries(online_store PRIVATE PkgConfig::PQXX)
