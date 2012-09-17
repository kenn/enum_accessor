require 'enum_accessor/version'
require 'enum_accessor/railtie'
require 'active_support'

module EnumAccessor
  extend ActiveSupport::Concern

  module ClassMethods
    # enum_accessor encapsulates a validates_inclusion_of and automatically gives you a 
    # few more goodies automatically.
    # 
    #     class Computer < ActiveRecord:Base
    #       enum_accessor :status, [ :on, :off ], validation_options: { message: "incorrect status" }
    # 
    #       # Optionally with a message to replace the default one
    #       # enum_accessor :status, [ :on, :off ]
    # 
    #       #...
    #     end
    # 
    # This will give you a few things:
    # 
    # - add a validates_inclusion_of with a simple error message ("invalid #{field}") or your custom message
    # - define the following query methods, in the name of expressive code:
    #   - status_on?
    #   - status_off?
    # - define the STATUSES constant, which contains the acceptable values
    def enum_accessor(field, enums, options={})
      # Normalize arguments
      field = field.to_s
      case enums
      when Array
        enums = Hash[enums.map.with_index{|v,i| [v.to_s, i] }]
      when Hash
        enums = Hash[enums.map{|k,v| [k.to_s, v] }]
      else
        raise ArgumentError.new('enum_accessor takes Array or Hash as the second argument')
      end

      const_name = field.pluralize.upcase
      const_set(const_name, enums) unless const_defined?(const_name)
      const = const_get(const_name)

      symbolized_enums = Hash[enums.map{|k,v| [k.to_sym, v] }]

      # Getter
      define_method(field) do
        const.key(read_attribute(field)).try(:to_sym)
      end

      # Setter
      define_method("#{field}=") do |arg|
        write_attribute field, const[arg.to_s]
      end

      # Raw-value getter
      define_method("#{field}_raw") do
        read_attribute field
      end

      # Raw-value setter
      define_method("#{field}_raw=") do |arg|
        write_attribute field, Integer(arg)
      end

      # Checker
      symbolized_enums.keys.each do |key|
        method_name = key.to_s.downcase.gsub(/[-\s]/, '_')
        define_method("#{field}_#{method_name}?") do
          self.send(field) == key
        end
      end

      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{field.pluralize}(*args)
          return #{symbolized_enums} if args.first.nil?
          return #{symbolized_enums}[args.first.to_sym] if args.size == 1
          args.map{|arg| #{symbolized_enums}[arg.to_sym] }
        end
      EOS

      # Human-friendly view
      define_method("human_#{field}") do
        self.class.human_enum_accessor(field, self.send(field))
      end

      # Validation
      unless options[:validate] == false
        validates_inclusion_of field, { :in => symbolized_enums.keys }.merge(options[:validation_options] || {})
      end
    end

    # Mimics ActiveModel::Translation.human_attribute_name
    def human_enum_accessor(field, value, options = {})
      defaults = lookup_ancestors.map do |klass|
        :"#{self.i18n_scope}.enum_accessor.#{klass.model_name.i18n_key}.#{field}.#{value}"
      end
      defaults << :"enum_accessor.#{self.model_name.i18n_key}.#{field}.#{value}"
      defaults << :"enum_accessor.#{field}.#{value}"
      defaults << options.delete(:default) if options[:default]
      defaults << value.to_s.humanize

      options.reverse_merge! :count => 1, :default => defaults
      I18n.translate(defaults.shift, options)
    end
  end
end
