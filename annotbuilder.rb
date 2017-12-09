require 'rexml/document'
require 'active_support'
require 'active_support/core_ext'
require 'json'

cpath = "data/cldr-common/common"
dirs = ["annotations", "annotationsDerived"]
langs = {en: ['en'], ja: ['ja']}

langs.each do |lang, tags|
  dict = {} # {<cp>: [<tts>, <name>...]}
  fill = -> x, y, f { dict.key?(x) ? (f ? (dict[x][0] = y) : dict[x] << y) : (dict[x] = f ? [y] : [nil, y]) }
  dirs.each { |dir|
    Dir.glob("#{cpath}/#{dir}/#{lang}*.xml") do |file|
      xml = REXML::Document.new IO.read(file, mode: "r:utf-8")
      locale = ['language', 'script', 'territory'].map { |e|
        xml.get_elements("/ldml/identity/#{e}").first.try(:attribute, 'type').try(:value)
      }
      next if tags.find.with_index { |e, i| e.present? && locale[i].blank? }

      xml.each_element("/ldml/annotations/annotation") { |a|
        char = a.attribute('cp').to_s.intern
        names = a.get_text.to_s.split("|")
        tts = a.attribute('type').try(:value) == 'tts'

        if tts
          # warn "TTS overridden! #{char} - #{a.text} @ #{file}" if dict[char].try(:at, 0).present?
          next if dict[char].try(:at, 0).present?
          fill[char, names[0].strip, true]
          next
        end

        names.each do |t|
          fill[char, t.strip, false]
        end
      }
    end
  }

  chardef = []
  lookup = []
  dict.keys.sort.each { |k|
    chardef << ["#{k}", dict[k][0]]
    dict[k][1..-1].each do |n|
      warn "No TTS #{lang}: #{k} (#{k.to_s.ord.to_s(16)})" if dict[k][0].blank?
      lookup << [n, chardef.size - 1]
    end
  }
  open("utils-source/#{lang}.json", "w:utf-8") { |out|
    JSON.dump({
      "D" => chardef,
      "L" => lookup.sort { |a, b| (a[0] <=> b[0]).nonzero? || a[1] <=> b[1] },
    }, out)
  }

  dfile = IO.read("#{cpath}/dtd/ldml.dtd", mode: "r:utf-8")
  # Ruby doesn't have a working DTD parser!
  dfile.match(/<!ATTLIST version cldrVersion CDATA #FIXED "(\w+)" >/) do |m|
    version = "data/versions.json"
    vers = JSON.parse(IO.read(version, mode: "r:utf-8"))
    vers["cldr"] = m[1]
    open(version, "w:utf-8") { |ver| JSON.dump vers, ver }
  end
end
