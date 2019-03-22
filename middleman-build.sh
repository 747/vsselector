#!/bin/sh
mv build/chars chars-temp
mv build/images/te te-temp
mv build/utils utils-temp
bundle exec middleman build
mv chars-temp build/chars
mv te-temp build/images/te
mv utils-temp build/utils
