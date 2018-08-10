require 'yaml'

def create(conf)
  config = YAML.load_file conf
  config.each do |name, seq|
    default_dir = File.dirname name
    open(name, 'w:utf-8') { |out|
      seq.each do |entry|
        path = File.dirname(entry) == '.' ? "#{default_dir}/#{File.basename(entry)}" : entry
        out.puts File.read(path, encoding: 'utf-8')
      end
    }
  end
end

def delete(conf)
  config = YAML.load_file conf
  config.each do |name, _|
    File.delete name
  end
end

self.send(ARGV[0].intern, ARGV[1])