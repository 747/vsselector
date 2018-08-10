### Pre-defined variables
# TYPES = (index-to-type name mapping)
# COLLS = (index-to-collection name mapping)
# BASE_IDX = COLLS.indexOf("base")
###

#::: Header :::#

Header =
  view: ->
    m '.navbar.is-dark',
      m '.navbar-brand',
        m 'p.navbar-item', document.title
        # below are quickfix for mobile view in current ver of Bulma CSS
        m 'a.navbar-item.modality.is-hidden-desktop', 'data-target': "#about", '説明'
        m 'a.navbar-item.is-hidden-desktop', href: "https://github.com/747/vsselector", target: "_blank", 'GitHub'
      m '.navbar-menu',
        m '.navbar-start'
        m '.navbar-end',
          m 'a.navbar-item.modality', 'data-target': "#about", '説明'
          m 'a.navbar-item', href: "https://github.com/747/vsselector", target: "_blank", 'GitHub'

#::: Picker Area (top) :::#

CharTag =
  f: (e)->
    d = e.target.parentElement.dataset
    signboard.del d.pos, d.width
  view: (v)->
    c = v.attrs.code
    color = if c.isFunctionalCodePoint() then 'is-success' else 'is-info'
    m 'span.tag', class: color, 'data-pos': v.attrs.pos, "data-width": v.attrs.width, c.toUpperU(),
      m 'button.delete.is-small.delete-char',
        onclick: CharTag.f
        ontouchstart: CharTag.f
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
        'data-char': a.data
        onclick: m.withAttr 'data-char', signboard.ins
        ontouchstart: m.withAttr 'data-char', signboard.ins
        m 'img.glyph', title: a.title, alt: a.alt, src: a.src
Toggler =
  f: (e)->
    pickerTab.set e.target.parentElement.dataset.tab
  view: ->
    props =
      onclick: Toggler.f
      ontouchstart: Toggler.f
    m '#groups.tabs.is-centered.is-toggle',
      m 'ul',
        m 'li', 'data-tab': 'ivs', m 'a.toggler', props, 'IVS'
        m 'li', 'data-tab': 'vs', m 'a.toggler', props, '(F)VS'
        m 'li', 'data-tab': 'emod', m 'a.toggler', props, 'Emoji'
        m 'li', 'data-tab': 'util', m 'a.toggler', props, 'Utils'
Picker =
  view: ->
    m '#picker.column.is-5.message.is-success',
      m 'p.message-header',
        m 'span.is-inline-desktop.is-hidden-touch', '←クリックで挿入'
        m 'span.touch-picker-leader.is-hidden-desktop.is-inline-touch.has-text-centered', '↑クリックで挿入'
      m '#catalog.message-body',
        do ->
          switch pickerTab.source
            when "ivs"
              m 'ul#ivs', do ->
                ivs = (x)-> 0xE0100 + x - 17
                for n in [17..256]
                  m PickChar,
                    id: "ivs-#{n}"
                    data: "#{ivs n}"
                    title: "VS#{n} (#{ivs(n).formatU()})"
                    alt: "VS#{n}"
                    src: "undefined"
            when "vs"
              m 'ul#vs',
                do ->
                  svs = (x)-> 0xFE00 + x - 1
                  note = (x)-> svs(x).formatU() + if x == 15 then "; text style" else if n == 16 then "; emoji style" else ""
                  for n in [1..16]
                    m PickChar,
                      id: "vs-#{n}"
                      data: "#{svs n}"
                      title: "VS#{n} (#{note(n)})"
                      alt: "VS#{n}"
                      src: "undefined"
                do ->
                  fvs = (x) -> 0x180B + x - 1
                  for n in [1..3]
                    m PickChar,
                      id: "fvs-#{n}"
                      data: "#{fvs n}"
                      title: "Mongolian FVS#{n} (#{fvs(n).formatU()})"
                      alt: "FVS#{n}"
                      src: "undefined"
            when "emod"
              m 'ul#emod',
                do ->
                  ris = (x)-> 0x1F1E6 + x
                  for n in [0..25]
                    m PickChar,
                      id: "region-#{n}"
                      data: "#{ris n}"
                      title: "Regional letter #{(n+65).toUcs2()} (#{ris(n).formatU()})"
                      alt: "RIS #{(n+65).toUcs2()}"
                      src: "./images/te/#{ris(n).toLowerU()}.svg"
                do ->
                  emo = (x)-> 0x1F3FB + x - 2
                  sc = (x)-> if x is 2 then "1-2" else n
                  for n in [2..6]
                    m PickChar,
                      id: "fitz-#{n}"
                      data: "#{emo n}"
                      title: "Fitzgerald #{sc(n)} (#{emo(n).formatU()})"
                      alt: "Fitz #{sc(n)}"
                      src: "./images/te/#{emo(n).toLowerU()}.svg"
            when "util"
              m 'ul#util',
                m PickChar,
                  id: "zwj"
                  data: "#{0x200D}"
                  title: "ZERO WIDTH JOINER (#{0x200D.formatU()})"
                  alt: "ZWJ"
                  src: "undefined"
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
                      data: "#{tag(n)}"
                      title: "Tag #{t(n)[0]} (#{tag(n).formatU()})"
                      alt: "Tag #{t(n)[1]}"
                      src: "undefined"
        m Toggler

