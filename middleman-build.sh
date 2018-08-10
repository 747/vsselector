#!/bin/sh
mv build/chars chars-temp
mv build/images/te te-temp
mv build/utils utils-temp
ruby manual_concat.rb create generation.yml
bundle exec middleman build --verbose
ruby manual_concat.rb delete generation.yml
mv chars-temp build/chars
mv te-temp build/images/te
mv utils-temp build/utils
