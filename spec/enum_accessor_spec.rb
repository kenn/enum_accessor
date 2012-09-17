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
    @user.gender_female?.should == true
    @user.gender_male?.should == false
  end

  it 'adds getter' do
    @user.gender.should == :female
  end

  it 'adds setter' do
    @user.gender = :male
    @user.gender_male?.should == true
  end

  it 'adds raw value getter' do
    @user.gender_raw.should == 0
  end

  it 'adds raw value setter' do
    @user.gender_raw = 1
    @user.gender_male?.should == true
  end

  it 'adds humanized getter' do
    I18n.locale = :ja
    @user.human_gender.should == '女'

    I18n.locale = :en
    @user.human_gender.should == 'Female'
  end

  it 'defines internal constant' do
    User::GENDERS.should == { "female" => 0, "male" => 1 }
  end

  it 'adds class methods' do
    User.genders.should == { :female => 0, :male => 1 }
  end

  it 'adds validation' do
    @user.gender = 'bogus'
    @user.valid?.should be_false

    @user.gender = 'male'
    @user.valid?.should be_true
  end
end
