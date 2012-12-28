require './test/helper'
require 'rails/generators'
require 'generators/acts_as_eav_model/acts_as_eav_model_generator'

class GeneratorTest < Rails::Generators::TestCase
  tests ActsAsEavModelGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  context 'run generator' do
    context 'with table name' do
      setup do
        run_generator %w(user spork)
      end
      should 'create correct migration' do
        assert_migration 'db/migrate/create_attributes_table_for_users_as_spork' do |migration|
          assert_match /class CreateAttributesTableForUsersAsSpork/, migration
          assert_class_method :up, migration do |up|
            assert_match /add_index :spork, :user_id/, up
          end
        end
      end
    end
    context 'without table name' do
      setup do
        run_generator %w(user)
      end
      should 'create correct migration' do
        assert_migration 'db/migrate/create_attributes_table_for_users' do |migration|
          assert_match /class CreateAttributesTableForUsers/, migration
          assert_class_method :up, migration do |up|
            assert_match /create_table :user_attributes/, up
            assert_match /t\.integer :user_id :null => false/, up
            assert_match /t\.text :name, :null => false/, up
            assert_match /t\.text :value, :null => false/, up
            assert_match /add_index :user_attributes, :user_id/, up
          end
        end
      end
    end
    context 'with optional column_names' do
      setup do
        opts = {:name_field => 'namm',
               :value_field => 'varde',
               :foreign_key_name => 'anvandare_id'}
        run_generator %w(user --name_field=namm --value_field=varde --foreign_key_name=anvandare_id)
      end
      should 'create correct migration' do
        assert_migration 'db/migrate/create_attributes_table_for_users' do |migration|
          assert_match /class CreateAttributesTableForUsers/, migration
          assert_class_method :up, migration do |up|
            assert_match /create_table :user_attributes/, up
            assert_match /t\.integer :anvandare_id :null => false/, up
            assert_match /t\.text :namm, :null => false/, up
            assert_match /t\.text :varde, :null => false/, up
            assert_match /add_index :user_attributes, :anvandare_id/, up
          end
        end
      end

    end

  end

end
