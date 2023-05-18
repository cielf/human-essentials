require 'csv'
namespace :db do
  desc "Load US Counties"
  task :load_us_counties => :environment do
      puts 'loading US counties and equivalents.  '
      counties = []
      CSV.foreach("lib//assets//us_county_and_equivalent_list.csv") do |row|
        counties<< {name: row[0], region: row[1]}
      end
      County.upsert_all( counties, unique_by: [:name, :region])
  end
end