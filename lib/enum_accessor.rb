require 'enum_accessor/version'
require 'enum_accessor/railtie'
require 'active_support'

module EnumAccessor
  extend ActiveSupport::Concern

  module ClassMethods
    def enum_accessor(column, keys, options={})
      definition = options[:class_attribute] || column.to_s.pluralize.to_sym
      class_attribute definition
      send "#{definition}=", Definition.new(column, keys, self)

      # Getter
      define_method(column) do
        send(definition).dict.key(read_attribute(column))
      end

      # Setter
      define_method("#{column}=") do |arg|
        case arg
        when String, Symbol
          write_attribute column, send(definition).dict[arg]
        when Integer, NilClass
          write_attribute column, arg
        end
      end

      # Raw-value getter
      define_method("#{column}_raw") do
        read_attribute(column)
      end

      # Predicate
      send(definition).dict.each do |key, int|
        define_method("#{column}_#{key}?") do
          read_attribute(column) == int
        end
      end

      # Human-friendly print
      define_method("human_#{column}") do
        send(definition).human_dict[send(column)]
      end

      # Human-friendly print on class level
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
        integers = args.map{|arg| send(definition).dict[arg] }.compact
        where(column => integers)
      end

      # Validation
      if options.has_key?(:validate) or options.has_key?(:validation_options)
        raise ArgumentError, 'validation options are updated. please refer to the documentation.'
      end
      unless options[:validates] == false
        validation_options = options[:validates].is_a?(Hash) ? options[:validates] : {}
        validates column, { inclusion: { in: send(definition).dict.keys } }.merge(validation_options)
      end
    end

    class Definition
      attr_accessor :dict

      def initialize(column, keys, klass)
        dict = case keys
        when Array
          Hash[keys.map.with_index{|i,index| [i, index] }]
        when Hash
          keys
        else
          raise ArgumentError.new('enum_accessor takes Array or Hash as the second argument')
        end

        @column = column
        @klass = klass
        @dict = dict.with_indifferent_access.freeze
        @human_dict = {}
      end

      def human_dict
        @human_dict[I18n.locale] ||= begin
          Hash[@dict.keys.map{|key| [key, @klass.send("human_#{@column}", key)] }].with_indifferent_access.freeze
        end
      end
    end
  end
end
