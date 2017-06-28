# Pre-defined variables
# TYPES = (index-to-type name mapping)
# COLLS = (index-to-collection name mapping)
# BASE_IDX = COLLS.indexOf("base")

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
Number::isFunctionalCodePoint = ->
  if 0xFE00 <= @ <= 0xFE0F or 0xE0100 <= @ <= 0xE01EF or 0x180B <= @ <= 0x180D or 0x1F3FB <= @ <= 0x1F3FF
    return true
  else
    return false
String::getFirstCodePoint = ->
  if /^[\uD800-\uDBFF][\uDC00-\uDFFF]/.test(@)
    return 0x10000 + (@charCodeAt(0) - 0xD800 << 0xA) + @charCodeAt(1) - 0xDC00
  else if /^[\u0000-\uD799\uE000-\uFFFD]/.test(@)
    return @charCodeAt(0)
  else
    return undefined
String::searchCodePoint = ->
  if matched = /^\s*(?:U[-+])*([0-9A-F]{4,8})/i.exec(@)
    return parseInt(matched[1], 16)
  else
    return @getFirstCodePoint()

jQuery ($)->
  # rowmaker = (id, type, name, coll, base)->
  #   row = $("<tr/>")
  #   [tid, cid] = [TYPES[type], COLLS[coll]]
  #   cpa = cid == 'parent'
  #   if tid == 'ideograph' or tid == 'compat'
  #     src = "http://glyphwiki.org/glyph/u#{if base and !cpa then "#{base.toLowerU()}-u" else ""}#{id.toLowerU()}.svg"
  #   else if tid == 'emoji'
  #     src = "./images/e1/#{if base then "#{base.toLowerU()}-" else ""}#{id.toLowerU()}.svg"
  #   else
  #     src = "./images/noimage.png"
  #
  #   if cid
  #     collstr = "<span class=\"#{cid}\">#{cid}</span>"
  #   else
  #     collstr = coll
  #
  #   if coll is 'Adobe-Japan1'
  #     fontclass = 'ivs-aj1'
  #   else if coll is 'Moji_Joho'
  #     fontclass = 'ivs-mj'
  #   else if coll is 'Hanyo-Denshi' or coll is 'MSARG'
  #     fontclass = 'ivs-etc'
  #
  #   cols = [
  #     $("<td class=\"control has-addons has-addons-centered\"><button class=\"button is-dark insert\">↑挿入</button><input type=\"text\" class=\"autocopy input has-text-centered #{fontclass}\" value=\"#{if base and !cpa then base.toUcs2() else ""}#{id.toUcs2()}\"><button class=\"button clipboard is-primary\">コピー</button></td>")
  #     $("<td>#{"U+#{if base then base.toUpperU() else id.toUpperU()}"}</td>")
  #     $("<td>#{if base then "U+#{id.toUpperU()}" else "-"}</td>")
  #     $("<td><img class=\"glyph\" src=\"#{src}\"></td>")
  #     $("<td>#{collstr}</td>")
  #     $("<td>#{name}</td>")
  #   ]
  #   row.append col for col in cols
  #   row
  renderSeq = (seqs, bases)->
    genid = bases.join('-')
    results = []
    results.push $("#SequencesHeader").render({'id': genid})
    for s in seqs
      q = {'seq': bases.concat(s['q']), 'name': s['n'], 'class': genid, 'isSeq': true}
      results.push $("#rowMaker").render(q)
    results
  fetchChar = ->
    cp = $("#searchbox").val().toString().searchCodePoint()
    filters = $(".search-filter:not(:checked)").map( ()-> $(this).attr("name") ).get()

    if cp?
      uhex = cp.toUpperU()
      [chunk, key] = [uhex.slice(0, uhex.length-2), uhex.slice(-2)]
      $.ajax {
        type: "get"
        url: "./chars/#{chunk}.json"
        contentType: 'application/json'
        dataType: 'json'
        success: (hash)->
          r = hash[key]
          $("#initial").hide()
          if r?
            [id, type, name, vars, coll, seq] = ["i", "t", "n", r["V"], "c", "S"]
            list = $("#charlist").empty()
            list.append $("#rowMaker").render({'id': cp, 'type': r[type], 'name': r[name], 'coll': BASE_IDX})
            list.append.apply(this, renderSeq(r[seq], [cp])) if r[seq]
            basechar = if TYPES[r[type]] == "compat" then vars[0][id] else cp
            for v in vars
              continue if $.inArray(v[coll], filters) >= 0
              list.append rowmaker({'id': v[id], 'type': v[type], 'name': v[name], 'coll': v[coll], 'base': basechar})
              list.append.apply(this, renderSeq(v[seq], [cp, v[id]]) ) if v[seq]
            new Clipboard '.clipboard', {
              target: (trigger)->
                trigger.previousElementSibling
            }
            $("#notfound").hide()
            $("#found").show()
          else
            $("#found").hide()
            $("#notfound").show()
        error: ->
          $("#initial").hide()
          $("#found").hide()
          $("#notfound").show()
      }
  analyze = (id)->
    text = $(id).val()
    split = []
    while text.length > 0
      first = text.getFirstCodePoint()
      range = if first and first > 0xFFFF then 2 else 1
      split.push first
      text = text.substring(range)
    return split
  charlistmaker = (seq)->
    tags = []
    pos = 0
    for code in seq
      width = if code > 0xFFFF then 2 else 1
      color = if code.isFunctionalCodePoint() then 'is-success' else 'is-info'
      tags.push "<span class=\"tag #{color}\" data-pos=\"#{pos}\" data-width=\"#{width}\">#{code.toUpperU()}<button class=\"delete delete-char\"></button></span>"
      pos += width
    $("#breakdown-body").html tags.join("+")
    return
  insertToBox = (string)->
    $("#bigbox").selection('replace', {
      text: string,
      caret: 'end'
    })
    $("#bigbox").change()
    undefined

  $("#search").click -> fetchChar()

  $("#searchbox").keypress (key)->
    if key.which == 13
      fetchChar()
      return false

  $(".modality").click ->
    modal = $(this).data("target")
    $(modal).addClass("is-active")
    return false

  $(".modal-background, .modal-close").click ->
    $(this).closest(".modal").removeClass("is-active")
    return false

  $(".toggler").click ->
    tab = $(this).data("tab")
    $("#picker > ul:not(#{tab})").hide()
    $(tab).show()
    $(".toggler").each ->
      $(this).closest("li").removeClass("is-active")
    $(this).closest("li").addClass("is-active")
    return false

  $(".pick").click ->
    cpdata = + $(this).data("char") # string read as int
    insertToBox cpdata.toUcs2()
    return false

  $(document).on 'click', '.delete-char', ->
    tagdata = $(this).closest(".tag").data()
    if $.isNumeric(tagdata['pos']) and $.isNumeric(tagdata['width'])
      str = $("#bigbox").val()
      $("#bigbox").val str.slice(0, tagdata['pos']) + str.slice(tagdata['pos'] + tagdata['width'])
      $("#bigbox").change()
    return false

  $(document).on 'click', '.insert', ->
    variant = $(this).next().val()
    insertToBox variant
    return false

  former = $("#bigbox").val()
  $("#bigbox").on "change keyup paste", ->
    current = $(this).val()
    return if current == former
    former = current
    charlistmaker analyze("#bigbox")
