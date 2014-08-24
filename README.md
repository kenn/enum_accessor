# EnumAccessor - Simple enum fields for ActiveRecord

EnumAccessor lets you define enum for attributes, and store them as integer in the database.

It is very similar to [Official Rails 4.1 Implementation](http://edgeguides.rubyonrails.org/4_1_release_notes.html#active-record-enums), but EnumAccessor offers quite a few advantages:

* No-conflict safe predicate methods (`user.status_active?` instead of `user.active?`)
* Validation
* Scope
* Translation

Compatible with ActiveRecord 3 or later.

## Usage

Add this line to your application's Gemfile.

```ruby
gem 'enum_accessor'
```

Define `enum_accessor` in a model class.

```ruby
class User < ActiveRecord::Base
  enum_accessor :gender, [:female, :male]
end
```

And now you have a set of methods and constants.

```ruby
user = User.new
user.gender = 'female'  # Takes String or Symbol
user.gender             # => "female"
user.gender_female?     # => true
user.gender_raw         # => 0

user.gender = :male
user.gender_female?     # => false
user.gender_raw         # => 1

User.genders            # => { 'female' => 0, 'male' => 1 }
```

Notice that zero-based numbering is used as database values.

Your migration should look like this.

```ruby
create_table :users do |t|
  t.integer :gender, default: 0
end
```

Optionally, it would be a good idea to add `limit: 1` on the column for even better space efficiency when the enum set is small.

## Manual coding

There are times when it makes more sense to manually pick particular integer values for the mapping.

In such cases, just pass a hash with coded integer values.

```ruby
enum_accessor :status, ok: 200, not_found: 404, internal_server_error: 500
```

## Scoping query

For querying purpose, use `User.genders` method to retrieve internal integer values.

```ruby
User.where_gender(:female)
```

Also takes multiple values.

```ruby
User.where_status(:active, :pending)
```

To use under direct `where` context (e.g. `find_by` or `find_or_create_by`), pass integer value.

```ruby
Social.find_or_create_by(kind: Social.kinds[:facebook], external_id: facebook_user_id)
```

## Validations

By default, models are validated using `inclusion`. To disable, pass `false` to `validates` option.

```ruby
enum_accessor :status, [:on, :off], validates: false
```

You can also pass validation options.

```ruby
enum_accessor :status, [:on, :off], validates: { allow_nil: true }
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
user.human_gender         # => '女'
User.human_genders        # => { 'female' => '女', 'male' => '男' }

I18n.locale = :en
user.human_gender         # => 'Female'
User.human_genders        # => { 'female' => 'Female', 'male' => 'Male' }
```

## Changelog

- v2.0.0:
  - Reworked to remove the "dict" methods. Now `User.genders.dict` is `User.genders` and `User.genders.human_dict` is `User.human_genders`
- v1.1.0:
  - Validate by default again.
  - Added `:class_attribute` option to specify class attribute to hold definitions
  - Cache translations on the fly
- v1.0.0:
  - Drop support for Ruby 1.8
  - Now getter method returns a String rather than a Symbol
  - Do not validate by default
  - Added `where_gender(:female)` scope
  - Removed the `_raw=` as setter automatically handles both types
  - Removed constants (e.g. `User::GENDERS`) and now use the class attribute to save the definition
- v0.3.0: Add support for `find_or_create_by` - just pass integer value

## Other solutions

There are tons of similar gems out there. Then why did I bother creating another one myself rather than sending pull requests to one of them? Because most of them define enum values as top-level predicate methods, which can cause method conflict. (`user.active?` vs `user.status_active?`)

* [Official Rails 4.1 Implementation](http://edgeguides.rubyonrails.org/4_1_release_notes.html#active-record-enums)
* [simple_enum](https://github.com/lwe/simple_enum)
* [enumerize](https://github.com/brainspec/enumerize)

Also, EnumAccessor has one of the simplest code base, so that you can easily hack on.
