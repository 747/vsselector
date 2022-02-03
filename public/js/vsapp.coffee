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
###
# == Modal (instructions) control ==
###

elAbout = document.getElementById('about')

popup = ->
  elAbout.className += ' is-active'

document.getElementById('unmodal').onclick = ->
  elAbout.className = elAbout.className.replace /(?:^|\s)is-active(?![-\w])/g, ''
###
# == VDOM models ==
###

uiLang =
  value: "ja"
  reset: true
  set: (v)->
    old = uiLang.value
    uiLang.value = if v then v else 'ja'
    uiLang.reset = if uiLang.value is old then false else true

signboard =
  value: ""
  set: (v)-> signboard.value = v
  del: (p, w)->
    if numlike(p) and numlike(w)
      s = signboard.value
      signboard.value = s.slice(0, +p) + s.slice(+p + +w)
    return false
  ins: (v)->
    area = document.getElementById 'bigbox'
    [s, o, e] = [signboard.value, area.selectionStart, area.selectionEnd]
    signboard.value = s.slice(0, o) + v + s.slice(e)

pickerTab =
  source: "ivs"
  set: (v)-> pickerTab.source = v

query =
  box: ""
  boxed: ""
  word: []
  phase: ""
  results: []
  error: ""
  filters: []
  tab: undefined
  visSeq: []

  allowed: (name)-> name not in query.filters

  filter: (name)->
    index = query.filters.indexOf name
    if index < 0 then query.filters.push name else query.filters.splice index, 1

  show: (idx)-> query.tab = idx

  visible: (group)-> group in query.visSeq

  toggleSeq: (group)->
    index = query.visSeq.indexOf group
    if index < 0 then query.visSeq.push group else query.visSeq.splice index, 1

  input: (text)-> query.box = text

  fetch: ->
    cp = query.box.toString().searchCodePoint()

    if cp?
      query.phase = "wait"
      query.word = cp
      query.results = []
      query.tab = undefined
      query.visSeq = []

      hexes = (c.toUpperU() for c in cp)
      chunks = (e.slice(0, e.length-2) for e in hexes)
      keys = (e.slice(-2) for e in hexes)
      Promise.all (query.request(ch) for ch in chunks)
      .then (results)->
        for res, i in results
          r = res[keys[i]]
          query.results[i] = if r? then query.build(r, cp[i]) else undefined
        query.phase = "got"
        query.tab = 0
      .catch (error)->
        query.phase = "error"
        query.error = error.message

  request: (block)->
    m.request
      type: "get"
      url: "./chars/#{block}.json"

  build: (r, cp)->
    [o, id, type, name, vars, coll, seq] = [[], "i", "t", "n", r["V"], "c", "S"]
    cat = TYPES[r[type]]
    basechar = if TYPES[r[type]] == 'compat' then vars[0][id] else cp

    o.push
      'id': cp
      'type': cat or r[type]
      'name': r[name]
      'cid': "base"

    o.push query.buildSeq(r[seq], [cp]) if r[seq]

    for v in vars
      cname = COLLS[v[coll]]
      o.push
        'id': v[id]
        'type': TYPES[v[type]] or v[type]
        'name': v[name]
        'cid': cname
        'coll': v[coll]
        'base': basechar unless cname is 'parent'

      o.push query.buildSeq(v[seq], [cp, v[id]]) if v[seq]
    o

  buildSeq: (seqs, bases)->
    genid = bases.join('-')
    for s in seqs
      'seq': bases.concat(s['q'])
      'name': s['n']
      'klass': genid

hint =
  loaded: false
  data: []
  searcher: undefined
  max: 20

  suggest: (text)->
    @searcher.search(text).slice(0, @max)

  load: ->
    langs = ['en']
    langs.push uiLang.value unless uiLang.value is 'en-us'
    hint.loaded = false
    Promise.all (hint.request(ln) for ln in langs)
    .then (results)->
      for res in results
        rd = res['D']
        for entry, refs of res['L']
          for r in refs
            hint.data.push
              label: entry
              value: rd[r][0]
              desc: rd[r][1]
      hint.searcher = new Fuse hint.data,
        includeMatches: true
        threshold: 0.4
        keys: ['label']
      hint.loaded = true if hint.searcher

  request: (lang)->
    m.request
      type: "get"
      url: "./utils/#{lang}.json"
