diff --git src/video/riscos/SDL_riscosvideo.c src/video/riscos/SDL_riscosvideo.c
index 4763011..47dba94 100644
--- src/video/riscos/SDL_riscosvideo.c
+++ src/video/riscos/SDL_riscosvideo.c
@@ -83,6 +83,9 @@ RISCOS_CreateDevice(void)
 
     device->CreateSDLWindow = RISCOS_CreateWindow;
     device->DestroyWindow = RISCOS_DestroyWindow;
+    device->SetWindowSize = RISCOS_SetWindowSize;
+    device->SetWindowFullscreen = RISCOS_SetWindowFullscreen;
+    device->SetWindowTitle = RISCOS_SetWindowTitle;
     device->GetWindowWMInfo = RISCOS_GetWindowWMInfo;
 
     device->CreateWindowFramebuffer = RISCOS_CreateWindowFramebuffer;
@@ -113,6 +116,12 @@ RISCOS_VideoInit(_THIS)
     if (RISCOS_InitModes(_this) < 0) {
         return -1;
     }
+    RISCOS_UpdateEigs(_this);
+
+    /* 2026: become a Wimp task straight away (inside the desktop), so
+       every screen mode change, including starting full screen, goes
+       through Wimp_SetMode and the desktop is restored cleanly. */
+    RISCOS_WimpStart(_this);
 
     /* We're done! */
     return 0;
@@ -122,6 +131,7 @@ static void
 RISCOS_VideoQuit(_THIS)
 {
     RISCOS_QuitEvents(_this);
+    RISCOS_WimpQuit(_this);
 }
 
 #endif /* SDL_VIDEO_DRIVER_RISCOS */
