#let dark = (
  base    : white.darken(90%),
  surface : orange.lighten(92%),
  overlay : color.hsl(184deg, 23%, 94%),
  muted   : silver,
  subtle  : gray,
  text    : white,
  love    : red,
  gold    : orange,
  rose    : purple,
  pine    : purple,
  foam    : teal,
  iris    : maroon,
  highlight : (
    low     : green.desaturate(50%),
    med     : yellow.desaturate(50%),
    high    : red.desaturate(50%),
  )
)

#let theme = dark
