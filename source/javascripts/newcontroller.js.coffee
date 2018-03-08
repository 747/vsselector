# Pre-defined variables
# TYPES = (index-to-type name mapping)
# COLLS = (index-to-collection name mapping)
# BASE_IDX = COLLS.indexOf("base")

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

TheApp =
  view: ->
    m Header
    m Workspace
    m Search

Header =
  view: ->
    m '.navbar',
      m '.navbar-brand',
        m 'p.navbar-item', document.title
        # below are quickfix for mobile view in current ver of Bulma CSS
        m 'a.navbar-item.modality.is-hidden-desktop', dataset: {target: "#about"}, '説明'
        m 'a.navbar-item.is-hidden-desktop', href: "https://github.com/747/vsselector", target: "_blank", 'GitHub'
      m '.navbar-menu'
        m '.navbar-start'
        m '.navbar-end'
          m 'a.navbar-item.modality', dataset: {target: "#about"}, '説明'
          m 'a.navbar-item', href: "https://github.com/747/vsselector", target: "_blank", 'GitHub'

Workspace =
  view: ->
    m '#workspace.columns.section.transparent',
      m '#viewer.column.is-7',
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
BigBox =
  view: ->
    m 'textarea#bigbox.textarea.is-fullwidth', placeholder: "#{0x1F4DD.toUcs2()}..."
Picker =
  view: ->
    m '#picker.column.is-5.message.is-success',
      m 'p.message-header', '←クリックで挿入'
      m '#catalog.message-body',
        m 'ul#ivs', ->
          ivs = (x)-> 0xE0100 + x - 17
          for n in [17..256]
            m pickChar,
              id: "ivs-#{n}"
              data: "#{ivs n}"
              title: "VS#{n} (#{ivs(n).formatU()})"
              alt: "VS#{n}"
        m 'ul#vs',
          ->
            svs = (x)-> 0xFE00 + x - 1
            note = (x)-> svs(x).formatU() + if x == 15 then "; text style" else if n == 16 then "; emoji style" else ""
            for n in [1..16]
              m pickChar,
                id: "vs-#{n}"
                data: "#{svs n}"
                title: "VS#{n} (#{note(n)})"
                alt: "VS#{n}"
          ->
            fvs = (x) -> 0x180B + x - 1
            for n in [1..3]
              m pickChar,
                id="fvs-#{n}"
                data: "#{fvs n}"
                title: "Mongolian FVS#{n} (#{fvs(n).formatU()})"
                alt: "FVS#{n}"
        m 'ul#emod',
          ->
            ris = (x)-> 0x1F1E6 + x
            for n in [0..25]
              m pickChar,
                id: "region-#{n}"
                data: "#{ris n}"
                title="Regional letter #{(n+65).toUcs2()} (#{ris(n).formatU()})"
                alt="RIS #{(n+65).toUcs2()}"
                src="./images/te/#{ris(n).toLowerU()}.svg"
          ->
            emo = (x)-> 0x1F3FB + x - 2
            sc = (x)-> if x is 2 then "1-2" else n
            for n in [2..6]
              m pickChar,
                id: "fitz-#{n}"
                data: "#{emo n}"
                title: "Fitzgerald #{sc} (#{emo(n).formatU()})"
                alt: "Fitz #{sc}"
                src: "./images/te/#{emo(n).toLowerU()}.svg"
        m 'ul#util',
          m pickChar,
            id: "zwj"
            data: "#{0x200D}"
            title: "ZERO WIDTH JOINER (#{0x200D.formatU()})"
            alt="ZWJ"
          ->
            tag = (x)-> 0xE0020 + x
            t = (x)->
              if x is 0 then ["SPACE", "SP"]
              else if x is 0x5F then ["END", "END"]
              else ["\u00ab#{(x+32).toUcs2()}\u00bb", "#{(x+32).toUcs2()}"]
            # U+E001 is still deprecated
            for n in [0..0x5F]
              m pickChar,
                id: "tags-#{n}"
                data: "#{tagn}"
                title: "Tag #{t(x)[0]} (#{tag(n).formatU()})"
                alt: "Tag #{t(x)[1]}"
        m '#groups.tabs.is-centered.is-toggle',
          m 'ul',
            m 'li', m 'a.toggler', 'data-tab': "#ivs", 'IVS'
            m 'li', m 'a.toggler', 'data-tab': "#vs", '(F)VS'
            m 'li', m 'a.toggler', 'data-tab': "#emod", 'Emoji'
            m 'li', m 'a.toggler', 'data-tab': "#util", 'Utils'
PickChar =
  view: (v)->
    a = v.attrs
    m 'li', id: a.id,
      m 'a.pick', 'data-char': a.data,
        m 'img.glyph', title: a.title, alt: a.alt, src: a.src
CharList =
  view: (v)->
    c = v.children.toCodepoints()
    m 'p#breakdown-body.message-body', ->
      sum = 0
      for code in c
        offset = sum
        sum += code.toUcs2().length
        m charTag, pos: offset, code
CharTag =
  view: (v)->
    c = v.children
    color = if c.isFunctionalCodePoint then 'is-success' else 'is-info'
    m 'span.tag', class: color, dataset: { pos: v.attrs.pos, width: c.length }, c,
      m 'button.delete.delete-char'

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
                m 'input', type: 'checkbox', class: 'search-filter', name: ivd, checked: true, " #{ivd}"
      m VResult
VResult =
  view: (v)->
    m '#entries',
      m '#initial.message.is-info',
        m 'p.has-text-centered.message-body', '以下に検索結果が表示されます'
      m '#notfound.message.is-warning',
        m 'p.has-text-centered.message-body', '見つかりませんでした'
      m External
      m 'table#found.table',
        m 'thead', m 'tr',
          m 'th#copy', '表示'
          m 'th#codepoint', 'コード'
          m 'th#variation', 'セレクタ'
          m 'th#image', '画像'
          m 'th#collection', 'コレクション'
          m 'th#internal', '識別名'
      m 'tbody#charlist', ->
        m Row # TODO
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
                      "http://glyphwiki.org/glyph/u#{if base and base isnt id then base.toLowerU() + '-u'}#{id.toLowerU()}.svg"
                    when "emoji"
                      "./images/te/#{if base then base.toString(16) + '-'}#{id.toString(16)}.svg"
                    else "./images/noimage.png"
            m 'td', ->
              if cid then m 'span', class: cid, cid
              else coll
            m 'td', name
          ]
  onupdate: ->
    new Clipboard '.clipboard',
      target: (trigger)->
        trigger.parentNode.previousElementSibling.children.filter( (e)-> e.tagName is 'input' )[0].value

SeqHeader =
  view: ->
    m 'tr.content.message.is-small.is-warning.seq-header', id: id,
      m 'td.message-header', colSpan: 6, 'この字から始まるシークエンス'
External =
  view: (v)->
    id = v.attrs.children
    [
      ['CHISE', 'http://www.chise.org/est/view/character/', 'toUcs2']
      ['GlyphWiki', 'https://glyphwiki.org/wiki/u', 'toLowerU']
      ['Codepoints', 'https://codepoints.net/U+', 'toUpperU']
    ].map (l) ->
      m 'a.button.is-info', "#{l[0]}で「#{id.toUcs2()}」を表示",
        href: l[1] + id[l[2]]()
        target: '_blank'

m.mount document.getElementById('app'), TheApp