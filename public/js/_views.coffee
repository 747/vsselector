###
# == VDOM components ==
###

### Pre-defined variables
# TYPES = (index-to-type name mapping)
# COLLS = (index-to-collection name mapping)
# NAMES = (valid IVD collection names)
# MISSING = (emoji codes missing from the main glyph lib)
###

#::: Header :::#

Header =
  modal: (e)->
    e.redraw = false
    popup()
  view: ->
    m '.navbar.is-dark',
      m '.navbar-brand',
        m 'p.navbar-item',
          m 'b', I 'title'
          "\u00A0(β)"
        # below are quickfix for mobile view in current ver of Bulma CSS
        m 'a.navbar-item.dropdown.is-hoverable.is-hidden-desktop',
          m 'img.icon.is-large[src="images/language.svg"]', title: I 'lang', alt: I 'lang'
          m '.dropdown-menu',
            m '.dropdown-content', do ->
              for t, l of messages['langname'] when t isnt uiLang.value
                m "a.dropdown-item[href=.][data-lang=#{t}]", onclick: Header.lang, l
        m 'a.navbar-item.modality.is-hidden-desktop',
          onclick: Header.modal
          I 'help'
        m 'a.navbar-item.is-hidden-desktop', href: "https://github.com/747/vsselector", target: "_blank",
          m 'img.icon.is-large[src="images/github.svg"]', title: I 'github', alt: I 'github'
      m '.navbar-menu',
        m '.navbar-start'
        m '.navbar-end',
          m 'a.navbar-item.dropdown.is-hoverable',
            m 'img.icon.is-large[src="images/language.svg"]', title: I 'lang', alt: I 'lang'
            m '.dropdown-menu',
              m '.dropdown-content', do ->
                for t, l of messages['langname'] when t isnt uiLang.value
                  m "a.dropdown-item[href=.][data-lang=#{t}]", onclick: Header.lang, l
          m 'a.navbar-item.modality',
            onclick: Header.modal
            I 'help'
          m 'a.navbar-item', href: "https://github.com/747/vsselector", target: "_blank",
            m 'img.icon.is-large[src="images/github.svg"]', title: I 'github', alt: I 'github'
  lang: (e)->
    t = e.target.dataset.lang
    m.route.set "/#{t}/#{query.box.encodeAsParam()}"
    false

#::: Picker Area (top) :::#

CharTag =
  f: (e)->
    d = e.target.parentElement.dataset
    signboard.del d.pos, d.width
  view: (v)->
    c = +v.attrs.code
    color = if c.isFunctionalCodePoint() then 'is-success' else 'is-info'
    m 'span.tag', class: color, 'data-pos': v.attrs.pos, 'data-width': v.attrs.width, c.toUpperU(),
      m 'button.delete.is-small.delete-char',
        onclick: CharTag.f
CharList =
  view: (v)->
    c = signboard.value.toCodepoints()
    m 'p#breakdown-body.message-body.tags', do ->
      sum = 0
      for code in c
        offset = sum
        leng = code.toUcs2().length
        sum += leng
        m CharTag, pos: offset, width: leng, code: code

BigBox =
  f: ->
    m.withAttr 'value', signboard.set
  view: ->
    m 'textarea#bigbox.textarea.is-fullwidth',
      placeholder: "#{0x1F4DD.toUcs2()}..."
      value: signboard.value
      onchange: BigBox.f()
      onkeyup: BigBox.f()
      onpaste: BigBox.f()

PickChar =
  view: (v)->
    a = v.attrs
    m 'li', id: a.id,
      m 'a.pick',
        'data-char': a.data.toUcs2()
        onclick: m.withAttr 'data-char', signboard.ins
        m 'img.glyph', title: a.title, alt: a.alt, src: a.src
Toggler =
  f: (e)->
    pickerTab.set e.target.parentElement.dataset.tab
  view: ->
    props =
      onclick: Toggler.f
    m '#groups.tabs.is-centered.is-toggle',
      m 'ul',
        m 'li[data-tab="ivs"]', m 'a.toggler', props, I 'tab_ivs'
        m 'li[data-tab="vs"]', m 'a.toggler', props, I 'tab_vs'
        m 'li[data-tab="emod"]', m 'a.toggler', props, I 'tab_emoji'
        m 'li[data-tab="util"]', m 'a.toggler', props, I 'tab_utils'
