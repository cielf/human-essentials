class Reports::NdbnAnnualsController < ApplicationController
  def index
    @years = get_reports_years
    @month_remaing_to_report = 12 - Time.current.month
  end

  def show
    raise ActionController::RoutingError.new('Not Found') unless validate_show_params

    reporters = []

    @year = params[:year]
    reporter_params = { year: @year, organization: current_organization }

    acquisition_reporter = Reports::AcquisitionReportService.new(reporter_params)
    @acquisition_report = acquisition_reporter.report
    reporters << acquisition_reporter

    warehouse_reporter = Reports::WarehouseInfoReportService.new(reporter_params)
    @warehouse_report = warehouse_reporter.report
    reporters << warehouse_reporter

    adult_incontinence_reporter = Reports::AdultIncontinenceReportService.new(reporter_params)
    @adult_incontinence_report = adult_incontinence_reporter.report
    reporters << adult_incontinence_reporter


    # Other Products
    @other_products = current_organization.items.where(partner_key: other_products_partner_keys).map(&:name)

    # Partner Information report values
    @partners = current_organization.partners
    @partner_agency_type = partner_agency_type
    @partner_zipcodes_serviced = partner_zipcodes_serviced

    # Children Served report values
    @children_served_by_partner = children_served_by_partner.to_s
    @monthly_children_served = (children_served_by_partner / 12).to_s

    # Summary Information report values
    @donations = current_organization.donations
    @donations_amount = @donations.pluck(:money_raised).compact.sum.to_s

    respond_to do |format|
      format.html
      format.csv do
        send_data Exports::ExportReportCSVService.new(reporters: reporters).generate_csv, filename: "NdbnAnnuals-#{@year}-#{Time.zone.today}.csv"
      end
    end
  end

  private

  def get_reports_years
    foundation_year = current_organization.created_at.year
    @actual_year = Time.current.year

    year_range = foundation_year...@actual_year
    year_range.to_a
  end

  def annual_drives
    @diaper_drives.within_date_range("2021-01-01 - 2021-12-31")
  end

  def number_of_diapers_from_drives
    annual_drives.map(&:donation_quantity).sum
  end

  def money_from_drives
    annual_drives.map(&:in_kind_value).sum
  end

  def virtual_diaper_drives
    annual_drives.where(virtual: true)
  end

  def money_from_virtual_drives
    virtual_diaper_drives.map(&:donation_quantity).sum
  end

  def number_of_diapers_from_virtual_drives
    virtual_diaper_drives.map(&:in_kind_value).sum
  end

  def partner_agency_type
    @partners.map do |partner|
      partner.profile.agency_type
    end
  end

  def partner_zipcodes_serviced
    @partners.map do |partner|
      partner.profile.zips_served
    end
  end

  def children_served_by_partner
    current_organization.partners.map do |partner|
      partner.profile.children.count
    end.sum
  end

  def base_item_json(key)
    file = File.read("db/base_items.json")
    json = JSON.parse(file)

    json[key].map(&:values).map { |keys| keys[0] }
  end

  def other_products_partner_keys
    menstrual_supplies = base_item_json("Menstrual Supplies/Items")
    miscellaneous = base_item_json("Miscellaneous")
    training_pants = base_item_json("Training Pants")
    wipes_adult = base_item_json("Wipes - Adults")
    wipes_children = base_item_json("Wipes - Childrens")

    menstrual_supplies + miscellaneous + training_pants + wipes_adult + wipes_children
  end

  def validate_show_params
    return true unless params.key?(:year)

    params[:year].to_i.positive?
  end
end
