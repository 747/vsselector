Number::toUcs2 = ->
  if 0 <= @ <= 0xFFFD
    return String.fromCharCode(@)
  else if 0xFFFF < @ <= 0x10FFFD
    down = @ - 0x10000
    hs = 0xD800 + (down >> 0xA)
    ls = 0xDC00 + (down & 0x3FF)
    return "#{String.fromCharCode(hs)}#{String.fromCharCode(ls)}"
  else
    return '\uFFFD'
Number::toLowerU = -> sprintf "%04x", @
Number::toUpperU = -> sprintf "%04X", @
String::getFirstCodePoint = ->
  if /^[\uD800-\uDBFF][\uDC00-\uDFFF]/.test(@)
    return 0x10000 + (@charCodeAt(0) - 0xD800 << 0xA) + @charCodeAt(1) - 0xDC00
  else if matched = /^\s*(?:U[-+])*([0-9A-F]{4,8})/i.exec(@)
    return parseInt(matched[1], 16)
  else if /^[\u0000-\uD799\uE000-\uFFFD]/.test(@)
    return @charCodeAt(0)
  else
    return undefined

jQuery ($)->
  rowmaker = (id, type, name, coll, base)->
    row = $("<tr/>")
    tid = TYPES[type]
    if tid == 'ideograph' or tid == 'compat'
      src = "http://glyphwiki.org/glyph/u#{if base then "#{base.toLowerU()}-u" else ""}#{id.toLowerU()}.svg"
    else if tid == 'emoji'
      src = "./images/e1/#{if base then "#{base.toLowerU()}-" else ""}#{id.toLowerU()}.svg"
    else
      src = "./images/noimage.png"

    if $.type(coll) == 'number' and coll >= 0
      collstr = "<span class=\"#{COLLS[coll]}\">#{COLLS[coll]}</span>"
    else
      collstr = coll

    cols = [
      $("<td><input type=\"text\" class=\"autocopy\" value=\"#{if base then base.toUcs2() else ""}#{id.toUcs2()}\"></td>")
      $("<td>#{"U+#{if base then base.toUpperU() else id.toUpperU()}"}</td>")
      $("<td>#{if base then "U+#{id.toUpperU()}" else "-"}</td>")
      $("<td><img class=\"glyph\" src=\"#{src}\"></td>")
      $("<td>#{collstr}</td>")
      $("<td>#{name}</td>")
    ]
    row.append col for col in cols
    row
  fetchChar = ->
    cp = $("#searchbox").val().toString().getFirstCodePoint()

    if cp?
      $.ajax {
        type: "get"
        url: "./chars/#{cp.toUpperU()}.json"
        contentType: 'application/json'
        dataType: 'json'
        success: (r)->
          [id, type, name, vars, coll] = ["i", "t", "n", r["V"], "c"]
          list = $("#charlist").empty()
          list.append rowmaker(cp, r[type], r[name], BASE_IDX)
          basechar = if TYPES[r[type]] == "compat" then vars[0][id] else cp
          list.append rowmaker(v[id], v[type], v[name], v[coll], basechar) for v in vars
          $("#notfound").hide()
          $("#found").show()
        error: ->
          $("#found").hide()
          $("#notfound").show()
      }

  $("#search").click -> fetchChar()
  $("#searchbox").keypress (key)->
    if key.which == 13
      fetchChar()
      return false
