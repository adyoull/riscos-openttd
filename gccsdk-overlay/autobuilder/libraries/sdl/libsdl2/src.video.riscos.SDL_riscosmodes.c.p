diff --git src/video/riscos/SDL_riscosmodes.c src/video/riscos/SDL_riscosmodes.c
index 9500b22..8666e96 100644
--- src/video/riscos/SDL_riscosmodes.c
+++ src/video/riscos/SDL_riscosmodes.c
@@ -308,6 +308,8 @@ RISCOS_SetDisplayMode(_THIS, SDL_VideoDisplay * display, SDL_DisplayMode * mode)
     /* Update cursor visibility, since it may have been disabled by the mode change. */
     SDL_SetCursor(NULL);
 
+    RISCOS_UpdateEigs(_this);
+
     return 0;
 }
 
