# == Schema Information
#
# Table name: manufacturers
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

class Manufacturer < ApplicationRecord
  has_paper_trail
  belongs_to :organization

  has_many :donations, inverse_of: :manufacturer, dependent: :destroy

  has_many :line_items, through: :donations

  validates :name, presence: true, uniqueness: { scope: :organization, message: 'Manufacturer already exists' }

  scope :alphabetized, -> { order(:name) }

  scope :with_volumes, -> {
    left_joins(donations: :line_items)
      .select("manufacturers.*, SUM(COALESCE(line_items.quantity, 0)) AS volume")
      .group(:id)
  }

  def self.by_donation_date(count = 10, date_range = nil)
    # selects manufacturers that have donation qty > 0 in the provided date range
    # and sorts them by the date of the most recent donation
    joins(donations: :line_items).where(donations: { issued_at: date_range })
      .select('manufacturers.*, sum(line_items.quantity) as donation_count, max(donations.issued_at) as donation_date')
      .group('manufacturers.id')
      .having('sum(line_items.quantity) > 0')
      .order('donation_date DESC')
      .limit(count)
  end
end
