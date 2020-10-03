###
# run!
###

m.route document.getElementById('app'), '',
  '': TheApp
  '/:lang': TheApp
  '/:lang/:qstr': TheApp
  '/:lang/:qstr/:bbtxt': TheApp
