require 'commander'

module U3d
  module Plugin
    class DoCommand
      def command(c)
        c.syntax = 'u3d do [-a | --arg <string>] [-b | --bar]'
        c.summary = 'Do something'
        c.description =  %(
  #{c.summary}

  Do something important.
        )
        c.option '-a', '--arg STRING', String, 'Arg argument'
        c.option '-b', '--bar', 'Bar argument'
        c.action do |args, options|
          run(args: args, options: options)
        end
      end
      def run(args: [], options: {})
        puts "do"
        puts args
        puts options      
      end
    end
  end
end


module U3d
  module Plugin
    class SubCommand
      def command(c)
        c.syntax = "u3d sub <one | two | three>"
        c.description = 'A command with sub command'
        c.action do |args, options|
          run(args: args, options: options)
        end
      end
      def run(args: [], options: {})
        puts "sub"
        puts args
        puts options      
      end
    end
  end
end

module Program
  class PluginRegister
    require 'bundler'

    include Commander::Methods

    def initialize
      @bundled_plugin_names = ['do', 'sub']
      @discovered_plugin_names = []
      load_plugins
      initialize_register
      register_commands
    end

    private

    def load_plugins
      available_plugins.each do |gem_name|
        puts "Loading '#{gem_name}' plugin"
        begin
          req = gem_name.tr("-", "/")
          puts "req: #{req}"
          require  req # from "u3d-plugin-foobar" to "u3d/plugin/foobar"
          store_plugin_reference(gem_name)
        rescue => ex
          puts ex.class
          puts ex.backtrace
          puts "Error loading plugin '#{gem_name}': #{ex}"
        end
      end
    end

    def store_plugin_reference(gem_name)
      puts "Storing #{gem_name}"
      plugin_name = gem_name.gsub(self.class.plugin_prefix, '')
      plugin_name_camelized = plugin_name.split('_').collect(&:capitalize).join
      puts "- #{plugin_name_camelized}"
      commands = Kernel.const_get("U3d::Plugin::#{plugin_name_camelized}").commands

      @discovered_plugin_names.push(*commands)
    end

    def initialize_register
      plugin_names = @discovered_plugin_names + @bundled_plugin_names

      @plugin_classes = []
      plugin_names.each do |plugin_name|
        puts "Initializing #{plugin_name}"
        plugin_name_camelized = plugin_name.split('_').collect(&:capitalize).join
        @plugin_classes << Kernel.const_get("U3d::Plugin::#{plugin_name_camelized}Command")
      end
    end

    def discovered_plugin_names
      available_plugins
    end

    def available_plugins
      available_gems.keep_if do |current|
        current.start_with?(self.class.plugin_prefix)
      end      
    end

    def available_gems
      return [] unless gemfile_path
      dsl = Bundler::Dsl.evaluate(gemfile_path, nil, true)
      return dsl.dependencies.map(&:name)
    end

    def self.plugin_prefix
      "u3d-plugin-".freeze
    end

    def gemfile_path
      # This is pretty important, since we don't know what kind of
      # Gemfile the user has (e.g. Gemfile, gems.rb, or custom env variable)
      Bundler::SharedHelpers.default_gemfile.to_s
    rescue Bundler::GemfileNotFound
      nil
    end    

    def register_commands
      @plugin_classes.each do |plugin_class|
        plugin_name = plugin_class.to_s.gsub(/^.*::/, '').gsub("Command", '').downcase
        puts "Registering command '#{plugin_name}' mapped to #{plugin_class}"
        command plugin_name.to_sym do |c|
          plugin_class.new.command(c)
        end
      end
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

      plugin_register = Program::PluginRegister.new

      default_command :do

      run!
    end
  end
end


Program::CommandsGenerator.run