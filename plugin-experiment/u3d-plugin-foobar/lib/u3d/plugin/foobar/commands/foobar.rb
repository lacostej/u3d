
module U3d
  module Plugin
    class FoobarCommand
      def command(c)
        c.syntax = 'u3d foobar'
        c.summary = 'Foobar something'
        c.description =  %(
  #{c.summary}

  Do something important.
        )
        c.action do |args, options|
          run(args: args, options: options)
        end
      end
      def run(args: [], options: {})
        puts "foobar"
        puts args
        puts options      
      end
    end
  end
end