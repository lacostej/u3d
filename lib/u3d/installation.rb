## --- BEGIN LICENSE BLOCK ---
# Copyright (c) 2016-present WeWantToKnow AS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
## --- END LICENSE BLOCK ---

require 'u3d/utils'

module U3d
  UNITY_DIR_CHECK = /Unity_\d+\.\d+\.\d+[a-z]\d+/
  UNITY_DIR_CHECK_LINUX = /unity-editor-\d+\.\d+\.\d+[a-z]\d+\z/

  class Installation
    attr_reader :root_path

    def initialize(root_path: nil, path: nil)
      @root_path = root_path
      @path = path
    end

    def self.create(root_path: nil, path: nil)
      UI.deprecated("path is deprecated. Use root_path instead") unless path.nil?
      if Helper.mac?
        MacInstallation.new(root_path: root_path, path: path)
      elsif Helper.linux?
        LinuxInstallation.new(root_path: root_path, path: path)
      else
        WindowsInstallation.new(root_path: root_path, path: path)
      end
    end

    def paths
      @paths ||= U3d::BuildPaths.new(self)
    end

    # FIXME create a parameter for build library operation spec
    def build_library(references: [], files: [], sdk_level: 2, out: 'Output.dll')
      target = File.dirname out
      U3d::Utils.ensure_dir(target)

      reference_string = references.map { |dep| dep.argescape }.join(',')

      output_callback = proc do |line|
        UI.command_output(line.rstrip)
      end
      # we will need a smarter command builder once we have optional parameters
      command = "#{paths.mcs.argescape} -r:#{reference_string} -target:library -sdk:#{sdk_level} -out:#{out} #{files.join(' ')}"
      U3dCore::CommandExecutor.execute_command(command: command, output_callback: output_callback)
      U3dCore::UI.success "Library '#{out}' built!"
    end

    def export_package(dirs: [], dir: Dir.pwd, log_file: '/dev/stdout',  raw_logs: false, out: nil)
      # FIXME there's a bit of duplication from the commands here. Revisit API
      require 'u3d/unity_runner'
      require 'u3d/log_analyzer'
      up = U3d::UnityProject.new(dir)
      run_args = [
        '-logFile', log_file,
        '-projectpath', up.path,
        '-exportPackage', dirs, out,
        '-batchmode', '-quit'
      ].flatten
      runner = Runner.new
      runner.run(self, run_args, raw_logs: raw_logs)
      U3dCore::UI.success "UnityPackage '#{out}' built!"
    end
  end

  class MacInstallation < Installation
    require 'plist'

    def version
      plist['CFBundleVersion']
    end

    def default_log_file
      "#{ENV['HOME']}/Library/Logs/Unity/Editor.log"
    end

    def exe_path
      "#{root_path}/Unity.app/Contents/MacOS/Unity"
    end

    def path
      UI.deprecated("path is deprecated. Use root_path instead")
      return @path if @path
      "#{@root_path}/Unity.app"
    end

    def packages
      if Utils.parse_unity_version(version)[0].to_i <= 4
        # Unity < 5 doesn't have packages
        return []
      end
      fpath = File.expand_path('PlaybackEngines', root_path)
      return [] unless Dir.exist? fpath # install without package
      Dir.entries(fpath).select { |e| File.directory?(File.join(fpath, e)) && !(e == '.' || e == '..') }
    end

    def clean_install?
      !(root_path =~ UNITY_DIR_CHECK).nil?
    end

    private

    def plist
      @plist ||=
        begin
          fpath = "#{root_path}/Unity.app/Contents/Info.plist"
          raise "#{fpath} doesn't exist" unless File.exist? fpath
          Plist.parse_xml(fpath)
        end
    end
  end

  class LinuxInstallation < Installation
    def version
      # I don't find an easy way to extract the version on Linux
      require 'rexml/document'
      fpath = "#{root_path}/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/ivy.xml"
      raise "Couldn't find file #{fpath}" unless File.exist? fpath
      doc = REXML::Document.new(File.read(fpath))
      version = REXML::XPath.first(doc, 'ivy-module/info/@e:unityVersion').value
      if (m = version.match(/^(.*)x(.*)Linux$/))
        version = "#{m[1]}#{m[2]}"
      end
      version
    end

    def default_log_file
      "#{ENV['HOME']}/.config/unity3d/Editor.log"
    end

    def exe_path
      "#{root_path}/Editor/Unity"
    end

    def path
      UI.deprecated("path is deprecated. Use root_path instead")
      @root_path || @path
    end

    def packages
      false
    end

    def clean_install?
      !(root_path =~ UNITY_DIR_CHECK_LINUX).nil?
    end
  end

  class WindowsInstallation < Installation
    def version
      require 'rexml/document'
      # For versions >= 5
      fpath = "#{root_path}/Editor/Data/PlaybackEngines/windowsstandalonesupport/ivy.xml"
      # For versions < 5
      fpath = "#{root_path}/Editor/Data/PlaybackEngines/wp8support/ivy.xml" unless File.exist? fpath
      raise "Couldn't find file #{fpath}" unless File.exist? fpath
      doc = REXML::Document.new(File.read(fpath))
      version = REXML::XPath.first(doc, 'ivy-module/info/@e:unityVersion').value

      version
    end

    def default_log_file
      if @logfile.nil?
        begin
          loc_appdata = Utils.windows_local_appdata
          log_dir = File.expand_path('Unity/Editor/', loc_appdata)
          UI.important "Log directory (#{log_dir}) does not exist" unless Dir.exist? log_dir
          @logfile = File.expand_path('Editor.log', log_dir)
        rescue RuntimeError => ex
          UI.error "Unable to retrieve the editor logfile: #{ex}"
        end
      end
      @logfile
    end

    def exe_path
      File.join(@root_path, 'Editor', 'Unity.exe')
    end

    def path
      UI.deprecated("path is deprecated. Use root_path instead")
      @root_path || @path
    end

    def packages
      # Unity prior to Unity5 did not have package
      return [] if Utils.parse_unity_version(version)[0].to_i <= 4
      fpath = "#{root_path}/Editor/Data/PlaybackEngines/"
      return [] unless Dir.exist? fpath # install without package
      Dir.entries(fpath).select { |e| File.directory?(File.join(fpath, e)) && !(e == '.' || e == '..') }
    end

    def clean_install?
      !(root_path =~ UNITY_DIR_CHECK).nil?
    end
  end
end
