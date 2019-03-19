require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'singleton'

DATAPATH = "data"
CHARPATH = "chars-source"
FINALPATH = "build/chars"

TYPESJSON = JSON.load(File.open("#{DATAPATH}/types.json", "r:utf-8").read)
TYPES = TYPESJSON["categories"].map(&:intern)
UNTYPES = TYPES.map { |e| [e, TYPES.index(e)] }.to_h
COLLS = TYPESJSON["collections"].map(&:intern)
UNCOLLS = COLLS.map { |e| [e, COLLS.index(e)] }.to_h

RUN_AT = Time.at(Time.now.to_i)

class Variant
  attr_accessor :id, :type, :collection, :name

  def initialize(id=nil, type=nil, collection=nil, name=nil)
    @id, @type, @collection, @name = id, type, collection, name
    @seq = []
  end

  def seq(sequence)
    sequence.is_a?(Sequence) ? @seq.push(sequence) : raise("Tried to set #{sequence.inspect} as a sequence of '#{name}'!")
  end
  def seqs; @seq; end

  def serialize
    hash = {
      'i' => @id,
      't' => UNTYPES[@type] || UNTYPES[:unknown],
      'c' => UNCOLLS[@collection] || (@collection.is_a?(String) && @collection.present? ? @collection : UNCOLLS[:unknown]),
      'n' => @name
    }
    if @seq.present?
      hash['S'] ||= []
      @seq.sort_by(&:seq).each { |s| hash["S"].push s.serialize }
    end
    hash
  end

  def deserialize(h)
    @id, @type, @name = h['i'], TYPES[h['t']], h['n']
    @collection = h['c'].is_a?(Integer) ? COLLS[h['c']] : h['c']
    h['S'].each { |s| seq(Sequence.new.deserialize(s)) } if h['S'].present?
    self
  end
end

class Character
  attr_accessor :id, :type, :name

  def initialize(id=nil, type=nil, name=nil)
    @id, @type, @name = id, type, name
    @var = []
    @seq = []
  end

  def var(variant)
    variant.is_a?(Variant) ? @var.push(variant) : raise("Tried to set #{variant.inspect} as a variant of U+#{hex.upcase}!")
  end
  def vars; @var; end

  # return a variant of it or nil
  def get_var(code)
    @var.find { |v| v.id == code }
  end

  def seq(sequence)
    sequence.is_a?(Sequence) ? @seq.push(sequence) : raise("Tried to set #{sequence.inspect} as a sequence of U+#{hex.upcase}!")
  end
  def seqs; @seq; end

  def serialize
    raise "ID-less output - #{self.inspect}!" unless @id
    hash = {'t' => UNTYPES[@type] || UNTYPES[:unknown], 'n' => @name, 'V' => []}
    @var.sort_by(&:id).each { |v| hash["V"].push v.serialize }
    if @seq.present?
      hash['S'] ||= []
      @seq.sort_by(&:seq).each { |s| hash["S"].push s.serialize }
    end
    hash
  end

  def read(num, obj)
    @id = num
    @type, @name = TYPES[obj['t']], obj['n']
    obj['V'].each { |v| var(Variant.new.deserialize(v)) }
    obj['S'].each { |s| seq(Sequence.new.deserialize(s)) } if obj['S'].present?
    self
  end

  private
  def hex(id=@id); id ? id.hex4 : "ff9d"; end
end

class Sequence
  attr_accessor :seq, :name

  def initialize(seq=[], name=nil)
    @seq, @name = seq, name
  end

  def serialize
    { 'q' => @seq, 'n' => @name }
  end

  def deserialize(h)
    @seq, @name = h['q'], h['n']
    self
  end
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

versions = {std: 0, ivd: 0, emo: 0, evs: 0, ezs: 0}
chunks = Chunks.instance
get_char = -> num, cat, name {
  char = chunks.lookup(num, cat, name)
  return char
}
cjku = -> n {
  ci = [0xFA0E, 0xFA0F, 0xFA11, 0xFA13, 0xFA14, 0xFA1F, 0xFA21, 0xFA23, 0xFA24, *0xFA27..0xFA29].include? n
  "CJK #{ci ? 'COMPATIBILITY' : 'UNIFIED'} IDEOGRAPH-#{n.hex4.upcase}"
}
report = -> l, n { puts "#{l}: passing #{n}" if n % 100 == 0 }
compats = []
ivdcols = []

report["IVD", 0]
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
      ivdcols << coll unless ivdcols.include? coll
    end
  }
end

report["STD", 0]
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

      # making it order-independent
      c11y = category == :compat
      base_cat = c11y ? :ideograph : category
      base_name = c11y ? cjku[base] : name
      char = get_char[base, base_cat, base_name]

      case category
      when :compat
        char.var Variant.new(var, category, collection, desc)
        compid = desc.split('-')[1].to_i(16)
        comp = Character.new(compid, category, desc)
        comp.var Variant.new(base, :parent, :parent, cjku[base])
        compats.push comp
      when :emoji
        char.type = :plain
        vartype = desc.start_with?('emoji') ? :emoji : :plain
        char.var Variant.new(var, vartype, collection, desc)
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