Workspace =
  view: ->
    m '#workspace.columns.section.transparent',
      m '#viewer.column.is-7',
        m BigBox
        m '#breakdown.message.is-warning.is-fullwidth',
          m CharList
        m '.level.is-mobile',
          m '.level-left'
          m 'p#shares.content.is-small.level-right',
            m 'span#to_share.level-item', '内容をシェア'
            m 'a#twitter-share.level-item',
              m 'img.glyph', src: "images/Twitter_Social_Icon_Circle_Color.svg", alt: "Twitter"
            m 'a#line-it.level-item',
              m 'img.glyph', src: "images/share-d.png", alt: "LINE"
      m Picker

#::: Search Area (bottom) :::#

SearchData =
  config:
    string: ""
    filter: []
  result: {}
  fetch: ->
    cp = SearchData.config.string.searchCodePoint()
    if cp?
      uhex = cp.toUpperU()
      [chunk, key] = [uhex.slice(0, uhex.length-2), uhex.slice(-2)]
      m.request
        type: "get"
        url: "./chars/#{chunk}.json"
      .then (hash)->
        SearchData.result = hash[key]
SeqHeader =
  view: ->
    m 'tr.content.message.is-small.is-warning.seq-header', id: id,
      m 'td.message-header', colSpan: 6, 'この字から始まるシークエンス'
External =
  view: (v)->
    id = v.attrs.code
    m 'div',
      [
        ['CHISE', 'http://www.chise.org/est/view/character/', 'toUcs2']
        ['GlyphWiki', 'https://glyphwiki.org/wiki/u', 'toLowerU']
        ['Codepoints', 'https://codepoints.net/U+', 'toUpperU']
      ].map (l)->
        m 'a.button.is-info', "#{l[0]}で「#{id.toUcs2()}」を表示",
          href: l[1] + id[l[2]]()
          target: '_blank'
      , this
Row =
  view: (v)->
    a = v.attrs
    isSeq = v.attrs.seq?

    m 'tr', class: (if isSeq then "content message is-small is-warning collapsible #{klass}"),
      m 'td',
        m '.field.has-addons.has-addons-centered',
          m '.control',
            m 'button.is-dark.insert', class: (if isSeq then 'is-small'), '↑挿入'
          m '.control',
            m 'input.autocopy.input.has-text-centered',
              class: ->
                classes = if isSeq then ['is-small'] else []
                classes.push ->
                  switch coll
                    when "Adobe-Japan1" then 'ivs-aj1'
                    when "Moji_Joho" then 'ivs-mj'
                    when "Hanyo-Denshi", "MSARG", "KRName" then 'ivs-etc'
                classes.filter( (n) -> n isnt undefined ).join ' '
              value: ->
                if isSeq then seq.eachToUcs2.join ' '
                else (if base and base isnt id then base.toUcs2()) + id.toUcs2()
          m '.control'
            m 'button.clipboard.is-primary', class: (if isSeq then 'is-small'), 'コピー'
      ->
        if isSeq
          [
            m 'td', colSpan: 2, seq.eachToUpperU.join ' '
            m 'td',
              m 'img.glyph', src: "./images/te/#{seq.eachToHex.join('-')}.svg"
            m 'td', colSpan: 2, name
          ]
        else
          [
            m 'td', "U+#{if base then base.toUpperU() else id.toUpperU()}"
            m 'td', if base then 'U+' + base.toUpperU() else '-'
            m 'td',
              m 'img.glyph',
                src: ->
                  switch type
                    when "ideograph", "compat"
                      "https://glyphwiki.org/glyph/u#{if base and base isnt id then base.toLowerU() + '-u'}#{id.toLowerU()}.svg"
                    when "emoji"
                      "./images/te/#{if base then base.toString(16) + '-'}#{id.toString(16)}.svg"
                    else "./images/noimage.png"
            m 'td', ->
              if cid then m 'span', class: cid, cid
              else coll
            m 'td', name
          ]
  onupdate: ->
    new ClipboardJS '.clipboard',
      target: (trigger)->
        trigger.parentNode.previousElementSibling.children.filter( (e)-> e.tagName is 'input' )[0].value

VResult =
  view: (v)->
    m '#entries', VResult.response(query.phase)
  response: (phase)->
    switch phase
      when 'found'
        m External, code: query.word[0]
        m 'table#found.table',
          m 'thead', m 'tr',
            m 'th#copy', '表示'
            m 'th#codepoint', 'コード'
            m 'th#variation', 'セレクタ'
            m 'th#image', '画像'
            m 'th#collection', 'コレクション'
            m 'th#internal', '識別名'
        # m 'tbody#charlist', ->
          # m Row # TODO
      when 'notfound'
        m External, char: query.word[0]
        m '#notfound.message.is-warning',
          m 'p.has-text-centered.message-body', '見つかりませんでした'
      when 'wait'
        m 'message.is-primary',
          m 'p.message-body.is-loading'
      else
        m '.message.is-info',
          m 'p.has-text-centered.message-body', '以下に検索結果が表示されます'

Search =
  view: ->
    m '#search.section',
      m '#query.level.is-block-touch',
        m '.level-left',
          m '.level-item',
            m '.field.has-addons',
              m 'p.control',
                m 'input#searchbox.input', type: 'text', name: 'char', placeholder: "例：邊、270B…",
              m 'p.control',
                m 'button#search.button.is-primary', type: 'submit', value: 'search',
                  m 'span#searchlabel', '登録済の異体字を検索'
        m '.level-right',
          m '.field.level-item.is-grouped',
            m 'label.label.control',
              m 'span#selectcol', 'コレクションを指定 (IVS)'
            for ivd in NAMES
              m 'label.control.checkbox',
                m 'input', type: 'checkbox', class: 'search-filter', name: ivd, checked: true
                " #{ivd}"
      m VResult

#::: Main App :::#

TheApp =
  view: -> [
    m Header
    m Workspace
    m Search
  ]