Picker =
  view: ->
    m '#picker.column.is-5.message.is-success',
      m 'p.message-header',
        m 'span.is-inline-tablet.is-hidden-mobile', I 'paste_left'
        m 'span.touch-picker-leader.is-hidden-tablet.is-inline-mobile.has-text-centered', I 'paste_up'
      m '#catalog.message-body',
        do ->
          switch pickerTab.source
            when "ivs"
              m 'ul#ivs', do ->
                ivs = (x)-> 0xE0100 + x - 17
                for n in [17..256]
                  m PickChar,
                    id: "ivs-#{n}"
                    data: ivs n
                    title: "VS#{n} (#{ivs(n).formatU()})"
                    alt: "VS#{n}"
                    src: "./images/selectors/vs-#{n}.svg"
            when "vs"
              m 'ul#vs',
                do ->
                  svs = (x)-> 0xFE00 + x - 1
                  note = (x)-> svs(x).formatU() + if x == 15 then "; text style" else if n == 16 then "; emoji style" else ""
                  for n in [1..16]
                    m PickChar,
                      id: "vs-#{n}"
                      data: svs n
                      title: "VS#{n} (#{note(n)})"
                      alt: "VS#{n}"
                      src: "./images/selectors/vs-#{n}.svg"
                do ->
                  fvs = (x) -> 0x180B + x - 1
                  for n in [1..3]
                    m PickChar,
                      id: "fvs-#{n}"
                      data: fvs n
                      title: "Mongolian FVS#{n} (#{fvs(n).formatU()})"
                      alt: "FVS#{n}"
                      src: "./images/selectors/fvs-#{n}.svg"
            when "emod"
              m 'ul#emod',
                do ->
                  ris = (x)-> 0x1F1E6 + x
                  for n in [0..25]
                    m PickChar,
                      id: "region-#{n}"
                      data: ris n
                      title: "Regional letter #{(n+65).toUcs2()} (#{ris(n).formatU()})"
                      alt: "RIS #{(n+65).toUcs2()}"
                      src: "./images/te/#{ris(n).toLowerU()}.svg"
                do ->
                  emo = (x)-> 0x1F3FB + x - 2
                  sc = (x)-> if x is 2 then "1-2" else n
                  for n in [2..6]
                    m PickChar,
                      id: "fitz-#{n}"
                      data: emo n
                      title: "Fitzgerald #{sc(n)} (#{emo(n).formatU()})"
                      alt: "Fitz #{sc(n)}"
                      src: "./images/te/#{emo(n).toLowerU()}.svg"
                do ->
                  emc = (x)-> 0x1F9B0 + x
                  tx = (x)-> ['red hair', 'curly hair', 'bald', 'white hair'][x]
                  for n in [0..3]
                    m PickChar,
                      id: "ecom-#{n}"
                      data: emc n
                      title: "Emoji component #{tx(n)} (#{emc(n).formatU()})"
                      alt: tx(n).charAt(0).toUpperCase() + tx(n).slice(1)
                      src: "./images/te/#{emc(n).toLowerU()}.svg"
            when "util"
              m 'ul#util',
                m PickChar,
                  id: "zwj"
                  data: 0x200D
                  title: "ZERO WIDTH JOINER (#{0x200D.formatU()})"
                  alt: "ZWJ"
                  src: "./images/selectors/zwj.svg"
                do ->
                  tag = (x)-> 0xE0020 + x
                  t = (x)->
                    if x is 0 then ["SPACE", "SP"]
                    else if x is 0x5F then ["END", "END"]
                    else ["\u00ab#{(x+32).toUcs2()}\u00bb", "#{(x+32).toUcs2()}"]
                  # U+E001 is still deprecated
                  for n in [0..0x5F]
                    m PickChar,
                      id: "tags-#{n}"
                      data: tag(n)
                      title: "Tag #{t(n)[0]} (#{tag(n).formatU()})"
                      alt: "Tag #{t(n)[1]}"
                      src: "./images/selectors/tag-#{n+32}.svg"
        m Toggler

