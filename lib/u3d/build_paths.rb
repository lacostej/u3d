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
require 'u3d/installation'
require 'u3d_core/helper'

module U3d
  class BuildPaths
    def initialize(unity)
      @unity = unity
    end

    def managed(file)
      file = File.join(managed_path, file)
      raise "Managed file '#{file}' not found" unless File.exist? file
      file
    end

    def managed_path
      if U3d::Helper.mac?
        # Note: the location of the managed files and mcs has changed between 5.3 and 5.6
        # This method currently only support Unity version 5.6+
        managed_path = File.join(@unity.path, 'Contents', 'Managed')
      else
        managed_path = File.join(@unity.path, 'Editor', 'Data', 'Managed')
      end
      managed_path
    end
    def mcs
      if U3d::Helper.mac?
        mcs_path = File.join(@unity.path, 'Contents', 'MonoBleedingEdge', 'bin', 'mcs')
      else
        mcs_path = File.join(@unity.path, 'Editor', 'Data', 'MonoBleedingEdge', 'bin', 'mcs')
      end
      mcs_path
    end
  end
end