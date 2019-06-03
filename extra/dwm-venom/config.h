/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 0;        /* border pixel of windows */
static const unsigned int gappx     = 6;       /* gap pixel between windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;     /* 0 means no systray */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "Ohsnap:size=10","Siji:size=10" };
static const char dmenufont[]       = "Ohsnap:size=10";
static const char col_gray1[]       = "#171717";
static const char col_gray2[]       = "#040405";
static const char col_gray3[]       = "#676C76";
static const char col_gray4[]       = "#494949";
static const char col_cyan[]        = "#040405";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_gray1, col_cyan  },
};

/* tagging */
static const char *tags[] = { "term", "www", "fm", "edit", "media", "irc", "game", "dev", "misc" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class                instance    title             tags mask     isfloating  monitor */
	{ "Gimp",               NULL,       NULL,               0,          True,       -1 },
	{ "qutebrowser",        NULL,       NULL,               1 << 1,     False,      -1 },
	{ "Google-chrome",      NULL,       NULL,               1 << 1,     False,      -1 },
	{ "Firefox",            NULL,       NULL,               1 << 1,     False,      -1 },
	{ "Firefox",            "Dialog",   NULL,               1 << 1,     True,       -1 },
	{ "Thunar",             NULL,       NULL,               1 << 2,     False,      -1 },
	{ "Pcmanfm",            NULL,       NULL,               1 << 2,     False,      -1 },
	{ "Pcmanfm",            NULL,       "Execute File",     0,          True,       -1 },
	{ "Pcmanfm",            NULL,       "Copying files",    0,          True,       -1 },
	{ "Geany",              NULL,       NULL,               1 << 3,     False,      -1 },
	{ "Gcolor2",            NULL,       NULL,               0,          True,       -1 },
	{ "Hexchat",            NULL,       NULL,               1 << 5,     False,      -1 },
	{ "VirtualBox",         NULL,       NULL,               1 << 7,     False,      -1 },
	{ "VirtualBox",         NULL,      "Virtual Media Manager",  0,     True,       -1 },
	{ "Uget-gtk",           NULL,       NULL,               0,          True,       -1 },
	{ "Transmission-gtk",   NULL,       NULL,               0,          True,       -1 },
	{ "Gcolor2",            NULL,       NULL,               0,          True,       -1 },
	{ "Viewnior",           NULL,       NULL,               0,          True,       -1 },
	{ "Xarchiver",          NULL,       NULL,               0,          True,       -1 },
	{ "Qpdfview",           NULL,       NULL,               0,          True,       -1 },
	{ "Epdfview",           NULL,       NULL,               0,          True,       -1 },
	{ "Galculator",         NULL,       NULL,               0,          True,       -1 },
	{ "fontforge",          NULL,       NULL,               0,          True,       -1 },
	{ "Steam",              NULL,       NULL,               1 << 6,     True,       -1 },
	{ "st",                 NULL,       "alsamixer",        0,          True,       -1 },
	{ NULL,                 NULL,       "File Operation Progress", 0,   True,       -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int attachbelow = 1;    /* 1 means attach after the currently active window */

#include "fibonacci.c"
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "\uE002",      tile },    /* first entry is default */
	{ "\uE006",      NULL },    /* no layout function means floating behavior */
	{ "\uE000",      monocle },
	{ "\uE008",      spiral },
	{ "\uE007",      dwindle },
	{ NULL,          NULL },
};

#include <X11/XF86keysym.h>
#include "shiftview.c"

/* key definitions */
#define MODKEY Mod1Mask
#define SUPER Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_gray1, "-sf", col_gray4, NULL };
static const char *termcmd[]  = { "st", NULL };
static const char *qute[]     = { "qutebrowser", NULL };
static const char *www[]      = { "google-chrome-stable", NULL };
//static const char *www[]      = { "firefox", NULL };
static const char *fm[]       = { "pcmanfm", NULL };
//static const char *fm[]       = { "thunar", NULL };
static const char *rootfm[]   = { "sudo", "pcmanfm", "/", NULL };
//static const char *rootfm[]   = { "sudo", "thunar", "/", NULL };
static const char *gcolor2[]  = { "gcolor2", NULL };
static const char *geany[]    = { "geany", NULL };
static const char *vbox[]     = { "VirtualBox", NULL };
static const char *calc[]     = { "galculator", NULL };
static const char *nbwmon[]   = { "st", "-e", "nbwmon", NULL };
static const char *volup[]    = { "amixer", "-q", "set", "Master", "5%+", NULL };
static const char *voldw[]    = { "amixer", "-q", "set", "Master", "5%-", NULL };
static const char *volmute[]  = { "amixer", "-q", "set", "Master", "toggle", NULL };
static const char *lightup[]  = { "light", "-A", "5", NULL };
static const char *lightdw[]  = { "light", "-U", "5", NULL };
static const char *alsa[]     = { "st", "-e", "alsamixer", NULL };
static const char *offscr[]   = { "xset", "dpms", "force", "off", NULL };
static const char *mplay[]    = { "playerctl", "play-pause", NULL };
static const char *mnext[]    = { "playerctl", "next", NULL };
static const char *mprev[]    = { "playerctl", "previous", NULL };

