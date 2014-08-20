# encoding: UTF-8

require 'spec_helper'

ActiveRecord::Base.connection.create_table :users, force: true do |t|
  t.column :gender, :integer, default: 0
end

class User < ActiveRecord::Base
  enum_accessor :gender, [ :female, :male ]
end

describe EnumAccessor do
  before do
    @user = User.new
  end

  it 'adds checker' do
    expect(@user.gender_female?).to eq(true)
    expect(@user.gender_male?).to eq(false)
  end

  it 'adds getter' do
    expect(@user.gender).to eq(:female)
  end

  it 'adds setter' do
    @user.gender = :male
    expect(@user.gender_male?).to eq(true)
  end

  it 'adds raw value getter' do
    expect(@user.gender_raw).to eq(0)
  end

  it 'adds raw value setter' do
    @user.gender_raw = 1
    expect(@user.gender_male?).to eq(true)
  end

  it 'adds humanized methods' do
    I18n.locale = :ja
    expect(User.human_attribute_name(:gender)).to eq('性別')
    expect(@user.human_gender).to eq('女')
    expect(User.human_genders(:female)).to eq('女')
    expect(User.human_genders).to eq({ :female => '女', :male => '男' })

    I18n.locale = :en
    expect(User.human_attribute_name(:gender)).to eq('Gender')
    expect(@user.human_gender).to eq('Female')
    expect(User.human_genders(:female)).to eq('Female')
    expect(User.human_genders).to eq({ :female => 'Female', :male => 'Male' })
  end

  it 'defines internal constant' do
    expect(User::GENDERS).to eq({ "female" => 0, "male" => 1 })
  end

  it 'adds class methods' do
    expect(User.genders).to eq({ :female => 0, :male => 1 })
    expect(User.genders[:female]).to eq(0)
    expect(User.genders(:female)).to eq(0)
  end

  it 'adds validation' do
    @user.gender = 'bogus'
    expect(@user.valid?).to be_falsey

    @user.gender = 'male'
    expect(@user.valid?).to be_truthy
  end
end
