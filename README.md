# EnumAccessor - Simple enum fields for ActiveRecord

EnumAccessor lets you define enum for attributes, and store them as integer in the database.

Compatible with ActiveRecord 3 or later.

## Usage

Add this line to your application's Gemfile.

```ruby
gem 'enum_accessor'
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

Notice that zero-based numbering is used as database values.

Your migration should look like this.

```ruby
create_table :users do |t|
  t.integer :gender, :default => 0
end
```

Optionally, it would be a good idea to add `:limit => 1` on the column for even better space efficiency when the enum set is small.

## Manual coding

There are times when it makes more sense to manually pick particular integer values for the mapping.

In such cases, just pass a hash with coded integer values.

```ruby
enum_accessor :status, ok: 200, not_found: 404, internal_server_error: 500
```

## Scoping query

For querying purpose, use `User.genders` method to retrieve internal integer values.

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

## Translation

EnumAccessor supports [i18n](http://guides.rubyonrails.org/i18n.html) just as ActiveModel does.

For instance, create a Japanese translation in `config/locales/ja.yml`

```yaml
ja:
  enum_accessor:
    gender:
      female: 女
      male: 男
```

and now `human_*` methods return a translated string. It defaults to `humanize` method nicely as well.

```ruby
I18n.locale = :ja
user.human_gender     # => '女'
User.human_genders    # => { :female => '女', :male => '男' }

I18n.locale = :en
user.human_gender     # => 'Female'
User.human_genders    # => { :female => 'Female', :male => 'Male' }
```

## Why enum keys are internally stored as strings rather than symbols?

Because `params[:gender].to_sym` is dangerous. It could lead to problems like memory leak, slow symbol table lookup, or even DoS attack. If a user sends random strings for the parameter, it generates uncontrollable number of symbols, which can never be garbage collected, and eventually causes `symbol table overflow (RuntimeError)`, eating up gigabytes of memory.

For the same reason, `ActiveSupport::HashWithIndifferentAccess` (which is used for `params`) keeps hash keys as string internally.

https://github.com/rails/rails/blob/master/activesupport/lib/active_support/hash_with_indifferent_access.rb

## Other solutions

There are tons of similar gems out there. Then why did I bother creating another one myself rather than sending pull requests to one of them? Because each one of them has incompatible design policies than EnumAccessor.

* [simple_enum](https://github.com/lwe/simple_enum)
  * Pretty close to EnumAccessor feature-wise but requires `*_cd` suffix for the database column, which makes AR scopes ugly.
  * Enum values are defined as top-level predicate methods, which could conflict with existing methods. Also you can't define multiple enums to the same model. In some use cases, predicate methods are not necessary and you just want to be on the safe side.
* [enumerated_attribute](https://github.com/jeffp/enumerated_attribute)
  * Top-level predicate methods. Many additional methods are coupled with a specific usage assumption.
* [enum_field](https://github.com/jamesgolick/enum_field)
  * Top-level predicate methods.
* [coded_options](https://github.com/jasondew/coded_options)
* [active_enum](https://github.com/adzap/active_enum)
* [classy_enum](https://github.com/beerlington/classy_enum)
* [enumerize](https://github.com/brainspec/enumerize)

Also, EnumAccessor has one of the simplest code base, so that you can easily hack on.
