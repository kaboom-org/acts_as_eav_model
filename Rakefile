# encoding: UTF-8
require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake'
require 'rdoc/task'

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)


Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Acts As EAV Model'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "acts_as_eav_model"
    gem.summary = %Q{Entity Attribute Value Implementation for inclusion in ActiveRecord models.}
    gem.description = %Q{Entity-attribute-value model (EAV) is a data model that is used in circumstances 
    where the number of attributes (properties, parameters) that can be used to describe 
    a thing (an "entity" or "object") is potentially very vast, but the number that will 
    actually apply to a given entity is relatively modest.}
    gem.email = ""
    gem.homepage = "http://github.com/g5search/acts_as_eav_model"
    gem.has_rdoc=true
    gem.authors = ["Marcus Wyatt"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

task :default => :spec
