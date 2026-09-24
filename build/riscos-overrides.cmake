# RISC OS (GCCSDK) has no -rdynamic and threads live in UnixLib's libc.
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
