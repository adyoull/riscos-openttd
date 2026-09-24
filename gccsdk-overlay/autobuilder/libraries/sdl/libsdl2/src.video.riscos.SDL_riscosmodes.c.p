diff --git src/video/riscos/SDL_riscosmodes.c src/video/riscos/SDL_riscosmodes.c
index 9500b22..76d1ee3 100644
--- src/video/riscos/SDL_riscosmodes.c
+++ src/video/riscos/SDL_riscosmodes.c
@@ -293,9 +293,17 @@ RISCOS_SetDisplayMode(_THIS, SDL_VideoDisplay * display, SDL_DisplayMode * mode)
     _kernel_oserror *error;
     int i;
 
-    regs.r[0] = 0;
-    regs.r[1] = (int)mode->driverdata;
-    error = _kernel_swi(OS_ScreenMode, &regs, &regs);
+    if (((SDL_VideoData *) _this->driverdata)->wimp_task != 0) {
+        /* 2026: a Wimp task must change mode through the Wimp, so that the
+           desktop and the other tasks know about it and are redrawn
+           properly when we return to the desktop. */
+        regs.r[0] = (int)mode->driverdata;
+        error = _kernel_swi(Wimp_SetMode, &regs, &regs);
+    } else {
+        regs.r[0] = 0;
+        regs.r[1] = (int)mode->driverdata;
+        error = _kernel_swi(OS_ScreenMode, &regs, &regs);
+    }
     if (error != NULL) {
         return SDL_SetError("Unable to set the current screen mode: %s (%i)", error->errmess, error->errnum);
     }
@@ -308,6 +316,8 @@ RISCOS_SetDisplayMode(_THIS, SDL_VideoDisplay * display, SDL_DisplayMode * mode)
     /* Update cursor visibility, since it may have been disabled by the mode change. */
     SDL_SetCursor(NULL);
 
+    RISCOS_UpdateEigs(_this);
+
     return 0;
 }
 
