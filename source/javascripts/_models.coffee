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
  word: []
  phase: ""
  results: []
  filters: []
  visSeq: []

  allowed: (name)-> query.filters.indexOf(name) < 0

  filter: (name)->
    index = query.filters.indexOf name
    if index < 0 then query.filters.push name else query.filters.splice index, 1

  visible: (group)-> query.visSeq.indexOf(group) >= 0

  toggleSeq: (group)->
    index = query.visSeq.indexOf group
    if index < 0 then query.visSeq.push group else query.visSeq.splice index, 1

  input: (text)-> query.box = text

  fetch: ->
    cp = query.box.toString().searchCodePoint()

    if cp?
      query.phase = "wait"
      query.word = [cp]
      query.visSeq = []
      uhex = cp.toUpperU()
      [chunk, key] = [uhex.slice(0, uhex.length-2), uhex.slice(-2)]
      m.request
        type: "get"
        url: "./chars/#{chunk}.json"
      .then (result)->
        r = result[key]
        if r?
          # query.results.push query.build r, cp
          query.results[0] = query.build r, cp
          query.phase = "found"
        else
          query.phase = "notfound"
      .catch (error)->
        query.phase = "error"

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
      o.push
        'id': v[id]
        'type': TYPES[v[type]] or v[type]
        'name': v[name]
        'cid': COLLS[v[coll]]
        'coll': v[coll]
        'base': basechar

      o.push query.buildSeq(v[seq], [cp, v[id]]) if v[seq]
    o

  buildSeq: (seqs, bases)->
    genid = bases.join('-')
    for s in seqs
      'seq': bases.concat(s['q'])
      'name': s['n']
      'klass': genid
