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
require "rails_helper"

RSpec.describe County, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