static Key keys[] = {
	/* modifier                     key        function        argument */
	{ SUPER,                        XK_comma,  spawn,          {.v = mprev } },
	{ SUPER,                        XK_period, spawn,          {.v = mnext } },
	{ SUPER,                        XK_p,      spawn,          {.v = mplay } },
	{ SUPER,                        XK_o,      spawn,          {.v = offscr } },
	{ SUPER,                        XK_v,      spawn,          {.v = alsa } },
	{ SUPER,                        XK_Left,   spawn,          {.v = lightdw } },
	{ SUPER,                        XK_Right,  spawn,          {.v = lightup } },
	{ 0,                XF86XK_AudioPrev,      spawn,          {.v = mprev } },
	{ 0,                XF86XK_AudioPlay,      spawn,          {.v = mplay } },
	{ 0,                XF86XK_AudioNext,      spawn,          {.v = mnext } },
	{ 0,                XF86XK_AudioMute,      spawn,          {.v = volmute } },
	{ 0,         XF86XK_AudioLowerVolume,      spawn,          {.v = voldw } },
	{ 0,         XF86XK_AudioRaiseVolume,      spawn,          {.v = volup } },
	{ 0,                 XF86XK_PowerOff,      spawn,          {.v = offscr } },
	{ SUPER,                        XK_m,      spawn,          {.v = volmute } },
	{ SUPER,                        XK_Down,   spawn,          {.v = voldw } },
	{ SUPER,                        XK_Up,     spawn,          {.v = volup } },
	{ MODKEY,                       XK_v,      spawn,          {.v = vbox } },
	{ MODKEY,                       XK_n,      spawn,          {.v = nbwmon } },
	{ MODKEY,                       XK_e,      spawn,          {.v = geany } },
	{ MODKEY,                       XK_g,      spawn,          {.v = gcolor2 } },
	{ 0,               XF86XK_Calculator,      spawn,          {.v = calc } },
	{ MODKEY,                       XK_a,      spawn,          {.v = fm } },
	{ MODKEY|ShiftMask,             XK_a,      spawn,          {.v = rootfm } },
	{ MODKEY,                       XK_w,      spawn,          {.v = www } },
	{ MODKEY,                       XK_q,      spawn,          {.v = qute } },
	{ MODKEY,                       XK_p,      spawn,          {.v = dmenucmd } },
	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
	{ SUPER,                        XK_1,      setlayout,      {.v = &layouts[0]} },
	{ SUPER,                        XK_2,      setlayout,      {.v = &layouts[1]} },
	{ SUPER,                        XK_3,      setlayout,      {.v = &layouts[2]} },
	{ SUPER,                        XK_4,      setlayout,      {.v = &layouts[3]} },
	{ SUPER,                        XK_5,      setlayout,      {.v = &layouts[4]} },
	{ MODKEY,                       XK_Up,     cyclelayout,    {.i = -1 } },
	{ MODKEY,                       XK_Down,   cyclelayout,    {.i = +1 } },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	{ MODKEY,                       XK_Left,   shiftview,      {.i = -1 } },
	{ MODKEY,                       XK_Right,  shiftview,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Left,   tagtoleft,      {0} },
	{ MODKEY|ShiftMask,             XK_Right,  tagtoright,     {0} },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        cyclelayout,    {.i = -1 } },
	{ ClkLtSymbol,          0,              Button3,        cyclelayout,    {.i = +1 } },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkTagBar,            0,              Button4,        shiftview,      {.i = -1 } },
	{ ClkTagBar,            0,              Button5,        shiftview,      {.i = +1 } },
};

