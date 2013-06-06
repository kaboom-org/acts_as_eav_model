module ActiveRecord # :nodoc:
  module Acts # :nodoc:
    ##
    # ActsAsEavModel allow for the Entity-attribute-value model (EAV), also
    # known as object-attribute-value model and open schema on any of your ActiveRecord
    # models.
    #
    # = What is Entity-attribute-value model?
    # Entity-attribute-value model (EAV) is a data model that is used in circumstances
    # where the number of attributes (properties, parameters) that can be used to describe
    # a thing (an "entity" or "object") is potentially very vast, but the number that will
    # actually apply to a given entity is relatively modest.
    #
    # = Typical Problem
    # A good example of this is where you need to store
    # lots (possible hundreds) of optional attributes on an object. My typical
    # reference example is when you have a User object. You want to store the
    # user's preferences between sessions. Every search, sort, etc in your
    # application you want to keep track of so when the user visits that section
    # of the application again you can simply restore the display to how it was.
    #
    # So your controller might have:
    #
    #   Project.find :all, :conditions => current_user.project_search,
    #     :order => current_user.project_order
    #
    # But there could be hundreds of these little attributes that you really don't
    # want to store directly on the user object. It would make your table have too
    # many columns so it would be too much of a pain to deal with. Also there might
    # be performance problems. So instead you might do something like
    # this:
    #
    #   class User < ActiveRecord::Base
    #     has_many :preferences
    #   end
    #
    #   class Preferences < ActiveRecord::Base
    #     belongs_to :user
    #   end
    #
    # Now simply give the Preference model a "name" and "value" column and you are
    # set..... except this is now too complicated. To retrieve a attribute you will
    # need to do something like:
    #
    #   Project.find :all,
    #     :conditions => current_user.preferences.find_by_name('project_search').value,
    #     :order => current_user.preferences.find_by_name('project_order').value
    #
    # Sure you could fix this through a few methods on your model. But what about
    # saving?
    #
    #   current_user.preferences.create :name => 'project_search',
    #     :value => "lastname LIKE 'jones%'"
    #   current_user.preferences.create :name => 'project_order',
    #     :value => "name"
    #
    # Again this seems to much. Again we could add some methods to our model to
    # make this simpler but do we want to do this on every model. NO! So instead
    # we use this plugin which does everything for us.
    #
    # = Capabilities
    #
    # The ActsAsEavModel plugin is capable of modeling this problem in a intuitive
    # way. Instead of having to deal with a related model you treat all attributes
    # (both on the model and related) as if they are all on the model. The plugin
    # will try to save all attributes to the model (normal ActiveRecord behaviour)
    # but if there is no column for an attribute it will try to save it to a
    # related model whose purpose is to store these many sparsly populated
    # attributes.
    #
    # The main design goals are:
    #
    # * Have the eav attributes feel like normal attributes. Simple gets and sets
    #   will add and remove records from the related model.
    # * Allow for more than one related model. So for example on my User model I might
    #   have some eav behavior going into a contact_info table while others are
    #   going in a user_preferences table.
    # * Allow a model to determine what a valid eav attribute is for a given
    #   related model so our model still can generate a NoMethodError.
    #
    module EavModel

      MAGIC_FIELD_NAMES = [:created_at, :created_on, :updated_at, :updated_on, :created_by, :updated_by,
        :lock_version, :type, :id, :position, :parent_id, :lft, :rgt, :quote_value, :template, :to_ary,
        :marshal_dump, :marshal_load, :_dump, :_load, :to_yaml_type, :to_yaml, :yaml_initialize, :to_xml, :to_json, :as_json,
        :from_json, :from_xml,:validate,:validate_on_create,:validate_on_update].freeze

      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods

        ##
        # Will make the current class have eav behaviour.
        #
        #   class Post < ActiveRecord::Base
        #     has_eav_behavior
        #   end
        #   post = Post.find_by_title 'hello world'
        #   puts "My post intro is: #{post.intro}"
        #   post.teaser = 'An awesome introduction to the blog'
        #   post.save
        #
        # The above example should work even though "intro" and "teaser" are not
        # attributes on the Post model.
        #
        # The following options are available on for has_eav_behavior to modify
        # the behavior. Reasonable defaults are provided:
        #
        # * <tt>class_name</tt>:
        #   The class for the related model. This defaults to the
        #   model name prepended to "Attribute". So for a "User" model the class
        #   name would be "UserAttribute". The class can actually exist (in that
        #   case the model file will be loaded through Rails dependency system) or
          #   if it does not exist a basic model will be dynamically defined for you.
        #   This allows you to implement custom methods on the related class by
        #   simply defining the class manually.
        # * <tt>table_name</tt>:
        #   The table for the related model. This defaults to the
        #   attribute model's table name.
        # * <tt>relationship_name</tt>:
        #   This is the name of the actual has_many
        #   relationship. Most of the type this relationship will only be used
        #   indirectly but it is there if the user wants more raw access. This
        #   defaults to the class name underscored then pluralized finally turned
        #   into a symbol.
        # * <tt>foreign_key</tt>:
        #   The key in the attribute table to relate back to the
        #   model. This defaults to the model name underscored prepended to "_id"
        # * <tt>name_field</tt>:
        #   The field which stores the name of the attribute in the related object
        # * <tt>value_field</tt>:
        #   The field that stores the value in the related object
        # * <tt>fields</tt>:
        #   A list of fields that are valid eav attributes. By default
        #   this is "nil" which means that all field are valid. Use this option if
        #   you want some fields to go to one flex attribute model while other
        #   fields will go to another. As an alternative you can override the
        #   #eav_attributes method which will return a list of all valid flex
        #   attributes. This is useful if you want to read the list of attributes
        #   from another source to keep your code DRY. This method is given a
        #   single argument which is the class for the related model. The following
        #   provide an example:
        #
        #  class User < ActiveRecord::Base
        #    has_eav_behavior :class_name => 'UserContactInfo'
        #    has_eav_behavior :class_name => 'Preferences'
        #
        #    def eav_attributes(model)
        #      case model
        #        when UserContactInfo
        #          %w(email phone aim yahoo msn)
        #        when Preference
        #          %w(project_search project_order user_search user_order)
        #        else Array.new
        #      end
        #    end
        #  end
        #
        #  marcus = User.find_by_login 'marcus'
        #  marcus.email = 'marcus@example.com' # Will save to UserContactInfo model
        #  marcus.project_order = 'name'     # Will save to Preference
        #  marcus.save # Carries out save so now values are in database
        #
        # Note the else clause in our case statement. Since an empty array is
        # returned for all other models (perhaps added later) then we can be
        # certain that only the above eav attributes are allowed.
        #
        # If both a :fields option and #eav_attributes method is defined the
        # <tt>fields</tt> option take precidence. This allows you to easily define the
        # field list inline for one model while implementing #eav_attributes
        # for another model and not having #eav_attributes need to determine
        # what model it is answering for. In both cases the list of flex
        # attributes can be a list of string or symbols
        #
        # A final alternative to :fields and #eav_attributes is the
        # #is_eav_attribute? method. This method is given two arguments. The
        # first is the attribute being retrieved/saved the second is the Model we
        # are testing for. If you override this method then the #eav_attributes
        # method or the :fields option will have no affect. Use of this method
        # is ideal when you want to retrict the attributes but do so in a
        # algorithmic way. The following is an example:
        #   class User < ActiveRecord::Base
        #     has_eav_behavior :class_name => 'UserContactInfo'
        #     has_eav_behavior :class_name => 'Preferences'
        #
        #     def is_eav_attribute?(attr, model)
        #       case attr.to_s
        #         when /^contact_/ then true
        #         when /^preference_/ then true
        #         else
        #           false
        #       end
        #     end
        #   end
        #
        #   marcus = User.find_by_login 'marcus'
        #   marcus.contact_phone = '021 654 9876'
        #   marcus.contact_email = 'marcus@example.com'
        #   marcus.preference_project_order = 'name'
        #   marcus.some_attribute = 'blah'  # If some_attribute is not defined on
        #                                   # the model then method not found is thrown
        #
        def has_eav_behavior(options = {})
          Rails.logger.debug("HERE OPTIONS=#{options.inspect}")
          # Provide default options
          options[:class_name] ||= self.name + 'Attribute'
          options[:table_name] ||= options[:class_name].tableize
          options[:relationship_name] ||= options[:class_name].tableize.to_sym
          options[:foreign_key] ||= "#{self.table_name.singularize.downcase}_id" #self.name.foreign_key
          options[:base_foreign_key] ||= self.name.underscore.foreign_key
          options[:name_field] ||= 'name'
          options[:value_field] ||= 'value'
          options[:fields].collect! {|f| f.to_s} unless options[:fields].nil?
          options[:parent] = self.name

          # Init option storage if necessary
          cattr_accessor :eav_options
          self.eav_options ||= Hash.new

          # Return if already processed.
          return if self.eav_options.keys.include? options[:class_name]

          # Attempt to load related class. If not create it
          begin
            options[:class_name].constantize
          rescue
            Object.const_set(options[:class_name],
            Class.new(ActiveRecord::Base)).class_eval do
              attr_accessible options[:name_field].to_sym, options[:value_field].to_sym, options[:foreign_key].to_sym
              def self.reloadable? #:nodoc:
                false
              end
            end
          end

          # Store options
          self.eav_options[options[:class_name]] = options

          # Only mix instance methods once
          unless self.included_modules.include?(ActiveRecord::Acts::EavModel::InstanceMethods)
            send :include, ActiveRecord::Acts::EavModel::InstanceMethods
          end

          # Modify attribute class
          attribute_class = options[:class_name].constantize
          base_class = self.name.underscore.to_sym

          attribute_class.class_eval do
            belongs_to base_class, :foreign_key => options[:base_foreign_key]
            alias_method :base, base_class # For generic access
          end

          # Modify main class
          class_eval do
            has_many options[:relationship_name],
              :class_name => options[:class_name],
              :table_name => options[:table_name],
              :foreign_key => options[:foreign_key],
              :dependent => :destroy

            # The following is only setup once
            unless method_defined? :method_missing_without_eav_behavior

              # Carry out delayed actions before save
              after_validation :save_modified_eav_attributes,:on=>:update

              # Make attributes seem real
              alias_method_chain :respond_to?, :eav_behavior
              alias_method_chain :method_missing, :eav_behavior

              private

              alias_method_chain :read_attribute, :eav_behavior
              alias_method_chain :write_attribute, :eav_behavior

            end
          end

          #create_attribute_table

        end

      end

      module InstanceMethods

        def self.included(base) # :nodoc:
          base.extend ClassMethods
        end

        module ClassMethods

          ##
          # Rake migration task to create the versioned table using options passed to has_eav_behavior
          #
          def create_attribute_table(options = {})
            eav_options.keys.each do |key|
              continue if eav_options[key][:parent] != self.name
              model = eav_options[key][:class_name]

              return if connection.tables.include?(eav_options[model][:table_name])
              self.connection.create_table(eav_options[model][:table_name], options) do |t|
                t.integer eav_options[model][:foreign_key], :null => false
                t.string eav_options[model][:name_field], :null => false
                t.string eav_options[model][:value_field], :null => false

                t.timestamps
              end

              self.connection.add_index eav_options[model][:table_name], eav_options[model][:foreign_key]
            end

          end

          ##
          # Rake migration task to drop the attribute table
          #
          def drop_attribute_table(options = {})
            eav_options.keys.each do |key|
              continue if eav_options[key][:parent] != self.name
              model = eav_options[key][:class_name]
              self.connection.drop_table eav_options[model][:table_name]
            end

          end

        end

        ##
        # Will determine if the given attribute is a eav attribute on the
        # given model. Override this in your class to provide custom logic if
        # the #eav_attributes method or the :fields option are not flexible
        # enough. If you override this method :fields and #eav_attributes will
        # not apply at all unless you implement them yourself.
        #
        def is_eav_attribute?(attribute_name, model)
          attribute_name = attribute_name.to_s
          model_options = eav_options[model.name]
          return model_options[:fields].include?(attribute_name) unless model_options[:fields].nil?
          return eav_attributes(model).collect {|field| field.to_s}.include?(attribute_name) unless eav_attributes(model).nil?
          true
        end

        ##
        # Return a list of valid eav attributes for the given model. Return
        # nil if any field is allowed. If you want to say no field is allowed
        # then return an empty array. If you just have a static list the :fields
        # option is most likely easier.
        #
        def eav_attributes(model); nil end

        def eav_options_for_instance
         eav_options.first.last
        end
        ##
        # CLK added a respond_to? implementation so that ActiveRecord AssociationProxy (polymorphic relationships)
        # does not mask the method_missing implementation here. See:
        # https://rails.lighthouseapp.com/projects/8994/tickets/2378-associationproxymethod_missing-masks-method_missing-in-models
        # Updated when certain magic fields (like timestamp columns) were interfering with saves, etc.
        # http://oldwiki.rubyonrails.org/rails/pages/MagicFieldNames
        #
        def respond_to_with_eav_behavior?(attribute_name, include_private = false)
          # first check is_eav_attribute? to prevent eager loading
          each_eav_relation do |model|
            if !eav_attributes(model).nil? && is_eav_attribute?(attribute_name, model)
              return true
            end
          end
          # next check via reading keys from EAV table
          if !read_attribute_with_eav_behavior(attribute_name).nil?
            return true
          end
          # fall back to super
          respond_to_without_eav_behavior?(attribute_name, include_private)
        end

        ##
        # Returns a hash of all eav key value pairs, optionally filtered by a model
        def eav_hash(model = nil)
          {}.tap do |hash|
            models = model ? [model].flatten.compact : eav_options.keys
            eav_options.each do |model, options|
              if models.include?(model)
                self.send(:eav_related, model.constantize).to_a.each do |relation|
                  key = relation.send(options[:name_field])
                  if key && is_eav_attribute?(key.to_sym, model.constantize)
                    hash[key.to_sym] = relation.send(options[:value_field])
                  end
                end
              end
            end
          end
        end

        private

        ##
        # Called after validation on update so that eav attributes behave
        # like normal attributes in the fact that the database is not touched
        # until save is called.
        #
        def save_modified_eav_attributes
          return if @save_eav_attr.nil?
          @save_eav_attr.each do |s|
            model, attribute_name = s
            related_attribute = find_related_eav_attribute(model, attribute_name)
            unless related_attribute.nil?
              if related_attribute.value.nil?
                eav_related(model).delete(related_attribute)
              else
                related_attribute.save
              end
            end
          end
          @save_eav_attr = []
        end

        ##
        # Overrides ActiveRecord::Base#read_attribute
        #
        def read_attribute_with_eav_behavior(attribute_name)
          attribute_name = attribute_name.to_s
          exec_if_related(attribute_name) do |model|

            return nil if !@remove_eav_attr.nil? && @remove_eav_attr.any? do |r|
              r[0] == model && r[1] == attribute_name
            end

            value_field = eav_options[model.name][:value_field]
            related_attribute = find_related_eav_attribute(model, attribute_name)

            return nil if related_attribute.nil?
            return related_attribute.send(value_field)
          end
          read_attribute_without_eav_behavior(attribute_name)
        end

        ##
        # Overrides ActiveRecord::Base#write_attribute
        #
        def write_attribute_with_eav_behavior(attribute_name, value)
          attribute_name = attribute_name.to_s
          exec_if_related(attribute_name) do |model|
            value_field = eav_options[model.name][:value_field]
            @save_eav_attr ||= []
            @save_eav_attr << [model, attribute_name]
            related_attribute = find_related_eav_attribute(model, attribute_name)
            if related_attribute.nil?
              # Used to check for nil? but this caused validation
              # problems that are harder to solve. blank? is probably
              # not correct but it works well for now.
              unless value.blank?
                name_field = eav_options[model.name][:name_field]
                foreign_key = eav_options[model.name][:foreign_key]
                eav_related(model).build name_field => attribute_name,
                  value_field => value, foreign_key => self.id
              end
              return value
            else
              value_field = (value_field.to_s + '=').to_sym
              return related_attribute.send(value_field, value)
            end
          end
          write_attribute_without_eav_behavior(attribute_name, value)
        end

        ##
        # Custom method added by ckraybill!
        #
        def attribute_empty_with_eav_behavior(attribute_name)
          !read_attribute_with_eav_behavior(attribute_name).blank?
        end

        ##
        # Implements eav-attributes as if real getter/setter methods
        # were defined.
        # Method modified to support '?' behavior
        def method_missing_with_eav_behavior(method_id, *args, &block)
          begin
            method_missing_without_eav_behavior(method_id, *args, &block)
          rescue NoMethodError => e
            m = method_id.to_s
            attribute_name = m.sub(/\=|\?$/, '')
            exec_if_related(attribute_name) do |model|
              if m =~ /\=$/
                return write_attribute_with_eav_behavior(attribute_name, args[0])
              elsif m =~ /\?$/
                return attribute_empty_with_eav_behavior(attribute_name)
              else
                return read_attribute_with_eav_behavior(attribute_name)
              end
            end
            raise e
          end
        end

        ##
        # Retrieve the related eav attribute object
        #
        def find_related_eav_attribute(model, attribute_name)
          name_field = eav_options[model.name][:name_field]
          eav_related(model).to_a.find do |relation|
            relation.send(name_field) == attribute_name
          end
        end

        ##
        # Retrieve the collection of related eav attributes
        #
        def eav_related(model)
          relationship = eav_options[model.name][:relationship_name]
          send relationship
        end

        ##
        # yield only if attribute_name is a eav_attribute
        #
        def exec_if_related(attribute_name)
          return false if self.class.column_names.include?(attribute_name) || MAGIC_FIELD_NAMES.include?(attribute_name.to_sym)
          return false if attribute_name =~ /^_/
          each_eav_relation do |model|
            if is_eav_attribute?(attribute_name, model)
              yield model
            end
          end
        end

        ##
        # yields for each eav relation.
        #
        def each_eav_relation
          eav_options.keys.each {|kls| yield kls.constantize}
        end

      end

    end
  end

  class Base

    ##
    # Overrides ActiveRecord::Base#attributes=
    #
    # Because in version >=2.2.2 of ActiveRecord the behaviour in the attributes
    # have been changed to throw a NoMethodError if the AR object don't respond
    # to an attribute setter, we could not use method missing to allow for our
    # entity-attribute-value behaviour.
    #
    def attributes=(new_attributes, guard_protected_attributes = true)
      return if new_attributes.nil?
      attributes = new_attributes.dup
      attributes.stringify_keys!
      multi_parameter_attributes = []
      attributes = sanitize_for_mass_assignment(attributes) if guard_protected_attributes
      attributes.each do |k, v|
        if k.include?("(")
          multi_parameter_attributes << [ k, v ]
        else
          send(:"#{k}=", v)
        end
      end

      assign_multiparameter_attributes(multi_parameter_attributes)
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::Acts::EavModel
