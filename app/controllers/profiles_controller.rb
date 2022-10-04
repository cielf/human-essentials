class ProfilesController < ApplicationController
  def edit
    @partner = current_organization.partners.includes(:partner_counties).find(params[:id]).profile
  end

  def update
    @partner = current_organization.partners.includes(:partner_counties).find(params[:id]).profile
    if (PartnerProfileUpdateService.new(@partner, edit_profile_params).call)
      redirect_to partner_path(@partner.partner) + "#partner-information", notice: "#{@partner.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  private

  def edit_profile_params
     params.require(:partners_partner).permit(
      :name,
      :agency_type,
      :other_agency_type,
      :partner_status,
      :proof_of_partner_status,
      :agency_mission,
      :address1,
      :address2,
      :city,
      :state,
      :zip_code,
      :website,
      :facebook,
      :twitter,
      :founded,
      :form_990,
      :proof_of_form_990,
      :program_name,
      :program_description,
      :program_age,
      :case_management,
      :evidence_based,
      :evidence_based_description,
      :program_client_improvement,
      :essentials_use,
      :receives_essentials_from_other,
      :currently_provide_diapers,
      :turn_away_child_care,
      :program_address1,
      :program_address2,
      :program_city,
      :program_state,
      :program_zip_code,
      :client_capacity,
      :incorporate_plan,
      :responsible_staff_position,
      :storage_space,
      :describe_storage_space,
      :trusted_pickup,
      :income_requirement_desc,
      :serve_income_circumstances,
      :income_verification,
      :internal_db,
      :maac,
      :population_black,
      :population_white,
      :population_hispanic,
      :population_asian,
      :population_american_indian,
      :population_island,
      :population_multi_racial,
      :population_other,
      :zips_served,
      :at_fpl_or_below,
      :above_1_2_times_fpl,
      :greater_2_times_fpl,
      :poverty_unknown,
      :ages_served,
      :executive_director_name,
      :executive_director_phone,
      :executive_director_email,
      :primary_contact_name,
      :primary_contact_phone,
      :primary_contact_mobile,
      :primary_contact_email,
      :pick_up_method,
      :pick_up_name,
      :pick_up_phone,
      :pick_up_email,
      :distribution_times,
      :new_client_times,
      :more_docs_required,
      :sources_of_funding,
      :sources_of_diapers,
      :essentials_budget,
      :essentials_funding_source,
      :enable_child_based_requests,
      :enable_individual_requests,
      partner_counties_attributes: %i(county_id client_share _destroy),
      documents: []
    )
  end
end
