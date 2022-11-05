#ifndef CONFIG_H
#define CONFIG_H

#define MOD Mod4Mask
/*#define ROUND_CORNERS 20*/
#define BORDER_COLOR "#737373"
#define BORDER_WIDTH 3

const char* menu[]    = {"dmenu_run", "-b", "-x", "560", "-y", "20", "-z", "700", "-p", "VisoneRun:",      0};
const char *launchercmd[] = {"launcher", NULL };
const char *scratchpadcmd[] = {"sctpad", "float", 0}; 
const char *termcmd[]  = {"sctpad", "scratchpad",  0};
const char *urxcmd[] = {"sctpad", "rxvt", 0 };
const char *urxpmcmd[] = {"sctpad", "pulsemixer", 0};
const char *ffcmd[]          = { "sctpad", "firefox", 0}; 
const char* voldown[] = {"dwm-vol", "-",         0};
const char* volup[]   = {"dwm-vol", "+",         0};
const char* volmute[] = {"dwm-vol", "mute",      0};
const char *sessioncmd[]  = { "void-session", 0};
const char *fzfilmscmd[]  = { "term-launcher", "-f", 0};
const char *fztvshowcmd[] = { "term-launcher", "-t", 0};
const char *fzvarioscmd[] = { "term-launcher", "-v", 0};
const char *ssmcmd[]       = { "dwm-screenshoots", "-m", 0};
const char *sscmd[]       = { "dwm-screenshoots", "-s", 0};
const char *quitcmd[]	 = { "pkill",  "sowm",  0};


struct key keys[] = {
    {MOD,		XK_q,	    win_kill,   {0}},
    {MOD,		XK_c,	    win_center, {0}},
    {MOD,		XK_f,	    win_fs,     {0}},
    {MOD|ShiftMask,	XK_q,	    run, {.com = quitcmd}},

    {MOD,		XK_Up,	    win_half,  {.com = (const char*[]){"n"}}},
    {MOD,		XK_Down,    win_half,  {.com = (const char*[]){"s"}}},
    {MOD,		XK_Right,   win_half,  {.com = (const char*[]){"e"}}},
    {MOD,		XK_Left,    win_half,  {.com = (const char*[]){"w"}}},


    {Mod1Mask,		XK_Up,	    win_next,   {0}},
    {Mod1Mask,		XK_Down,    win_prev,   {0}},

    {MOD,		XK_d,      run, {.com = menu}},
    {Mod1Mask,		XK_d,      run, {.com = launchercmd}},
    {Mod1Mask,		XK_Return, run, {.com = scratchpadcmd}},
    {MOD|ShiftMask,	XK_Return, run, {.com = termcmd}},
    {MOD,		XK_Return, run, {.com = urxcmd}},
    {MOD,		XK_p,	   run, {.com = urxpmcmd}},
    {MOD,		XK_b,	   run, {.com = ffcmd}},
    {MOD,		XK_s,	   run, {.com = sessioncmd}},
    {0,			XK_Print,  run, {.com = sscmd}},
    {MOD,		XK_Print,  run, {.com = ssmcmd}},
    {Mod1Mask,		XK_1,	   run, {.com = fzfilmscmd}},
    {Mod1Mask,		XK_2,	   run, {.com = fztvshowcmd}},
    {Mod1Mask,		XK_3,	   run, {.com = fzvarioscmd}},


    {0,   XF86XK_AudioLowerVolume,  run, {.com = voldown}},
    {0,   XF86XK_AudioRaiseVolume,  run, {.com = volup}},
    {0,   XF86XK_AudioMute,         run, {.com = volmute}},

    {Mod1Mask,           XK_Right, ws_go,     {.i = +1}},
    {Mod1Mask,           XK_Left,  ws_go,     {.i = -1}},

    {MOD,           XK_1, ws_go,     {.i = 1}},
    {MOD|ShiftMask, XK_1, win_to_ws, {.i = 1}},
    {MOD,           XK_2, ws_go,     {.i = 2}},
    {MOD|ShiftMask, XK_2, win_to_ws, {.i = 2}},
    {MOD,           XK_3, ws_go,     {.i = 3}},
    {MOD|ShiftMask, XK_3, win_to_ws, {.i = 3}},
    {MOD,           XK_4, ws_go,     {.i = 4}},
    {MOD|ShiftMask, XK_4, win_to_ws, {.i = 4}},
    {MOD,           XK_5, ws_go,     {.i = 5}},
    {MOD|ShiftMask, XK_5, win_to_ws, {.i = 5}},
    {MOD,           XK_6, ws_go,     {.i = 6}},
    {MOD|ShiftMask, XK_6, win_to_ws, {.i = 6}},
};

#endif
