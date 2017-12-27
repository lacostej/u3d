require 'commander'

module Program
  class Commands
  	def self.do(args: [], options: {})
      puts "do"
  		puts args
  		puts options
    end

  	def self.sub(args: [], options: {})
      puts "sub"
  		puts args
  		puts options
    end
  end
end

module Program
  class CommandsGenerator
    include Commander::Methods

    def self.run
      new.run
    end

    def run
      program :version, '1.0'
      program :description, 'Description'
      program :help, 'Authors', 'Jerome Lacoste <jerome@wewanttoknow.com>'

      global_option('--verbose', 'Run in verbose mode') { puts "verbose" }

      command :do do |c|
        c.syntax = 'u3d do [-a | --arg <string>] [-b | --bar]'
        c.summary = 'Do something'
        c.description =  %(
#{c.summary}

Do something important.
        )
        c.option '-a', '--arg STRING', String, 'Arg argument'
        c.option '-b', '--bar', 'Bar argument'
        c.action do |args, options|
          Program::Commands.do(args: args, options: options)
        end
      end

      command :sub do |c|
        c.syntax = "u3d sub <one | two | three>"
        c.description = 'A command with sub command'
        c.action do |args, options|
          Program::Commands.sub(args: args, options: options)
        end
      end

      default_command :do

      run!
    end
  end
end



Program::CommandsGenerator.run