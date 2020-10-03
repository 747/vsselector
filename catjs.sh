#!/bin/sh
cat public/js/_sprintf.min.js public/js/_clipboard.min.js public/js/_mithril.min.js public/js/_fuse.js > public/js/library.js
cat public/js/_helper_funcs.coffee public/js/_about.coffee public/js/_models.coffee public/js/_messages.coffee public/js/_views.coffee public/js/_newcontroller.coffee > public/js/vsapp.coffee