Social =
  view: ->
    m '.level.is-mobile',
      m '.level-left'
      m 'p#shares.content.is-small.level-right',
        m 'span#to_share.level-item', I 'share'
        m 'a#twitter-share.level-item',
          onclick: (e)-> Social.share e, 'twitter'
          m 'img.glyph[alt="Twitter"]',
            src: "images/Twitter_Social_Icon_Circle_Color.svg"
        m 'a#line-it.level-item',
          onclick: (e)-> Social.share e, 'line'
          m 'img.glyph[alt="LINE"]',
            src: "images/share-d.png"
  share: (e, t)->
    e.redraw = false
    switch t
      when 'twitter'
        url = encodeURIComponent window.location.href
        content = encodeURIComponent signboard.value
        tag = encodeURIComponent I 'share_tag'
        window.open "https://twitter.com/intent/tweet?text=#{content}&url=#{url}&hashtags=#{tag}", "tweet", "width=550,height=480,location=yes,resizable=yes,scrollbars=yes"
      when 'line'
        message = encodeURIComponent "#{signboard.value} #{window.location.href}"
        window.open "//line.me/R/msg/text/?#{message}"

Workspace =
  view: ->
    m '#workspace.columns.section.transparent',
      m '#viewer.column.is-7',
        m BigBox
        m '#breakdown.message.is-warning.is-fullwidth',
          m CharList
        m Social
      m Picker

#::: Search Area (bottom) :::#

CharTab =
  view: (v)->
    w = v.attrs.codes
    x = +v.attrs.num
    active = (n)-> if n is x then 'is-active' else undefined
    empty = (n)-> if query.results[n]? then undefined else 'has-background-grey-lighter'
    link = (n)-> if n is x then undefined else m.withAttr('data-idx', query.show)
    m 'div#chartabs.tabs.is-boxed', m 'ul', do ->
      for ch, i in w
        m 'li',
          class: [active(i), empty(i)].join ' '
          m 'a',
            'data-idx': i
            title: ch.toUpperU()
            onclick: link(i)
            ch.toUcs2()

External =
  view: (v)->
    id = +v.attrs.code
    m 'div.message.is-info', m 'p.message-body', do ->
      list = []
      for s, i in External.sites
        list.push ' ' if i > 0
        list.push m 'a.button.is-info',
          href: s[1] + id[s[2]]()
          target: '_blank'
          sprintf I('external'), site: s[0], char: id.toUcs2()
      list
  sites: [
    ['CHISE', 'http://www.chise.org/est/view/character/', 'toUcs2']
    ['GlyphWiki', 'https://glyphwiki.org/wiki/u', 'toLowerU']
    ['Codepoints', 'https://codepoints.net/U+', 'toUpperU']
  ]

Row =
  view: (v)->
    a = v.attrs
    [id, base, name, type, cid, coll, seq] = [a.id, a.base, a.name, a.type, a.cid, a.coll, a.seq]
    m 'tr', class: (if seq then "content message is-small is-warning collapsible #{a.klass}"),
      m 'td',
        m '.field.has-addons.has-addons-centered',
          m '.control',
            m 'button.button.is-dark.insert',
              class: (if seq then 'is-small'),
              char: Row.calcChar(seq, base, id)
              onclick: m.withAttr 'char', signboard.ins
              I 'insert'
          m '.control',
            m 'input.autocopy.input.has-text-centered',
              class: do ->
                classes = if seq then ['is-small'] else []
                classes.push do ->
                  switch coll
                    when "Adobe-Japan1" then 'ivs-aj1'
                    when "Moji_Joho" then 'ivs-mj'
                    when "Hanyo-Denshi", "MSARG", "KRName" then 'ivs-etc'
                (n for n in classes when n isnt undefined).join ' '
              value: Row.calcChar(seq, base, id)

          m '.control'
            m 'button.button.clipboard.is-primary',
              class: (if seq then 'is-small'),
              'data-clipboard-text': Row.calcChar(seq, base, id)
              I 'copy'
      do ->
        if seq
          code = seq.eachToHex().join('-')
          path = if MISSING.indexOf(code) > 0 then "./images/te/supp/#{code}.png" else "./images/te/#{code}.svg"
          [
            m 'td', colSpan: 2, seq.eachToUpperU().join ' '
            m 'td.glyph-col',
              m 'img.glyph', src: path
            m 'td', colSpan: 2, name
          ]
        else
          [
            m 'td', "U+#{if base then base.toUpperU() else id.toUpperU()}"
            m 'td', if base then "U+#{id.toUpperU()}" else '-'
            m 'td.glyph-col',
              m 'img.glyph',
                src: do ->
                  switch type
                    when "ideograph", "compat"
                      "https://glyphwiki.org/glyph/u#{if base then base.toLowerU() + '-u' else ''}#{id.toLowerU()}.svg"
                    when "emoji"
                      code = "#{if base then base.toString(16) + '-' else ''}#{id.toString(16)}"
                      if MISSING.indexOf(code) > 0 then "./images/te/supp/#{code}.png" else "./images/te/#{code}.svg"
                    else "./images/noimage.png"
            m 'td', do ->
              if cid then m 'span.named', I "coll_#{cid}"
              else coll
            m 'td', name
          ]
  header: (id, open)->
    txt = if open then I('close_seq') else I('open_seq')
    m 'tr.content.message.is-small.is-warning.seq-header',
      id: id
      onclick: m.withAttr 'id', query.toggleSeq
      m 'td.message-header[colspan=6]', txt
  oncreate: ->
    new ClipboardJS '.clipboard'
  calcChar: (seq, base, id)->
    if seq then seq.eachToUcs2().join ''
    else "#{if base then base.toUcs2() else ''}#{id.toUcs2()}"