messages =
  langname:
    'ja': '日本語'
    'en-us': 'English'
    'zh-hans': '简体中文'
    'zh-hant': '繁體中文'
  lang:
    'ja': '言語'
    'en-us': 'Language'
    'zh-hans': '语言'
    'zh-hant': '語言'
  title:
    'ja': '異体字セレクタセレクタ'
    'en-us': 'Variation Selector Selector'
    'zh-hans': '选异选'
    'zh-hant': '選異選'
  help:
    'ja': '説明'
    'en-us': 'Help'
    'zh-hans': '简易指南'
    'zh-hant': '簡易指南'
  github:
    'ja': 'GitHub'
    'en-us': 'GitHub'
    'zh-hans': 'GitHub'
    'zh-hant': 'GitHub'
  tab_ivs:
    'ja': 'IVS'
    'en-us': 'IVS'
    'zh-hans': 'IVS'
    'zh-hant': 'IVS'
  tab_vs:
    'ja': '(F)VS'
    'en-us': '(F)VS'
    'zh-hans': '(F)VS'
    'zh-hant': '(F)VS'
  tab_emoji:
    'ja': '絵文字'
    'en-us': 'Emoji'
    'zh-hans': 'Emoji'
    'zh-hant': '表情圖示'
  tab_utils:
    'ja': '補助'
    'en-us': 'Utils'
    'zh-hans': '辅助'
    'zh-hant': '輔助'
  paste_left:
    'ja': '⬅クリックで挿入'
    'en-us': 'Click to paste to left'
    'zh-hans': '点字放进左栏'
    'zh-hant': '點字放進左欄'
  paste_up:
    'ja': '⬆クリックで挿入'
    'en-us': 'Click to paste up'
    'zh-hans': '点字放进上栏'
    'zh-hant': '點字放進上欄'
  share:
    'ja': '内容をシェア'
    'en-us': 'Share to:'
    'zh-hans': '分享到'
    'zh-hant': '分享到'
  share_tag:
    'ja': '異体字セレクタセレクタ'
    'en-us': 'vsselector'
    'zh-hans': '选异选'
    'zh-hant': '選異選'
  external:
    'ja': '%(site)s で「%(char)s」を表示'
    'en-us': 'Lookup ‹%(char)s› on %(site)s'
    'zh-hans': '%(site)s 上查看“%(char)s”字'
    'zh-hant': '%(site)s 上查看「%(char)s」字'
  insert:
    'ja': '⬆挿入'
    'en-us': 'Insert ⬆'
    'zh-hans': '⬆粘贴'
    'zh-hant': '⬆貼上'
  copy:
    'ja': 'コピー'
    'en-us': 'Copy'
    'zh-hans': '复制'
    'zh-hant': '複製'
  open_seq:
    'ja': 'この字から始まるシークエンス'
    'en-us': 'Sequences starting with this variant'
    'zh-hans': '展开以此字开头的序列'
    'zh-hant': '展開以此字開頭的序列'
  close_seq:
    'ja': 'このシークエンスを閉じる'
    'en-us': 'Hide sequences'
    'zh-hans': '关闭序列列表'
    'zh-hant': '關閉序列列表'
  col_actual:
    'ja': '表示'
    'en-us': 'Output'
    'zh-hans': '字符'
    'zh-hant': '字符'
  col_code:
    'ja': 'コード'
    'en-us': 'Code Point'
    'zh-hans': '主字码位'
    'zh-hant': '主字碼位'
  col_var:
    'ja': 'セレクタ'
    'en-us': 'Selector'
    'zh-hans': '选择符'
    'zh-hant': '選擇符'
  col_image:
    'ja': '画像'
    'en-us': 'Image'
    'zh-hans': '字样'
    'zh-hant': '字樣'
  col_collection:
    'ja': 'コレクション'
    'en-us': 'Collection'
    'zh-hans': '集合'
    'zh-hant': '集合'
  col_source:
    'ja': '識別名'
    'en-us': 'Identifier'
    'zh-hans': '标识名称'
    'zh-hant': '識別名稱'
  not_found:
    'ja': '見つかりませんでした'
    'en-us': 'Not found.'
    'zh-hans': '无查询结果可显示'
    'zh-hant': '無查詢結果可顯示'
  search_init:
    'ja': '以下に検索結果が表示されます'
    'en-us': 'Your search results will show up here.'
    'zh-hans': '这里显示查询结果'
    'zh-hant': '此處顯示查詢結果'
  example:
    'ja': '例　1F468:ハート:葛飾'
    'en-us': 'ex. 1F468:heart:葛飾'
    'zh-hans': '例　1F468:heart:葛飾'
    'zh-hant': '例　1F468:heart:葛飾'
  search_button:
    'ja': '登録済の異体字を検索'
    'en-us': 'Search available variants'
    'zh-hans': '查询已编码的变体'
    'zh-hant': '查詢已編碼的變體'
  collections:
    'ja': 'コレクションを表示 (IVS)'
    'en-us': 'Toggle by collection (IVS)'
    'zh-hans': '按 IVS 集合筛选'
    'zh-hant': '依 IVS 集合篩選'
  coll_base:
    'ja': '基底文字'
    'en-us': 'Base'
    'zh-hans': '基本字符'
    'zh-hant': '基本字符'
  coll_parent:
    'ja': '親文字'
    'en-us': 'Parent'
    'zh-hans': '父字符'
    'zh-hant': '父字符'
  coll_standardized:
    'ja': '標準異体字'
    'en-us': 'Standardized'
    'zh-hans': '标准变体'
    'zh-hant': '標準變體'
  coll_modifier:
    'ja': '修飾文字'
    'en-us': 'Modifier'
    'zh-hans': '修饰符'
    'zh-hant': '修飾符'
  coll_unknown:
    'ja': '不明'
    'en-us': 'Unknown'
    'zh-hans': '未知'
    'zh-hant': '未知'
  very_useful_content:
    'ja': '常中：'
    'en-us': 'Constant: '
    'zh-hans': '常中：'
    'zh-hant': '常中：'

