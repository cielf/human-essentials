class ChangeClientShareToBeInteger < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      change_column  :partner_counties, :client_share, :integer
    }
  end
end
