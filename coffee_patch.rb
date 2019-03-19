require 'execjs'
require 'coffee_script/source'

module CoffeeScript
  # module Source
    class << self
      alias :__compile :compile
      def compile(script, options = {})
        options[:bare] = true
        __compile(script, options)
      end
    end
  # end
end