VResult =
  view: (v)->
    m '#entries[style="overflow-x: auto"]', # until bulma officially has .table-container...
      do -> VResult.response(query.phase)
  response: (phase)->
    switch phase
      when 'got'
        current = query.tab
        fragment = [
          m CharTab, codes: query.word, num: current
          m External, code: query.word[current]
        ]
        if query.results[current]?
          fragment.push(
            m 'table#found.table.is-fullwidth.is-marginless.transparent',
              m 'thead', m 'tr',
                m 'th#copy',       I 'col_actual'
                m 'th#codepoint',  I 'col_code'
                m 'th#variation',  I 'col_var'
                m 'th#image',      I 'col_image'
                m 'th#collection', I 'col_collection'
                m 'th#internal',   I 'col_source'
              m 'tbody#charlist', do ->
                rows = []
                for row, i in query.results[current] when query.allowed row['coll']
                  if Array.isArray row
                    hid = query.results[current][0].id + '-' + query.results[current][i-1].id
                    if query.visible hid
                      rows.push do -> Row.header hid, true
                      rows.push m Row, seq for seq in row
                      rows.push do -> Row.header hid, true
                    else
                      rows.push do -> Row.header hid
                  else if isObject row
                    rows.push m Row, row
                rows
          )
        else
          fragment.push(
            m '#notfound.message.is-warning',
              m 'p.has-text-centered.message-body', I 'not_found'
          )

        fragment
      when 'wait'
        m '.message.is-primary',
          m 'p.message-body', m 'button.button.is-fullwidth.is-text.is-paddingless.is-loading'
      when 'error'
        m '.message.is-danger',
          m 'p.message-body', query.error
      else
        m '.message.is-info',
          m 'p.has-text-centered.message-body', I 'search_init'

