Number::toUcs2 = ->
  if 0 <= @ <= 0xFFFD
    return String.fromCharCode(@)
  else if 0xFFFF < @ <= 0x10FFFD
    down = @ - 0x10000
    hs = 0xD800 + down >> 0xA
    ls = 0xDC00 + down & 0x3FF
    return "#{String.fromCharCode(hs)}#{String.fromCharCode(ls)}"
  else
    return '\uFFFD'
Number::toLowerU = -> sprintf "%04x", @
Number::toUpperU = -> sprintf "%04X", @
String::getFirstCodePoint = ->
  if /^[\uD800-\uDBFF][\uDC00-\uDFFF]/.test(@)
    return 0x10000 + (@charCodeAt(0) - 0xD800) << 0xA + @charCodeAt(1) - 0xDC00
  else if /^[\u0000-\uD799\uE000-\uFFFD]/.test(@)
    return @charCodeAt(0)
  else
    return undefined

jQuery ($)->
  rowmaker = (id, type, name, coll, base)->
    row = $("<tr/>")
    tid = typenames[type]
    if tid == 'ideograph' or tid == 'compat'
      src = "http://glyphwiki.org/glyph/#{"u#{base.toLowerU()}-" if base}#{id.toLowerU()}.svg"
    else if tid == 'emoji'
      src = "./images/e1/#{"u#{base.toLowerU()}-" if base}#{id.toLowerU()}.svg"
    else
      src = "./images/noimage.png"

    cols = [
      $("<td><input type=\"text\" class=\"autocopy\" value=\"#{base.toUcs2 if base}#{id.toUcs2}\"></td>")
      $("<td>#{"U+#{if base then base.toUpperU() else id.toUpperU()}"}</td>")
      $("<td>#{"U+#{if base then id.toUpperU() else "-"}"}</td>")
      $("<td><img class=\"glyph\" src=\"#{src}\"></td>")
      $("<td>#{coll}</td>")
      $("<td>#{name}</td>")
    ]
    row.append col for col in cols
    row

  $("#search").click ->
    cp = $("#searchbox").val().toString().getFirstCodePoint()

    if cp?
      $.ajax {
        type: "get"
        url: "./chars/#{cp.toUpperU(16)}"
        contentType: 'application/json'
        dataType: 'json'
        success: (r)->
          [id, type, name, vars, coll] = ["i", "t", "n", r["V"], "c"]
          list = $("#charlist").empty()
          list.append rowmaker(cp, r[type], r[name], "基底文字")
          basechar = if typenames[r[type]] == "compat" then vars[0][id] else r[id]
          list.append rowmaker(v[id], v[type], v[name], v[coll], basechar) for v in vars
          $("#notfound").hide()
          $("#found").show()
        error: ->
          $("#found").hide()
          $("#notfound").show()
      }
