# this one is important
SET(CMAKE_SYSTEM_NAME GNU)
SET(CMAKE_USER_MAKE_RULES_OVERRIDE ${CMAKE_CURRENT_LIST_DIR}/riscos-overrides.cmake)
SET(RISCOS TRUE)
#this one not so much
SET(CMAKE_SYSTEM_VERSION 1)

SET(CMAKE_SYSTEM_PROCESSOR arm)

# specify the cross compiler
SET(CMAKE_C_COMPILER   $ENV{GCCSDK_INSTALL_ENV}/arm-riscos-gnueabihf-gcc)
SET(CMAKE_ASM_COMPILER   $ENV{GCCSDK_INSTALL_ENV}/arm-riscos-gnueabihf-gcc)
SET(CMAKE_CXX_COMPILER $ENV{GCCSDK_INSTALL_ENV}/arm-riscos-gnueabihf-g++)

# where is the target environment 
SET(CMAKE_FIND_ROOT_PATH  $ENV{GCCSDK_INSTALL_ENV})

# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

SET(ENV{PKG_CONFIG_LIBDIR} $ENV{GCCSDK_INSTALL_ENV}/lib/pkgconfig:$ENV{GCCSDK_INSTALL_ENV}/share/pkgconfig)
