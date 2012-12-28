require 'rails/generators/active_record'

class ActsAsEavModelGenerator < ActiveRecord::Generators::Base
  desc "describe my generator here"

  argument :attribute_table_name, :required => false, :type => :string, :desc => "The names of the attribute table to create",
           :banner => "user_attributes"
  class_option :name_field, :type => :string, :default => 'name', :desc => "Column name for 'name' attribute"
  class_option :value_field, :type => :string, :default => 'value', :desc => "Column name for 'value' attribute"
  class_option :foreign_key_name, :type => :string, :desc => "Column nmae for foreign_key"

  def self.source_root
    @source_root ||= File.expand_path('../templates', __FILE__)
  end

  def generate_migration
    migration_template "acts_as_eav_model.rb.erb", "db/migrate/#{migration_file_name}"
  end

  protected

  def migration_name
    if attribute_table_name
      "create_attributes_table_for_#{name.underscore.pluralize}_as_#{attribute_table_name}"
    else
      "create_attributes_table_for_#{name.underscore.pluralize}"
    end
  end

  def table_name
    !attribute_table_name.nil? ? attribute_table_name :
      "#{name.underscore}_attributes".tableize
  end
  def migration_file_name
    "#{migration_name}.rb"
  end

  def migration_class_name
    migration_name.camelize
  end
  def name_field
    options.name_field
  end
  def value_field
    options.value_field
  end
  def foreign_key_name
    options.foreign_key_name || "#{name.underscore}_id"
  end
end
