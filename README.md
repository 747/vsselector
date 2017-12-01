GitHub Pages site: http://747.github.io/vsselector/

# Requirements
- Ruby 2.0+
- [http://bundler.io/](Bundler) gem
- gems specified in `Gemfile`

# How to update
1. Grab the latest files ([http://cldr.unicode.org/index/downloads](CLDR) and .txt files in `data`)
1. run `ruby charbuilder.rb` (Mutatis mutandis if Unicode file formats have changed)
1. run `./middleman-build.sh`
