# == Schema Information
#
# Table name: counties
#
#  id                 :bigint           not null, primary key
#  name               :string
#  state_or_territory :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :county do
    name { "MyString" }
    state_or_territory { "MyString" }
  end
end
