require 'yaml'

DATAPATH = "source/data"
CHARPATH = "chars-source"
FINALPATH = "build/ivd/chars"
TYPES = YAML.load_file("#{DATAPATH}/types.json").map(&:intern)
UNTYPES = TYPES.map { |e| [e, TYPES.index(e)] }.to_h


class Variant
  attr_accessor :id, :type, :collection, :name

  def initialize(id=nil, type=nil, collection=nil, name=nil)
    @id, @type, @collection, @name = id, type, collection, name
  end

  def serialize
    {'i' => @id, 't' => UNTYPES[@type] || UNTYPES[:unknown], 'c' => @collection, 'n' => @name}
  end

  def deserialize(h)
    @id, @type, @collection, @name = h['i'], TYPES[h['t']], h['c'], h['n']
    self
  end
end

class Character
  @@path = CHARPATH
  attr_accessor :id, :type, :name

  def initialize(id=nil, type=nil, name=nil)
    @id, @type, @name = id, type, name
    @var = []
  end

  def var(variant)
    variant.is_a?(Variant) ? @var.push(variant) : raise("Tried to set #{variant.inspect} as a variant of U+#{hex.upcase}!")
  end

  def vars
    @var
  end

  def output
    raise "ID-less output - #{self.inspect}!" unless @id
    hash = {'t' => UNTYPES[@type] || UNTYPES[:unknown], 'n' => @name, 'V' => []}
    @var.sort_by(&:id).each { |v| hash["V"].push v.serialize }
    open(dest, "w:utf-8") { |io| io.write YAML.to_json(hash)}
  end

  def read(num)
    return nil unless File.exist?(dest(num))
    obj = YAML.load_file(dest(num))
    @id = num
    @type, @name = TYPES[obj['t']], obj['n']
    obj['V'].each { |v| var(Variant.new.deserialize(v)) }
    self
  end

  private
  def hex(id=@id); id ? id.hex4 : "ff9d"; end
  def dest(id=@id); "#{@@path}/#{hex(id)}.json"; end
end

class Integer
  def hex4; sprintf("%04X", self); end
end
class String
  def splip(sep); self.split(sep).map(&:strip); end
  def spliph(sep=' '); self.splip(sep).map { |e| e.to_i(16) }; end
end

versions = {std: 0, ivd: 0, emo: 0}
get_char = -> num, cat, name {
  char = Character.new.read(num) || char = Character.new(num, cat, name)
  return char
}
cjku = -> n { "CJK UNIFIED IDEOGRAPH-#{n.hex4.upcase}" }
report = -> l, n { puts "#{l}: passing #{n}" if n % 100 == 0 }
compats = []

open("#{DATAPATH}/IVD_Sequences.txt", "r:utf-8") do |ivs|
  version_got = false
  category = :ideograph
  ivs.each.with_index(1) { |line, lnum|
    report["IVD", lnum]
    case line
    when /^#\s*(\d{4}-\d{2}-\d{2})/
      next if version_got
      versions[:ivd] = $1
      version_got = true
    when /^\s*$|^#/; next
    else
      seq, coll, orig = line.splip(';')
      base, var = seq.spliph

      char = get_char[base, category, cjku[base]]
      char.var Variant.new(var, category, coll, orig)
      char.output
    end
  }
end

open("#{DATAPATH}/StandardizedVariants.txt", "r:utf-8") do |svs|
  category = :unknown
  collection = "Standardized"
  svs.each.with_index(1) { |line, lnum|
    report["STD", lnum]
    case line
    when /^# StandardizedVariants-([\d\.]*\d)\.txt/
      versions[:std] = $1
    when /^# (?:CJK )*(Math|Myanmar|Phags-pa|Manichaean|Mongolian|Emoji|compat)/
      category = $1.gsub('-', '').downcase.intern
    when /^\s*$|^#/; next
    else
      seq, desc, third = line.splip(';')
      base, var = seq.spliph
      context, name = third.splip('#')

      char = get_char[base, category, name]

      case category
      when :compat
        char.type = :ideograph
        char.name = cjku[base]
        char.var Variant.new(var, category, collection, desc)
        compid = desc.split('-')[1].to_i(16)
        comp = Character.new(compid, category, desc)
        comp.var Variant.new(base, :parent, "Parent", cjku[base])
        compats.push comp
      when :emoji
        char.type = :plain
        char.var Variant.new(var, category, collection, desc)
      when :mongolian, :manichaean
        xdesc = desc << " (#{context})"
        char.var Variant.new(var, category, collection, xdesc)
      else
        char.var Variant.new(var, category, collection, desc)
      end
      char.output
    end
  }
end

open("#{DATAPATH}/emoji-sequences.txt", "r:utf-8") do |emj|
  inrange = false
  category = :emoji
  emj.each.with_index(1) { |line, lnum|
    report["EMOJI", lnum]
    case line
    when /^#\s*Date:\s*(\d{4}-\d{2}-\d{2})/
      versions[:emo] = $1
    when /^#\s*Emoji Modifier Sequence/
      inrange = true
    when /^#\s*={5,}/
      inrange = false
    when /^\s*$|^#/; next
    else
      next unless inrange
      seq, data = line.splip(';')
      base, var = seq.spliph
      type, data1 = data.splip('#')
      data2, names = data1.splip('   ')
      bname, mname = names.splip(',')
p base, var, type, bname, mname
      char = get_char[base, category, bname]
      char.var Variant.new(var, category, "Emoji Modifier", mname)
      char.output
    end
  }
end

compats.each do |co|
  pa = co.vars.find { |v| v.type == :parent }
  main = get_char[pa.id, :ideograph, pa.name]
  main.vars.each { |v| co.var v } if main
  co.output
end

open("#{DATAPATH}/versions.json", "w:utf-8") do |ver|
  ver.write YAML.to_json({
    "standardized" => versions[:std],
    "ideographic" => versions[:ivd],
    "emojisequences" => versions[:emo],
    "generated" => Time.now.strftime("%Y/%m/%d %R %Z")
  })
end
