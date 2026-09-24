diff --git src/video/riscos/SDL_riscoswindow.h src/video/riscos/SDL_riscoswindow.h
index d713b7a..a0c4eee 100644
--- src/video/riscos/SDL_riscoswindow.h
+++ src/video/riscos/SDL_riscoswindow.h
@@ -30,10 +30,16 @@ typedef struct
     SDL_Window *window;
     sprite_area *fb_area;
     sprite_header *fb_sprite;
+    int fb_direct;              /* 2026: framebuffer is the screen itself */
 } SDL_WindowData;
 
 extern int RISCOS_CreateWindow(_THIS, SDL_Window * window);
 extern void RISCOS_DestroyWindow(_THIS, SDL_Window * window);
+extern void RISCOS_SetWindowSize(_THIS, SDL_Window * window);
+extern void RISCOS_SetWindowFullscreen(_THIS, SDL_Window * window, SDL_VideoDisplay * display, SDL_bool fullscreen);
+extern void RISCOS_SetWindowTitle(_THIS, SDL_Window * window);
+extern void RISCOS_WimpQuit(_THIS);
+extern int RISCOS_WimpStart(_THIS);
 extern SDL_bool RISCOS_GetWindowWMInfo(_THIS, SDL_Window * window,
                                     struct SDL_SysWMinfo *info);
 