I = (key)->
  k = key.toLowerCase()
  if messages[k]
    messages[k][uiLang.value] or messages[k]['ja']
  else
    "Message <<#{k}>>?"
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
    m '.navbar.is-dark.is-fixed-top',
      m '.navbar-brand.is-clipped',
        m 'p.site-title.navbar-item.is-clipped.has-background-link',
          m 'b.is-clipped', I 'title'
          "\u00A0(β)"
      m '.navbar-menu',
        m '.navbar-start'
        m '.navbar-end',
          m '.navbar-item.has-dropdown.is-hoverable',
            m 'a.navbar-link',
              m 'img.icon.is-large[src="images/translate-2.svg"]', title: I 'lang', alt: I 'lang'
            m '.navbar-dropdown', do ->
              for t, l of messages['langname'] when t isnt uiLang.value
                m "a.navbar-item[href=/#{t}/#{query.box.encodeAsParam()}]", oncreate: m.route.link, l
          m 'a.navbar-item.modality',
            onclick: Header.modal
            I 'help'
          m 'a.navbar-item', href: "https://github.com/747/vsselector", target: "_blank",
            m 'img.icon.is-large[src="images/github.svg"]', title: I 'github', alt: I 'github'

#::: Very Useful Shortcuts :::#

UsefulBar =
  view: ->
    m '.notification.has-text-white.transparent',
      m 'strong.has-text-black.has-text-weight-bold', I 'very_useful_content'
      m 'a.tag.is-info',
        txt: '竈門禰󠄀豆子　※「禰󠄀」は「ネ＋爾」が正しい表記となります。',
        onclick: m.withAttr 'txt', signboard.ins
        '竈門禰󠄀豆子'
      ' '
      m 'a.tag.is-info',
        txt: '煉󠄁獄杏寿郎　※「煉󠄁」は「火＋東」が正しい表記となります。',
        onclick: m.withAttr 'txt', signboard.ins
        '煉󠄁獄杏寿郎'
      ' '
      m 'a.tag.is-info',
        txt: '鬼舞辻󠄀無惨　※「辻󠄀」はしんにょうの点が1つの字が正しい表記となります。',
        onclick: m.withAttr 'txt', signboard.ins
        '鬼舞辻󠄀無惨'
      ' '
      m 'a.tag.is-info',
        txt: '鋼鐡塚蛍',
        onclick: m.withAttr 'txt', signboard.ins
        '(鋼鐡塚蛍)'

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
                      src: "./images/ne/emoji_u#{ris(n).toLowerU()}.svg"
                do ->
                  emo = (x)-> 0x1F3FB + x - 2
                  sc = (x)-> if x is 2 then "1-2" else n
                  for n in [2..6]
                    m PickChar,
                      id: "fitz-#{n}"
                      data: emo n
                      title: "Fitzgerald #{sc(n)} (#{emo(n).formatU()})"
                      alt: "Fitz #{sc(n)}"
                      src: "./images/ne/emoji_u#{emo(n).toLowerU()}.svg"
                do ->
                  emc = (x)-> 0x1F9B0 + x
                  tx = (x)-> ['red hair', 'curly hair', 'bald', 'white hair'][x]
                  for n in [0..3]
                    m PickChar,
                      id: "ecom-#{n}"
                      data: emc n
                      title: "Emoji component #{tx(n)} (#{emc(n).formatU()})"
                      alt: tx(n).charAt(0).toUpperCase() + tx(n).slice(1)
                      src: "./images/ne/emoji_u#{emc(n).toLowerU()}.svg"
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
    m '#workspace.columns.is-multiline.section.transparent',
      m '#useful.column.is-full',
        m UsefulBar
      m '.columns.is-full',
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
          m '.control',
            m 'button.button.clipboard.is-primary',
              class: (if seq then 'is-small'),
              'data-clipboard-text': Row.calcChar(seq, base, id)
              I 'copy'
      do ->
        if seq
          code = seq.eachToLowerU().join('_')
          path = if 0x1F1E6 <= seq[0] <= 0x1F1FF or seq[0] is 0x1F3F4
            "./images/te/#{code.replace(/_/g, '-')}.svg"
          else if MISSING.indexOf(code) >= 0
            "./images/ne/supp/emoji_u#{code}.svg"
          else
            "./images/ne/emoji_u#{code}.svg"
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
                      code = "#{if base then base.toLowerU() + '_' else ''}#{id.toLowerU()}"
                      "./images/ne#{if MISSING.indexOf(code) >= 0 then '/supp' else ''}/emoji_u#{code}.svg"
                    else "./images/noimage.svg"
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
  onupdate: ->
    if uiLang.reset
      uiLang.reset = false
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
###
# run!
###

onMatch = (a)->
  uiLang.set a.lang
  document.body.setAttribute 'lang', uiLang.value
  document.title = I 'title'
  document.getElementById('about-title').textContent = (I 'title') + ' (β)'
  signboard.set a.bbtxt.decodeAsParam() if a.bbtxt
  if a.qstr
    decode = a.qstr.decodeAsParam()
    unless query.boxed is decode
      query.input decode
      query.fetch()
    query.boxed = decode
  TheApp

m.route document.getElementById('app'), '',
  '':                    onmatch: (a, p)-> onMatch a
  '/:lang':              onmatch: (a, p)-> onMatch a
  '/:lang/:qstr':        onmatch: (a, p)-> onMatch a
  '/:lang/:qstr/:bbtxt': onmatch: (a, p)-> onMatch a
