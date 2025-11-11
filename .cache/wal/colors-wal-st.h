const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0c1412", /* black   */
  [1] = "#273C43", /* red     */
  [2] = "#4F3C45", /* green   */
  [3] = "#12515A", /* yellow  */
  [4] = "#35494B", /* blue    */
  [5] = "#4B504C", /* magenta */
  [6] = "#686056", /* cyan    */
  [7] = "#c1a99f", /* white   */

  /* 8 bright colors */
  [8]  = "#87766f",  /* black   */
  [9]  = "#273C43",  /* red     */
  [10] = "#4F3C45", /* green   */
  [11] = "#12515A", /* yellow  */
  [12] = "#35494B", /* blue    */
  [13] = "#4B504C", /* magenta */
  [14] = "#686056", /* cyan    */
  [15] = "#c1a99f", /* white   */

  /* special colors */
  [256] = "#0c1412", /* background */
  [257] = "#c1a99f", /* foreground */
  [258] = "#c1a99f",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
