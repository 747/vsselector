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
  if 0xFE00 <= @ <= 0xFE0F or
     0xE0100 <= @ <= 0xE01EF or
     0x180B <= @ <= 0x180D or
     0x1F3FB <= @ <= 0x1F3FF or
     `this == 0x200D` or `this == 0xE007F` # force JS '=='
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
  # $.views.settings.debugMode true
  $.views.helpers
    eachToUcs2: (arr) -> arr.map( (e) -> e.toUcs2() )
    eachToHex: (arr) -> arr.map( (e) -> e.toString(16) )
    eachToUpperU: (arr) -> arr.map( (e) -> e.toUpperU() )

  renderSeq = (seqs, bases)->
    genid = bases.join('-')
    results = []
    results.push $("#SequencesHeader").render({'id': genid})
    for s in seqs
      q = {'seq': bases.concat(s['q']), 'name': s['n'], 'klass': genid, 'isSeq': true} # 'class' will break JsRender?
      results.push $("#rowMaker").render(q)
    results

  fetchChar = ->
    $("#search").addClass("is-loading")
    cp = $("#searchbox").val().toString().searchCodePoint()
    filters = $(".search-filter:not(:checked)").map( ()-> $(this).attr("name") ).get()

    if cp?
      uhex = cp.toUpperU()
      [chunk, key] = [uhex.slice(0, uhex.length-2), uhex.slice(-2)]
      $.ajax
        type: "get"
        url: "./chars/#{chunk}.json"
        contentType: 'application/json'
        dataType: 'json'
        success: (hash)->
          r = hash[key]
          $("#initial").hide()
          $("#extern p:first").empty().append $("#Extern").render {'id': cp}
          if r?
            [id, type, name, vars, coll, seq] = ["i", "t", "n", r["V"], "c", "S"]
            list = $("#charlist").empty()
            list.append $("#rowMaker").render
              'id': cp
              'type': TYPES[r[type]] or r[type]
              'name': r[name]
              'cid': "base"
            list.append renderSeq(r[seq], [cp]).join('') if r[seq]
            basechar = if TYPES[r[type]] == "compat" then vars[0][id] else cp
            for v in vars
              continue if $.inArray(v[coll], filters) >= 0
              list.append $("#rowMaker").render
                'id': v[id]
                'type': TYPES[v[type]] or v[type]
                'name': v[name]
                'cid': COLLS[v[coll]]
                'coll': v[coll]
                'base': basechar
              list.append renderSeq(v[seq], [cp, v[id]]).join('') if v[seq]
            new ClipboardJS '.clipboard',
              target: (trigger)->
                $(trigger).parent().prev().children("input").first().get(0)
            $("#notfound").hide()
            $("#found, #extern").show()
          else
            $("#found").hide()
            $("#notfound, #extern").show()
        error: ->
          $("#initial").hide()
          $("#found, #extern").hide()
          $("#notfound").show()
    $("#search").removeClass("is-loading")
    false

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
      tags.push $("#CharTag").render
        color: if code.isFunctionalCodePoint() then 'is-success' else 'is-info',
        pos: pos,
        width: width,
        cp: code.toUpperU()
      pos += width
    $("#breakdown-body").html tags.join("+")
    return

  insertToBox = (string)->
    $("#bigbox").selection 'replace',
      text: string,
      caret: 'end'
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
    $("#catalog > ul:not(#{tab})").hide()
    $(tab).show()
    $(".toggler").each ->
      $(this).closest("li").removeClass("is-active")
    $(this).closest("li").addClass("is-active")
    return false

  $(".pick").click ->
    cpdata = + $(this).data("char") # string read as int
    insertToBox cpdata.toUcs2()
    return false

  # Social buttons
  $("#twitter-share").click ->
    url = encodeURIComponent(window.location.href)
    content = encodeURIComponent($("#bigbox").val())
    tag = encodeURIComponent("異体字セレクタセレクタ")
    window.open "https://twitter.com/intent/tweet?text=#{content}&url=#{url}&hashtags=#{tag}", "tweet", "width=550,height=480,location=yes,resizable=yes,scrollbars=yes"
    false
  $("#line-it").click ->
    message = encodeURIComponent "#{$("#bigbox").val()} #{window.location.href}"
    window.open "//line.me/R/msg/text/?#{message}"
    false

  $(document).on 'click', '.delete-char', ->
    tagdata = $(this).closest(".tag").data()
    if $.isNumeric(tagdata['pos']) and $.isNumeric(tagdata['width'])
      str = $("#bigbox").val()
      $("#bigbox").val str.slice(0, tagdata['pos']) + str.slice(tagdata['pos'] + tagdata['width'])
      $("#bigbox").change()
    false

  $('#charlist').on 'click', '.insert', -> # document and body stopped binding the handler for unknown reason
    variant = $(this).parent().next().children("input").first().val()
    insertToBox variant
    false

  $('#charlist').on 'click touchend', '.seq-header', -> # iOS doesn't recognize click on td?
    $(this).nextUntil(":not(.collapsible)").slideToggle()
    false

  former = ""
  $("#bigbox").on "change keyup paste", ->
    current = $(this).val()
    return if current == former
    former = current
    charlistmaker analyze("#bigbox")
  $("#bigbox").change() # trigger once on startup

  # https://stackoverflow.com/a/11845718
  $.ui.autocomplete.prototype._resizeMenu = ->
    ul = this.menu.element
    ul.outerWidth this.element.outerWidth()

  compl = []
  langs = ["en", "ja"]
  $.when.apply $, langs.map (lang)->
    $.getJSON "./utils/#{lang}.json", (data)->
      for entry, refs of data["L"]
        for r in refs
          compl.push
            label: entry
            value: data["D"][r][0]
            desc: data["D"][r][1]
  .then ->
    $("#searchbox")
      .autocomplete
        source: compl
        classes:
          "ui-menu": "panel"
          "ui-menu-item": "panel-block"
        # focus: (ev, ui)->
        #   $("#searchbox").val ui.item.value
        #   return false
        # select: (ev, ui)->
        #   $("#searchbox").val ui.item.value
        #   return false
      .data "ui-autocomplete"
      ._renderItem = (ul, item)->
        $('<li class="panel-block">')
          .append $('<span class="panel-icon">' + item.value + '</span><div><p class="title is-6">' + item.label + '</p><p class="subtitle content is-small">' + item.desc + '</p></div>')
        .appendTo ul
