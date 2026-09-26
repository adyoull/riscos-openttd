#include "stdafx.h"
#include "gfx_type.h"
#include "debug.h"
DrawPixelInfo _screen;
int _debug_driver_level;
void DebugPrint(const char *, int, const std::string &) {}
bool HasCPUIDFlag(uint, uint, uint) { return true; }
