require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'singleton'

DATAPATH = "data"
CHARPATH = "chars-source"
FINALPATH = "build/ivd/chars"

TYPESJSON = JSON.load(File.open("#{DATAPATH}/types.json", "r:utf-8").read)
TYPES = TYPESJSON["categories"].map(&:intern)
UNTYPES = TYPES.map { |e| [e, TYPES.index(e)] }.to_h
COLLS = TYPESJSON["collections"].map(&:intern)
UNCOLLS = COLLS.map { |e| [e, COLLS.index(e)] }.to_h

RUN_AT = Time.now

class Variant
  attr_accessor :id, :type, :collection, :name

  def initialize(id=nil, type=nil, collection=nil, name=nil)
    @id, @type, @collection, @name = id, type, collection, name
  end

  def serialize
    {
      'i' => @id,
      't' => UNTYPES[@type] || UNTYPES[:unknown],
      'c' => UNCOLLS[@collection] || (@collection.is_a?(String) && @collection.present? ? @collection : UNCOLLS[:unknown]),
      'n' => @name
    }
  end

  def deserialize(h)
    @id, @type, @name = h['i'], TYPES[h['t']], h['n']
    @collection = h['c'].is_a?(Integer) ? COLLS[h['c']] : h['c']
    self
  end
end

class Character
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

  def serialize
    raise "ID-less output - #{self.inspect}!" unless @id
    hash = {'t' => UNTYPES[@type] || UNTYPES[:unknown], 'n' => @name, 'V' => []}
    @var.sort_by(&:id).each { |v| hash["V"].push v.serialize }
    hash
  end

  def read(num, obj)
    @id = num
    @type, @name = TYPES[obj['t']], obj['n']
    obj['V'].each { |v| var(Variant.new.deserialize(v)) }
    self
  end

  private
  def hex(id=@id); id ? id.hex4 : "ff9d"; end
end

class Chunks < Hash
  include Singleton

  @@working_chunk = nil
  @@path = CHARPATH

  def lookup(num, cat, name)
    chunk = num.hex4.to(-3)
    unless chunk == @@working_chunk
      save
      load chunk
    end
    access num, cat, name
  end

  def save
    return nil unless @@working_chunk
    hash = {}
    self.sort.each { |k, v| hash[k] = v.serialize }
    open(dest, "w:utf-8") { |io| JSON.dump(hash, io) }
    self.clear
  end

  def load(chunk)
    path = dest(chunk)
    if File.exist?(path) && File.mtime(path) >= RUN_AT
      obj = JSON.load(open(dest(chunk), "r:utf-8").read)
      obj.each_pair { |k, v| self[k] = Character.new.read(k, v) }
    end
    @@working_chunk = chunk
  end

  private
  def access(num, cat, name)
    key = num.hex4.last(2)
    unless self[key]
      char = Character.new(num, cat, name)
      self[key] = char
    end
    self[key]
  end
  def dest(id=@@working_chunk); "#{@@path}/#{id}.json"; end
end

class Integer
  def hex4; sprintf("%04X", self); end
end
class String
  def splip(sep); self.split(sep).map(&:strip); end
  def spliph(sep=' '); self.splip(sep).map { |e| e.to_i(16) }; end
end

versions = {std: 0, ivd: 0, emo: 0}
chunks = Chunks.instance
get_char = -> num, cat, name {
  char = chunks.lookup(num, cat, name)
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
      # char.output
    end
  }
end

open("#{DATAPATH}/StandardizedVariants.txt", "r:utf-8") do |svs|
  category = :unknown
  collection = :standardized
  svs.each.with_index(1) { |line, lnum|
    report["STD", lnum]
    case line
    when /^# StandardizedVariants-(\d[\d\.]*\d|\d)\.txt/
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
        comp.var Variant.new(base, :parent, :parent, cjku[base])
        compats.push comp
      when :emoji
        char.type = :plain
        char.var Variant.new(var, category, collection, desc)
      when :mongolian, :manichaean
        xdesc = context.present? ? desc << " (#{context})" : desc
        char.var Variant.new(var, category, collection, xdesc)
      else
        char.var Variant.new(var, category, collection, desc)
      end
      # char.output
    end
  }
end

open("#{DATAPATH}/emoji-sequences.txt", "r:utf-8") do |emj|
  inrange = false
  category = :emoji
  emj.each.with_index(1) { |line, lnum|
    report["EMOJI", lnum]
    case line
    when /^#\s*Version:\s*(\d[\d\.]*\d|\d)*/
      versions[:emo] = $1
    when /^#\s*Emoji Modifier Sequence/
      inrange = true
    when /^#\s*={5,}/
      inrange = false
    when /^\s*$|^#/; next
    else
      next unless inrange

      case versions[:emo]
      when "3.0"
        seq, data = line.splip(';')
        base, var = seq.spliph
        type, data1 = data.splip('#')
        data2, names = data1.splip('      ') # Is there a better way?
        bname, mname = names.splip(',')
        # p [base, var, type, data1, data2, bname, mname].join("\t")
      when "4.0"
        seq, type, desc = line.splip(';')
        base, var = seq.spliph
        bname, mname = desc.splip(',')
      else; next
      end

      char = get_char[base, category, bname]
      char.var Variant.new(var, category, :modifier, mname)
      # char.output
    end
  }
end

compats.each do |co|
  pa = co.vars.find { |v| v.type == :parent }
  main = get_char[pa.id, :ideograph, pa.name]
  comp = get_char[co.id, co.type, co.name]
  comp.var pa
  main.vars.each { |v| comp.var v } if main
  pa.type = :ideograph
  # co.output
end

chunks.save

open("#{DATAPATH}/versions.json", "w:utf-8") do |ver|
  JSON.dump({
    "standardized" => versions[:std],
    "ideographic" => versions[:ivd],
    "emojisequences" => versions[:emo],
    "generated" => Time.now.strftime("%Y/%m/%d %R %Z")
  }, ver)
end
