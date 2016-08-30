#!/bin/sh
mv build/chars chars-temp
mv build/images/e1 e1-temp
bundle exec middleman build --verbose
mv chars-temp build/chars
mv e1-temp build/images/e1
