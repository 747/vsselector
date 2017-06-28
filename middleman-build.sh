#!/bin/sh
mv build/chars chars-temp
mv build/images/te te-temp
bundle exec middleman build --verbose
mv chars-temp build/chars
mv te-temp build/images/te
