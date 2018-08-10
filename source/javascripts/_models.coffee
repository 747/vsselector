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
    signboard.value = s.slice(0, o) + (+v).toUcs2() + s.slice(e)

pickerTab =
  source: "ivs"
  set: (v)-> pickerTab.source = v

query =
  word: []
  phase: ""
  results: []
  fetch: (v)->
    cp = v.toString().searchCodePoint()

    if cp?
      query.phase = "wait"
      query.word = [cp.toUcs2()]
      uhex = cp.toUpperU()
      [chunk, key] = [uhex.slice(0, uhex.length-2), uhex.slice(-2)]
      m.request
        type: "get"
        url: "./chars/#{chunk}.json"
      .then (result)->
        r = result[key]
        if r?
          results.push r
          query.phase = "found"
        else
          query.phase = "notfound"
      .catch (error)->
        query.phase = "error"
