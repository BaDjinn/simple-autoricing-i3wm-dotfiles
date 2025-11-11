static const char norm_fg[] = "#c1a99f";
static const char norm_bg[] = "#0c1412";
static const char norm_border[] = "#87766f";

static const char sel_fg[] = "#c1a99f";
static const char sel_bg[] = "#4F3C45";
static const char sel_border[] = "#c1a99f";

static const char urg_fg[] = "#c1a99f";
static const char urg_bg[] = "#273C43";
static const char urg_border[] = "#273C43";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
