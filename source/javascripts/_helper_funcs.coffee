Number::toUcs2 = ->
  if 0 <= @ <= 0xFFFD
    String.fromCharCode @
  else if 0xFFFF < @ <= 0x10FFFD
    down = @ - 0x10000
    hs = 0xD800 + (down >> 0xA)
    ls = 0xDC00 + (down & 0x3FF)
    "#{String.fromCharCode hs}#{String.fromCharCode ls}"
  else
    '\uFFFD'
Number::toLowerU = -> sprintf "%04x", @
Number::toUpperU = -> sprintf "%04X", @
Number::formatU = -> "U+#{@toUpperU()}"
Number::isFunctionalCodePoint = ->
  0xFE00 <= @ <= 0xFE0F or
  0xE0100 <= @ <= 0xE01EF or
  0x180B <= @ <= 0x180D or
  0x1F3FB <= @ <= 0x1F3FF or
  ([0x200D, 0xE007F].find (p)-> `this == p`)? # force JS '=='
Number::isWhitespaceCodePoint = ->
  0x0009 <= @ <= 0x000D or
  0x2000 <= @ <= 0x200A or
  0x2028 <= @ <= 0x2029 or
  ([0x0020, 0x0085, 0x00A0, 0x1680, 0x202F, 0x205F, 0x3000].find (p)-> `this == p`)? # force JS '=='
String::getFirstCodePoint = ->
  if /^[\uD800-\uDBFF][\uDC00-\uDFFF]/.test @
    0x10000 + (@charCodeAt(0) - 0xD800 << 0xA) + @charCodeAt(1) - 0xDC00
  else if /^[\u0000-\uD799\uE000-\uFFFD]/.test @
    @charCodeAt 0
  else
    undefined
String::searchCodePoint = ->
  if matched = /^\s*(?:U[-+])*([0-9A-F]{4,8})/i.exec(@)
    parseInt(matched[1], 16)
  else
    @getFirstCodePoint()
String::toCodepoints = ->
  if @length <= 0
    []
  else
    first = @getFirstCodePoint()
    range = if first and first > 0xFFFF then 2 else 1
    [first].concat @substr(range).toCodepoints()
# TODO
# Array::eachToUcs2
# Array::eachToHex
# Array::eachToUpperU

numlike = (x)-> +x is +x
