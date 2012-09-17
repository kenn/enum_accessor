# EnumAccessor - Simple enum fields for ActiveRecord

EnumAccessor lets you define enum for attributes, and store them as integer in the database.

Compatible with ActiveRecord 3 or later.

## Usage

Add this line to your application's Gemfile.

```ruby
gem 'enum_accessor'
```

Add an integer column.

```ruby
create_table :users do |t|
  t.column :gender, :integer, default: 0
end
```

Define `enum_accessor` in a model class.

```ruby
class User < ActiveRecord::Base
  enum_accessor :gender, [ :female, :male ]
end
```

And now you have a set of methods and constants.

```ruby
user = User.new
user.gender             # => :female
user.gender_male?       # => false
user.gender_raw         # => 0

user.gender = :male
user.gender_male?       # => true
user.gender_raw         # => 1

User.genders            # => { :female => 0, :male => 1 }
User::GENDERS           # => { "female" => 0, "male" => 1 }
```

Notice that zero-based numbering is used for database values.

## Manual coding

There are times when it makes more sense to manually pick particular integers for the mapping.

Just pass a hash with coded integer values.

```ruby
enum_accessor :status, ok: 200, not_found: 404, internal_server_error: 500
```

## Scoping query

To retrieve internal integer values for query, use `User.genders`.

```ruby
User.where(gender: User.genders(:female))
```

## Validations

You can pass custom validation options to `validates_inclusion_of`.

```ruby
enum_accessor :status, [ :on, :off ], validation_options: { message: "incorrect status" }
```

Or skip validation entirely.

```ruby
enum_accessor :status, [ :on, :off ], validate: false
```

## i18n

EnumAccessor supports i18n just as ActiveModel does.

Add the following lines to `config/locales/ja.yml`

```yaml
ja:
  enum_accessor:
    user:
      gender:
        female: 女
        male: 男
```

and now `human_*` method returns a translated string. It defaults to English nicely as well.

```ruby
I18n.locale = :ja
user.human_gender       # => '女'

I18n.locale = :en
user.human_gender       # => 'Female'
```

## Why enum keys are internally stored as strings rather than symbols?

Because `params[:gender].to_sym` is dangerous. It could be a source of problems like memory leak, slow symbol table lookup, or even DoS attack. If a user sends random strings for the parameter, it generates unlimited number of symbols, which can never be garbage collected, and eventually causes `symbol table overflow (RuntimeError)`, eating up gigabytes of memory.

For the same reason, `ActiveSupport::HashWithIndifferentAccess` (which is used for `params`) keeps hash keys as string internally.

https://github.com/rails/rails/blob/master/activesupport/lib/active_support/hash_with_indifferent_access.rb

## Other solutions

There are tons of similar gems out there. Then why did I bother creating another one myself rather than sending pull requests to one of them? Because each one of them has incompatible design policies than EnumAccessor.

* [simple_enum](https://github.com/lwe/simple_enum)
    * Pretty close to EnumAccessor feature-wise but requires `*_cd` suffix for the database column, which makes AR scopes ugly.
* [enum_field](https://github.com/jamesgolick/enum_field)
    * Enum values are defined as top-level predicate methods, which could conflict with existing methods. Also you can't define multiple enums to the same model. In some use cases, predicate methods are not necessary and you just want to be on the safe side.
* [enumerated_attribute](https://github.com/jeffp/enumerated_attribute)
    * Top-level predicate methods. Many additional methods are coupled with a specific usage assumption.
* [coded_options](https://github.com/jasondew/coded_options)
    * No support for symbols. Verbose definitions.
* [active_enum](https://github.com/adzap/active_enum)
    * Syntax seems verbose.
* [classy_enum](https://github.com/beerlington/classy_enum)
    * As the name suggests, class-based enum. I wanted something lighter.

Also, EnumAccessor has one of the simplest code base, so that you can easily hack on.
