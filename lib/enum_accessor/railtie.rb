module EnumAccessor
  if defined? Rails::Railtie
    class Railtie < Rails::Railtie
      initializer 'enum_accessor.insert_into_active_record' do |app|
        ActiveSupport.on_load :active_record do
          include EnumAccessor
        end
      end
    end
  end
end
