**GitHub Pages site**: https://747.github.io/vsselector/

# Requirements
- environment with Bash

- [Ruby](https://www.ruby-lang.org/) 2.0+ environment
- [Bundler](http://bundler.io/) gem
- gems specified in `Gemfile`

- [Node.js](https://nodejs.org/) (tested with v12)
- [Yarn 2](https://yarnpkg.com/) (and probably [npm](https://github.com/npm/cli))
- packages specified in `package.json`

# How to update
1. Grab the latest files ([CLDR](http://cldr.unicode.org/index/downloads) and .txt files in `data`)
1. run `ruby charbuilder.rb` (mutatis mutandis if Unicode file formats have changed)
1. run `ruby annotbuilder.rb` (same as above)
1. copy all files in `chars-source` and `utils-source` into `www/chars` and `www/utils` respectively
1. run `./harp-build.sh`
1. run `./gh-deploy.sh`
