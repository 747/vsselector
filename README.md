**GitHub Pages site**: https://747.github.io/vsselector/

# Requirements
- [Ruby](https://www.ruby-lang.org/) 2.0+ environment
- [Bundler](http://bundler.io/) gem
- gems specified in `Gemfile`

# How to update
1. Grab the latest files ([CLDR](http://cldr.unicode.org/index/downloads) and .txt files in `data`)
1. run `ruby charbuilder.rb` (mutatis mutandis if Unicode file formats have changed)
1. run `./middleman-build.sh`
