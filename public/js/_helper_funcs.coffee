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
  [0x200D, 0xE007F].indexOf(+@) >= 0
Number::isWhitespaceCodePoint = ->
  0x0009 <= @ <= 0x000D or
  0x2000 <= @ <= 0x200A or
  0x2028 <= @ <= 0x2029 or
  [0x0020, 0x0085, 0x00A0, 0x1680, 0x202F, 0x205F, 0x3000].indexOf(+@) >= 0
String::getFirstCodePoint = ->
  if /^[\uD800-\uDBFF][\uDC00-\uDFFF]/.test @
    0x10000 + (@charCodeAt(0) - 0xD800 << 0xA) + @charCodeAt(1) - 0xDC00
  else if /^[\u0000-\uD799\uE000-\uFFFD]/.test @
    @charCodeAt 0
  else
    undefined
String::searchCodePoint = ->
  segs = @match /(?:U[-+])*[0-9A-F]{4,8}|[\uD800-\uDBFF][\uDC00-\uDFFF]|(?!\s)[\u0000-\uD799\uE000-\uFFFD]/gi
  norm = for s in segs
    if matched = /^\s*(?:U[-+])*([0-9A-F]{4,8})/i.exec(s)
      parseInt(matched[1], 16)
    else
      s.getFirstCodePoint()
  (n for n, i in norm when n? and not n.isFunctionalCodePoint() and not n.isWhitespaceCodePoint() and norm.indexOf(n) is i)
String::toCodepoints = ->
  if @length <= 0
    []
  else
    first = @getFirstCodePoint()
    range = if first and first > 0xFFFF then 2 else 1
    [first].concat @substr(range).toCodepoints()
String::encodeAsParam = ->
  @toCodepoints().eachToHex().join('-')
String::decodeAsParam = ->
  (parseInt(e, 16).toUcs2() for e in @split('-')).join ''
Array::eachToUcs2 = ->
  (e.toUcs2() for e in @)
Array::eachToHex = ->
  (e.toString(16) for e in @)
Array::eachToUpperU = ->
  (e.toUpperU() for e in @)
Array::eachToLowerU = ->
  (e.toLowerU() for e in @)

numlike = (x)-> +x is +x
isObject = (value)->
  value and typeof value is 'object' and value.constructor is Object
