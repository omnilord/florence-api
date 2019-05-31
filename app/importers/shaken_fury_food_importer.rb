require 'csv'

class ShakenFuryFoodImporter

  SRC_FILE = "#{__dir__}/data/shaken_fury_food.csv".freeze

  def self.distribution_points(override = false)
    r = 0
    CSV.readlines(SRC_FILE).map do |row|
      r += 1
      next if r == 1 # Skip headers

      # create a "cleaned" set of fields
      data = row.map { |cell| cell.nil? ? '' : cell.strip.gsub(/\s+/, ' ') }

      address1 = data[9]
      city = data[10]
      state = data[12]
      address = "#{address1}, #{city}, #{state}"

      notes = []

      {
        facility_name: data[2],
        address: address,
        city: city,
        county: data[13],
        state: state,
        phone: '',
        notes: notes.join("\n\n"),
        source: 'SHAKEN_FURY_2019_MASTER_GROUND_TRUTH_DOC',
        longitude: '',
        latitude: '',
        active: true,
        archived: false
      }
    end
  end
end
