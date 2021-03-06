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
