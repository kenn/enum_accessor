require 'enum_accessor/version'
require 'enum_accessor/railtie'
require 'active_support'

module EnumAccessor
  extend ActiveSupport::Concern

  module ClassMethods
    def enum_accessor(column, keys, options={})
      # Normalize keys
      dict = case keys
      when Array
        Hash[keys.map.with_index{|i,index| [i, index] }]
      when Hash
        keys
      else
        raise ArgumentError.new('enum_accessor takes Array or Hash as the second argument')
      end

      # Define class attributes
      definition = options[:class_attribute] || column.to_s.pluralize.to_sym
      class_attribute definition
      class_attribute "_human_#{definition}"
      send "#{definition}=", dict.with_indifferent_access.freeze
      send "_human_#{definition}=", {}

      # Getter
      define_method(column) do
        send(definition).key(read_attribute(column))
      end

      # Setter
      define_method("#{column}=") do |arg|
        case arg
        when String, Symbol
          write_attribute column, send(definition)[arg]
        when Integer, NilClass
          write_attribute column, arg
        end
      end

      # Raw-value getter
      define_method("#{column}_raw") do
        read_attribute(column)
      end

      # Predicate
      send(definition).each do |key, int|
        define_method("#{column}_#{key}?") do
          read_attribute(column) == int
        end
      end

      # Human-friendly print
      define_method("human_#{column}") do
        self.class.send("human_#{definition}")[send(column)]
      end

      # Human-friendly print on class level
      define_singleton_method("human_#{definition}") do
        send("_human_#{definition}")[I18n.locale] ||= begin
          Hash[send(definition).keys.map{|key| [key, send("human_#{column}", key)] }].with_indifferent_access.freeze
        end
      end

      # Internal method for translation
      # Mimics ActiveModel::Translation.human_attribute_name
      define_singleton_method "human_#{column}" do |key, options={}|
        defaults = lookup_ancestors.map do |klass|
          :"#{self.i18n_scope}.enum_accessor.#{klass.model_name.i18n_key}.#{column}.#{key}"
        end
        defaults << :"enum_accessor.#{self.model_name.i18n_key}.#{column}.#{key}"
        defaults << :"enum_accessor.#{column}.#{key}"
        defaults << options.delete(:default) if options[:default]
        defaults << key.to_s.humanize

        options.reverse_merge! count: 1, default: defaults
        I18n.translate(defaults.shift, options)
      end

      # Scopes
      define_singleton_method "where_#{column}" do |*args|
        integers = args.map{|arg| send(definition)[arg] }.compact
        where(column => integers)
      end

      # Validation
      if options.has_key?(:validate) or options.has_key?(:validation_options)
        raise ArgumentError, 'validation options are updated. please refer to the documentation.'
      end
      unless options[:validates] == false
        validation_options = options[:validates].is_a?(Hash) ? options[:validates] : {}
        validates column, { inclusion: { in: send(definition).keys } }.merge(validation_options)
      end
    end
  end
end
