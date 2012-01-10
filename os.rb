####
# Code as per https://github.com/janlelis/zucker/blob/master/lib/zucker/os.rb
# License as per https://github.com/janlelis/zucker/blob/master/MIT-LICENSE
#
# License
# =======
#
# Copyright (c) 2010-2011 Jan Lelis
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# Code
# ====

require 'rbconfig'

module OS
  class << self
    def is?(what)
      what === RbConfig::CONFIG['host_os']
    end
    alias is is?

    def to_s
      RbConfig::CONFIG['host_os']
    end
  end

  module_function

  def linux?
    OS.is?( /linux|cygwin/ )
  end

  def mac?
    OS.is?( /mac|darwin/ )
  end

  def bsd?
    OS.is?( /bsd/ )
  end

  def windows?
    OS.is?( /mswin|mingw/ )
  end

  def solaris?
    OS.is?( /solaris|sunos/ )
  end

  def posix?
    linux? or mac? or bsd? or solaris? or begin 
        fork do end
        true
      rescue NotImplementedError, NoMethodError
        false
      end
  end

  #def symbian?
    #TODO who knows what symbian returns?
  #end

  # ...
end

# J-_-L
