require 'csv'

class ShakenFuryKySheltersImporter
  HEADERS = %i[
    shelter address city county state zip longitude latitude
    phone accepting notes source private_notes
    allow_pets pets unofficial accessibility active
  ].freeze

  SRC_FILE = "#{__dir__}/data/shelters_KY_fury-1.csv".freeze
  CLEAN_FILE = "#{__dir__}/data/shelters_KY_fury-1_clean.csv".freeze

  def self.shelters(override = false)
    unless override || File.file?(CLEAN_FILE)
      CSV.readlines(CLEAN_FILE, headers: true)
    else
      parse_source
    end
  end

private

  def self.id(n)
    n -= 24 if n > 35 # fields 36 to 60 are missing
    n -= 3 if n > 55 # fields 80 to 83 are missing
    n - 1 # it's 1-based
  end

  def self.parse_source
    r = 0
    source = nil
    CSV.open(CLEAN_FILE, 'wb', write_headers: true, headers: HEADERS) do |out|
      source = CSV.readlines(SRC_FILE).map do |row|
        r += 1
        next if r < 3 # Skip headers

        if row[0].nil? || !row[0].match?(/\A\s*\d+\s*\z/)
          puts "Non-conformant record on row #{r}"
          next
        end

        # create a "cleaned" set of fields
        data = row.map { |cell| cell.nil? ? '' : cell.strip.gsub(/\s+/, ' ') }

        #clean up address line two because bad data entry
        address1 = data[id(19)]
        city = data[id(22)]
        state = data[id(23)]
        zip = data[id(25)]
        city_state = "#{city}, #{state}".downcase
        address2 =
          if [1010, 469].include?(r) # address2 is bad on these rows
            ''
          else
            tmp = data[id(20)]
            (tmp.downcase != city_state && tmp.downcase != city.downcase)  ? ", #{tmp}" : ''
          end
        address = "#{address1}#{address2}, #{city}, #{state}  #{zip}"

        pets =
          case data[id(68)].downcase
          when 'yes' then 'Yes'
          when 'no' then 'No'
          else
            'Unknown'
          end

        notes = []
        notes << "Directions to Facility: #{data[id(69)]}" unless data[id(69)].empty?
        notes << "General Notes: #{data[id(70)]}" unless data[id(70)].empty?

        priv_notes = []
        priv_notes << "Evacuation Capacity: #{data[id(14)]}" unless data[id(14)].empty?
        priv_notes << "Longterm Capacity: #{data[id(15)]}" unless data[id(15)].empty?
        priv_notes << "Restrictions: #{data[id(101)]}" unless data[id(101)].empty?
        priv_notes << "Additional Notes: #{data[id(78)]}" unless data[id(78)].empty?

        record = {
          shelter: data[id(8)],
          address: address,
          city: city,
          county: data[id(24)],
          state: state,
          zip: zip,
          longitude: data[id(63)],
          latitude: data[id(64)],
          allow_pets: pets == 'Yes',
          pets: pets,
          phone: data[id(34)],
          accepting: data[id(17)].downcase == 'closed' ? 'no' : 'yes',
          notes: notes.join("\n\n"),
          source: "SHAKEN_FURY_2019_BATCH_1_ID:#{data[id(1)]}",
          private_notes: priv_notes.join("\n\n"),
          unofficial: false,
          accessibility: '',
          active: data[id(11)].downcase == 'no'
        }

        out << HEADERS.map { |h| record[h] }

        record
      end
    end
    source
  end
end
