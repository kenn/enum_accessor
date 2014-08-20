require 'rubygems'
require 'bundler/setup'

require 'enum_accessor'

RSpec.configure do |config|
  require 'active_record'
  ActiveRecord::Base.send(:include, EnumAccessor)

  # Establish in-memory database connection
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

  # Load translation
  I18n.enforce_available_locales = true
  I18n.load_path << File.join(File.dirname(__FILE__), 'locales.yml')
end
