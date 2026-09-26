diff --git src/video/riscos/SDL_riscosvideo.h src/video/riscos/SDL_riscosvideo.h
index db6c86e..e2e9ec6 100644
--- src/video/riscos/SDL_riscosvideo.h
+++ src/video/riscos/SDL_riscosvideo.h
@@ -31,8 +31,48 @@ typedef struct SDL_VideoData
 {
     int last_mouse_buttons;
     Uint8 key_pressed[RISCOS_MAX_KEYS_PRESSED];
+
+    /* 2026: windowed (Wimp) mode. Only one SDL window at a time can be a
+       desktop window (wimp_sdl_window); any other window is created full
+       screen, as the original driver did. Games only need one. */
+    int wimp_task;              /* task handle, or 0 if not a Wimp task */
+    int wimp_window;            /* Wimp window handle, or 0 in full screen (see RISCOS_IsWindowed) */
+    SDL_Window *wimp_sdl_window;
+    SDL_bool pointer_in;        /* pointer is over our window */
+    SDL_bool has_caret;         /* we have the input focus */
+    SDL_bool cursor_hidden;     /* SDL asked for the pointer to be hidden */
+    int buttons_inside;         /* buttons pressed while over our window */
+    int pending_clicks;         /* Mouse_Click buttons not yet reported (short clicks) */
+    int pending_click_x, pending_click_y;   /* where the last of them happened (OS units) */
+    int xeig, yeig;             /* cached eigen factors of the current mode */
+    int iconbar_icon;           /* icon bar icon handle, or -1 */
+    int wscale_x, wscale_y;     /* screen pixels per SDL pixel in a desktop window */
+    char window_title[128];     /* title bar text (the Wimp reads it from here) */
+    int wheel_x, wheel_y;       /* last OS_Pointer 2 wheel position */
+    SDL_bool wheel_valid;       /* wheel_x/y have been read at least once */
 } SDL_VideoData;
 
+/* 2026: SDL_TRUE when the program is running in a desktop window, SDL_FALSE
+   when it has the whole screen (single-tasking) or no window yet. */
+SDL_FORCE_INLINE SDL_bool
+RISCOS_IsWindowed(const SDL_VideoData *vdata)
+{
+    return (vdata->wimp_window != 0) ? SDL_TRUE : SDL_FALSE;
+}
+
+/* 2026: scale of a desktop window in screen pixels per SDL pixel: "1" never
+   scales, "2" to "4" always scale by that much; unset scales by 2 in high
+   resolution (EX0 EY0) modes. Can be set with SDL_SetHint or as the system
+   variable SDL_RISCOS_WINDOW_SCALE; SDL$WindowScale is still read if the
+   hint isn't set. */
+#define SDL_HINT_RISCOS_WINDOW_SCALE "SDL_RISCOS_WINDOW_SCALE"
+
+extern void RISCOS_ApplyPointerVisibility(_THIS);
+extern void RISCOS_WimpPlotWindow(_THIS, SDL_Window *window, int *block, int more);
+extern int RISCOS_WimpReadEig(int var);
+extern void RISCOS_UpdateEigs(_THIS);
+extern void RISCOS_ChooseWindowScale(_THIS, SDL_Window *window);
+
 #endif /* SDL_riscosvideo_h_ */
 
 /* vi: set ts=4 sw=4 expandtab: */
