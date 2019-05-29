list = File.readlines("#{__dir__}/Twemoji filenames.txt", encoding: 'utf-8')
  .select { |l| /^[\s#]/ !~ l }
  .map { |e| /^([-\h]+\.svg) should be ([-\h]+\.svg)/.match(e)&.[](1..2) }.to_h

Dir.open("#{__dir__}/../te-source/", encoding: 'utf-8') do |d|
  d.each { |f| File.rename(d.path << f, d.path << list[f]) if list[f] }
  # d.each_child { |f| File.rename(d.path << f, d.path << list[f]) if list[f] } # >= Ruby 2.6
end