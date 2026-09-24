diff --git src/video/riscos/SDL_riscosvideo.c src/video/riscos/SDL_riscosvideo.c
index 4763011..ab8acac 100644
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
@@ -113,6 +116,7 @@ RISCOS_VideoInit(_THIS)
     if (RISCOS_InitModes(_this) < 0) {
         return -1;
     }
+    RISCOS_UpdateEigs(_this);
 
     /* We're done! */
     return 0;
@@ -122,6 +126,7 @@ static void
 RISCOS_VideoQuit(_THIS)
 {
     RISCOS_QuitEvents(_this);
+    RISCOS_WimpQuit(_this);
 }
 
 #endif /* SDL_VIDEO_DRIVER_RISCOS */
