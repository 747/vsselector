###
# == Modal (instructions) control ==
###

elAbout = document.getElementById('about')

popup = ->
  elAbout.className += ' is-active'

document.getElementById('unmodal').onclick = ->
  elAbout.className = elAbout.className.replace /(?:^|\s)is-active(?![-\w])/g, ''