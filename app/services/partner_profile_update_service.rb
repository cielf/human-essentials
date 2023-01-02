class PartnerProfileUpdateService
  include ServiceObjectErrorsMixin

  def initialize(old_partner, new_partner_params, new_profile_params)
    @partner = old_partner
    @profile = @partner.profile
    @partner_params = new_partner_params
    @old_partner_counties = old_partner.partner_counties
    @profile_params = new_profile_params
  end

  def call
    @partner.update(@partner_params)

    @partner.partner_counties.each(&:destroy!)
    @partner.reload
    # Replace the current partner with the new parameters

    @partner.update @partner_params

    if @partner.valid?
      @profile.update(@profile_params)
      return @profile.valid?  # Returns true if no errors
    end
    false # problem on partner update
  end
end