# Manually define REGIONAL INDICATOR SYMBOLs
('A'..'Z').each do |letter|
  # 0x1F1A5 = 0x1F1E6 - "A".ord
  get_char[0x1F1A5 + letter.ord, :emoji, "REGIONAL INDICATOR SYMBOL LETTER #{letter}"]
end
# And FLAG
get_char[0x1F3F4, :emoji, "WAVING BLACK FLAG"]

# In current logic, some emoji non-variant sequences depend on the product of this file
# So this MUST be processed first!
report["EVS", 0]
open("#{DATAPATH}/emoji-variation-sequences.txt", "r:utf-8") do |evs|
  evs.each.with_index(1) { |line, lnum|
    report["EVS", lnum]
    case line
    when /^#\s*Version:\s*(\d[\d\.]*\d|\d)*/
      versions[:evs] = $1
    when /^\s*$|^#/; next
    else
      seq, desc, third = line.splip(';')
      base, var = seq.spliph
      third =~ /# \((\d+\.\d)\) (.*)$/
      ver_at, name = $1, $2

      char = get_char[base, :plain, name]
      vartype = desc.start_with?('emoji') ? :emoji : :plain
      char.var Variant.new(var, vartype, :standardized, desc)
    end
  }
end

# Some emoji zwj sequences depend on the product of this file for now
# This MUST be processed before emoji-zwj-sequences.txt!
report["EMOJI", 0]
open("#{DATAPATH}/emoji-sequences.txt", "r:utf-8") do |emj|
  inrange = false
  trailing = false # false -> variant mode, true -> sequence mode
  category = :emoji
  emj.each.with_index(1) { |line, lnum|
    report["EMOJI", lnum]
    case line
    when /^#\s*Version:\s*(\d[\d\.]*\d|\d)*/
      versions[:emo] = $1
    when /^#\s*Emoji (Keycap|Flag|Tag|Modifier) Sequence/
      trailing = true if %w(Keycap Flag Tag).include? $1
      inrange = true
    when /^#\s*={5,}/
      inrange = false
      trailing = false
    when /^\s*$|^#/; next
    else
      next unless inrange

      case versions[:emo]
      when "3.0"
        seq, data = line.splip(';')
        base, var, *extra = seq.spliph # Expect possible longer sequence
        type, data1 = data.splip('#')
        data2, desc = data1.splip('      ') # Is there a better way?
        bname, mname = desc.splip(',')
        # p [base, var, type, data1, data2, bname, mname].join("\t")
      when "4.0", "5.0", "11.0"
        record, comment = line.splip('#')
        seq, type, desc = record.splip(';')
        base, var, *extra = seq.spliph # Expect possible longer sequence
        bname, mname = desc.splip(':')
      else; abort("EMOJI unrecognized version!")
      end

      char = get_char[base, category, bname]

      if trailing
        the_var = char.get_var(var)
        adopter = the_var || char
        extra.unshift var unless the_var
        adopter.seq Sequence.new(extra, desc)
      else
        char.var Variant.new(var, category, :modifier, mname)
      end
      # char.output
    end
  }
end

report["EZWJ", 0]
open("#{DATAPATH}/emoji-zwj-sequences.txt", "r:utf-8") do |ezs|
  ezs.each.with_index(1) { |line, lnum|
    report["EZWJ", lnum]
    case line
    when /^#\s*Version:\s*(\d[\d\.]*\d|\d)*/
      versions[:ezs] = $1
    when /^\s*$|^#/; next
    else
      case versions[:emo]
      when "3.0"
        seq, data = line.splip(';')
        base, var, *extra = seq.spliph
        type, data1 = data.splip('#')
        data2, desc = data1.splip(/\s{3,}/)
        # bname, mname = desc.splip(',')
      when "4.0", "5.0", "11.0"
        record, comment = line.splip('#')
        seq, type, desc = record.splip(';')
        base, var, *extra = seq.spliph
        # bname, mname = desc.splip(':')
      else; abort("EZWJ unrecognized version!")
      end

      char = get_char[base, :plain, desc] # in case an unknown character -> :plain

      the_var = char.get_var(var)
      adopter = the_var || char
      extra.unshift var unless the_var
      adopter.seq Sequence.new(extra, desc)
    end
  }
end

report["COMPAT", 0]
compats.each.with_index(1) do |co, ci|
  report["COMPAT", ci]
  pa = co.vars.find { |v| v.type == :parent }
  main = get_char[pa.id, :ideograph, pa.name]
  comp = get_char[co.id, co.type, co.name]
  comp.var pa
  main.vars.each { |v| comp.var v } if main
  pa.type = :ideograph
  # co.output
end

chunks.save

puts "generates VERSIONS"
open("#{DATAPATH}/versions.json", "w:utf-8") do |ver|
  JSON.dump({
    "standardized" => versions[:std],
    "ideographic" => versions[:ivd],
    "emojivs" => versions[:evs],
    "emojisequences" => versions[:emo],
    "emojizwj" => versions[:ezs],
    "generated" => Time.now.strftime("%Y/%m/%d %R %Z"),
    # "ivd-range" => [],
    # "compat-range" => [],
    # "emoji-range" => [],
  }, ver)
end

puts "generates KNOWNNAMES"
open("#{DATAPATH}/knownnames.json", "w:utf-8") do |kno|
  JSON.dump({
    "ivdcollections" => ivdcols.sort
  }, kno)
end