SearchBox =
  oninit: ->
    hint.load()

  f: ->
    m.withAttr 'value', query.input
  key: (e)->
    e.redraw = false
    if SearchBox.suggestionsCache.length > 0
      last = SearchBox.suggestionsCache.length - 1
      curr = SearchBox.selecting
      rebuild = ->
        SearchBox.suggestionsCache = SearchBox.buildSuggestions()
        SearchBox.keypressHappened = false
        m.redraw()

    if e.key is 'Enter' or e.keyCode is 13 or e.which is 13
      if SearchBox.keypressHappened
        return SearchBox.replaceBySuggestion SearchBox.suggestionsCache[curr].attrs['data-char'] if curr?
        SearchBox.clearSuggestions()
        query.input e.currentTarget.value
        Search.submit()
    else if e.key is 'ArrowDown' or e.keyCode is 40 or e.which is 40
      if last?
        SearchBox.selecting = if not curr? or curr >= last then 0 else curr + 1
        return rebuild()
    else if e.key is 'ArrowUp' or e.keyCode is 38 or e.which is 38
      if last?
        SearchBox.selecting = if not curr? or curr <= 0 then last else curr - 1
        return rebuild()
    else
      query.input e.currentTarget.value
    SearchBox.buffer.update()
    SearchBox.suggestBuffer.update()
    SearchBox.keypressHappened = false
  keypressHappened: false # keypressが発火しないkeyupは変換確定
  keypress: (e)->
    e.redraw = false
    SearchBox.keypressHappened = true
  buffer:
    clear: false
    __timer: undefined
    update: ->
      clearTimeout @__timer
      @clear = false
      @__timer = setTimeout (=> @clear = true; m.redraw), 100
  view: ->
    [
      m 'input#searchbox.input[type=text]',
        placeholder: I 'example'
        value: query.box
        onchange: SearchBox.f()
        onkeypress: SearchBox.keypress
        oninput: SearchBox.key
        onkeyup: SearchBox.key
        onpaste: SearchBox.f()
      m '#autocomplete.panel.has-background-white', SearchBox.suggestionsCache
    ]

  candidate: ''
  searchCache: []
  suggestionsCache: []
  selecting: undefined
  insert: ->
    m.withAttr 'data-char', SearchBox.replaceBySuggestion
  replaceBySuggestion: (t)->
    str = query.box
    before = str.indexOf ':'
    after = before + SearchBox.candidate.length + 2 # take in the closing colon, doesn't harm if nonexistent
    query.input str.slice(0, before) + t + str.slice(after)
    SearchBox.suggest()
  clearSuggestions: ->
    SearchBox.suggestionsCache = []
  suggestBuffer:
    clear: false
    __timer: undefined
    update: ->
      clearTimeout @__timer
      @clear = false
      @__timer = setTimeout (=> @clear = true; SearchBox.suggest()), 500
  suggest: ->
    lead = query.box.indexOf ':'
    if lead >= 0
      start = lead + 1
      end = query.box.indexOf(':', start)
      captured = query.box.slice(start, (if end > 0 then end else undefined))
    else
      captured = ''
    if hint.loaded and captured isnt SearchBox.candidate
      SearchBox.selecting = undefined
      SearchBox.candidate = captured
      SearchBox.searchCache = hint.suggest captured
      SearchBox.suggestionsCache = SearchBox.buildSuggestions()
    m.redraw()
  buildSuggestions: ->
    for sg, i in SearchBox.searchCache
        it = sg.item
        _mk = [].concat.apply([], mt.indices for mt in sg.matches) # first-level flatten
        mk = (e for e, mi in _mk when _mk.indexOf(e) is mi) # uniq
          .sort (a, b)-> a[0] - b[0]
        emph = (iv)-> m 'mark', iv
        marked = do ->
          fragment = it.label.toCodepoints().eachToUcs2()
          loss = 0
          for ep in mk
            [bgn, end] = (p - loss for p in ep)
            len = end - bgn
            if len is 0
              fragment[bgn] = emph fragment[bgn]
            else if len > 0
              fragment.splice bgn, len+1, emph fragment.slice bgn, end+1
              loss += len
          fragment
        m 'a.autocomplete-item.panel-block',
          class: if SearchBox.selecting is i then 'has-background-link has-text-white' else ''
          'data-char': it.value
          onclick: SearchBox.insert()
          m 'span.panel-icon.emoji-width', it.value
          m 'span', marked
          m 'span.desc.has-text-grey-light.is-size-7', it.desc

Search =
  view: ->
    m '#search.section',
      m '#query.level.is-block-touch is-block-desktop-only is-block-widescreen-only',
        m '.level-left',
          m '.level-item',
            m '.field.has-addons',
              m 'p.control',
                m SearchBox
              m 'p.control',
                m 'button#searchbutton.button.is-primary',
                  onclick: Search.submit
                  m 'span#searchlabel', I 'search_button'
        m '.level-right',
          m 'p.has-text-weight-bold.control.level-item',
            m 'span#selectcol', I 'collections'
          for ivd in NAMES
            m '.level-item.collection-selector.control.checkbox',
              m 'input.is-checkradio.is-block.is-success.search-filter[type=checkbox]',
                name: ivd
                onclick: m.withAttr 'name', query.filter
                checked: query.allowed ivd
              m 'label.collection-selector-desc',
                for: ivd,
                onclick: m.withAttr 'for', query.filter # because it shadows the checkbox
                ivd
      m VResult
  submit: ->
    m.route.set "/#{uiLang.value}/#{query.box.encodeAsParam()}"

#::: Main App :::#

TheApp =
  view: -> [
    m Header
    m Workspace
    m Search
  ]
