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
