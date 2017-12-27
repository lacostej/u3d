Dir[File.expand_path('**/{commands,helper}/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end

module U3d
  module Plugin
    module Foobar
      def self.commands
      	['foobar']
      end
    end
  end
end
