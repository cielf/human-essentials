# == Schema Information
#
# Table name: items
#
#  id                           :integer          not null, primary key
#  active                       :boolean          default(TRUE)
#  barcode_count                :integer
#  category                     :string
#  distribution_quantity        :integer
#  name                         :string
#  on_hand_minimum_quantity     :integer          default(0), not null
#  on_hand_recommended_quantity :integer
#  package_size                 :integer
#  partner_key                  :string
#  value_in_cents               :integer          default(0)
#  visible_to_partners          :boolean          default(TRUE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  item_category_id             :integer
#  kit_id                       :integer
#  organization_id              :integer
#

class Item < ApplicationRecord
  has_paper_trail
  include Filterable
  include Exportable
  include Valuable

  after_update :update_associated_kit_name, if: -> { kit.present? }

  belongs_to :organization # If these are universal this isn't necessary
  belongs_to :base_item, counter_cache: :item_count, primary_key: :partner_key, foreign_key: :partner_key, inverse_of: :items
  belongs_to :kit, optional: true
  belongs_to :item_category, optional: true

  validates :name, uniqueness: { scope: :organization }
  validates :name, presence: true
  validates :organization, presence: true
  validates :distribution_quantity, numericality: { greater_than: 0 }, allow_blank: true
  validates :on_hand_recommended_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :on_hand_minimum_quantity, numericality: { greater_than_or_equal_to: 0 }

  has_many :line_items, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :barcode_items, as: :barcodeable, dependent: :destroy
  has_many :storage_locations, through: :inventory_items
  has_many :donations, through: :line_items, source: :itemizable, source_type: "::Donation"
  has_many :distributions, through: :line_items, source: :itemizable, source_type: "::Distribution"

  scope :active, -> { where(active: true) }

  # Add spec for these
  scope :kits, -> { where.not(kit_id: nil) }
  scope :loose, -> { where(kit_id: nil) }

  scope :visible, -> { where(visible_to_partners: true) }
  scope :alphabetized, -> { order(:name) }
  scope :by_base_item, ->(base_item) { where(base_item: base_item) }
  scope :by_partner_key, ->(partner_key) { where(partner_key: partner_key) }

  scope :by_size, ->(size) { joins(:base_item).where(base_items: { size: size }) }
  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .includes(:base_item)
      .alphabetized
  }

  # Scopes - explanation of business rules for filtering scopes as of 20240518.  This is currently a mess.
  # 1/  Disposable.   Disposables are only the disposable diapers for children.  So we deliberately exclude adult and cloth
  # 2/  Cloth.  Cloth diapers for children.  Exclude adult cloth.
  # 3/  Adult incontinence.  Items for adult incontinence -- diapers, ai pads, but not adult wipes.
  # 4/  Period supplies.  We have a category for menstrual supplies, which includes pads and tampons as indicated below, but also liners.
  #        In discussion with the business about liners being in AI vs period supplies.   Because what we have is almost
  #        certainly wrong.
  # 5/  Other -- Miscellaneous,  plus a few things that have been specifically called out
  # Known holes and ambiguities as of 20240518.  Working on these with the business
  # 1/  It looks to me like we are totally excluding adult cloth.  a *very* small value, but...
  # 2/  Liners.   Liners are a big problem.  *Trying* to get  straight answer from the business so that we don't doublecount
  #                because liners can, in the real world, be menstrual supplies or AI, and different banks are going to have
  #                different uses.   Complicating factor -- there are, apparently, some products that are used for AI,
  #                but not menstrual, some that are used for menstrual, but not AI, and some that are used for either.
  # 3/  Period supplies -- currently we just have it as tampons and pads.  CL thinks it should be category: menstrual supplies,
  #                 but see liner issues above.  (note:  "Period supplies" category, in the code below, doesn't exist)
  # 4/  Looks like we are double counting cloth training pants
  # 4/  Things we might not be counting:    Wipes -- Childrens

  scope :disposable, -> {
    joins(:base_item)
      .where("lower(base_items.category) LIKE '%diaper%'")
      .where.not("lower(base_items.category) LIKE '%cloth%' OR lower(base_items.name) LIKE '%cloth%'")
      .where.not("lower(base_items.category) LIKE '%adult%'")
  }

  scope :cloth_diapers, -> {
    joins(:base_item)
      .where("lower(base_items.category) LIKE '%cloth%' OR lower(base_items.name) LIKE '%cloth%'")
      .where.not("lower(base_items.category) LIKE '%adult%'")
  }

  scope :adult_incontinence, -> {
    joins(:base_item)
      .where(items: { partner_key: %w(adult_incontinence underpads liners) })
      .or(where("items.partner_key LIKE '%adult%' AND items.partner_key NOT LIKE '%cloth%' AND items.partner_key NOT LIKE '%wipes'"))
      .or(where("lower(base_items.category) LIKE '%adult%' AND lower(base_items.category) NOT LIKE '%wipes%'"))
  }

  scope :period_supplies, -> {
    joins(:base_item)
      .where(items: { partner_key: %w(tampons pads) })
      .or(where("base_items.category = 'Period Supplies'"))
  }

  scope :other_categories, -> {
    joins(:base_item)
      .where(items: { partner_key: %w(cloth_training_pants wipes adult_wipes) })
      .or(where("base_items.category = 'Miscellaneous'"))
  }

  before_destroy :validate_destroy, prepend: true

  def self.barcoded_items
    joins(:barcode_items).order(:name).group(:id)
  end

  def self.storage_locations_containing(item)
    StorageLocation.joins(:inventory_items).where("inventory_items.item_id = ?", item.id)
  end

  def self.barcodes_for(item)
    BarcodeItem.where("barcodeable_id = ?", item.id)
  end

  def self.reactivate(item_ids)
    item_ids = Array.wrap(item_ids)
    Item.where(id: item_ids).find_each { |item| item.update(active: true) }
  end

  def has_inventory?(inventory = nil)
    if inventory
      inventory.quantity_for(item_id: id).positive?
    else
      inventory_items.where("quantity > 0").any?
    end
  end

  def is_in_kit?
    organization.kits
      .active
      .joins(:line_items)
      .where(line_items: { item_id: id}).any?
  end

  def can_delete?(inventory = nil)
    can_deactivate_or_delete?(inventory) && line_items.none? && !barcode_count&.positive?
  end

  # @return [Boolean]
  def can_deactivate_or_delete?(inventory = nil)
    if inventory.nil? && Event.read_events?(organization)
      inventory = View::Inventory.new(organization_id)
    end
    # Cannot deactivate if it's currently in inventory in a storage location. It doesn't make sense
    # to have physical inventory of something we're now saying isn't valid.
    # If an active kit includes this item, then changing kit allocations would change inventory
    # for an inactive item - which we said above we don't want to allow.

    !has_inventory?(inventory) && !is_in_kit?
  end

  def validate_destroy
    unless can_delete?
      errors.add(:base, "Cannot delete item - it has already been used!")
      throw(:abort)
    end
  end

  def deactivate!
    unless can_deactivate_or_delete?
      raise "Cannot deactivate item - it is in a storage location or kit!"
    end
    if kit
      kit.deactivate
    else
      update!(active: false)
    end
  end

  def other?
    partner_key == "other"
  end

  def self.gather_items(current_organization, global = false)
    if global
      where(id: current_organization.barcode_items.all.pluck(:barcodeable_id))
    else
      where(id: current_organization.barcode_items.pluck(:barcodeable_id))
    end
  end
  # Convenience method so that other methods can be simplified to
  # expect an id or an Item object

  def to_i
    id
  end

  def to_h
    { name: name, item_id: id }
  end

  def self.csv_export_headers
    ["Name", "Barcodes", "Base Item", "Quantity"]
  end

  # TODO remove this method once read_events? is true everywhere
  def csv_export_attributes
    [
      name,
      barcode_count,
      base_item.name,
      inventory_items.sum(&:quantity)
    ]
  end

  # @param items [Array<Item>]
  # @param inventory [View::Inventory]
  # @return [String]
  def self.generate_csv_from_inventory(items, inventory)
    item_quantities = items.to_h { |i| [i.id, inventory.quantity_for(item_id: i.id)] }
    CSV.generate(headers: true) do |csv|
      csv_data = items.map do |item|
        attributes = [item.name, item.barcode_count, item.base_item.name, item_quantities[item.id]]
        attributes.map { |attr| normalize_csv_attribute(attr) }
      end
      ([csv_export_headers] + csv_data).each { |row| csv << row }
    end
  end

  def default_quantity
    distribution_quantity || 50
  end

  def inventory_item_at(storage_location_id)
    inventory_items.find_by(storage_location_id: storage_location_id)
  end

  private

  def update_associated_kit_name
    kit.update(name: name)
  end
end
