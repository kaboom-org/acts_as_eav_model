require 'rubygems'

require 'tempfile'
require 'pathname'
require 'test/unit'

require 'shoulda'
#require 'mocha'
#require 'bourne'

require 'active_record'
#require 'active_record/version'
#require 'active_support'
#require 'active_support/core_ext'
#require 'mime/types'
#require 'pathname'
#require 'ostruct'

#puts "Testing against version #{ActiveRecord::VERSION::STRING}"


ROOT = Pathname(File.expand_path(File.join(File.dirname(__FILE__), '..')))
$LOAD_PATH << File.join(ROOT, 'lib')

require File.join(ROOT, 'lib', 'acts_as_eav_model.rb')

