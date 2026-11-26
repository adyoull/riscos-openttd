#include "stdafx.h"
#include "gfx_type.h"
#include "debug.h"
#include "palette_func.h"
#include "core/bitmath_func.hpp"
DrawPixelInfo _screen;
int _debug_driver_level;
void DebugPrint(std::string_view, int, std::string &&) {}
bool HasCPUIDFlag(uint, uint, uint) { return true; }
/* ReallyAdjustBrightness, copied from palette.cpp by run.sh. */
#include "adjust_brightness.inc"
