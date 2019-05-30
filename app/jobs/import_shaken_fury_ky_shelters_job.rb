class ImportShakenFuryKySheltersJob < ApplicationJob
  queue_as :default

  def perform(*args)
    logger.info "Starting ImportFemaSheltersJob #{Time.now}"
    ky_data = ShakenFuryKySheltersImporter.shelters.compact
    imported = 0
    ky_data.each { |data| imported += deduplicated_import!(data) }
    logger.info "ImportFemaSheltersJob Complete - Records received: #{ky_data.length}, Imported Shelters: #{imported}"
  end

private

  def deduplicated_import!(data)
    # This is a very naive deduplication effort, yes it does
    # an unindexed scan of the database against several columns of text
    #
    # TODO: Use Arel for the where named functions
    # arel = Shelter.arel_table

    if data.nil?
      puts 'We got a snag with bad data here.'
      return 0
    end

    if shelter = find_by_address(data).first
      logger.info "Duplicate found by address: #{data[:shelter]} @ #{data[:address]}"
    elsif shelter = find_by_coordinates(data).first
      logger.info "Duplicate found by coordinates: #{data[:shelter]} @ [#{data[:latitude]}, #{data[:longitude]}]"
    elsif shelter = find_by_location_fields(data).first
      logger.info "Duplicate found by fields: #{data[:shelter]} @ [#{data[:city]}, #{data[:state]}, #{data[:zip]}]"
    elsif shelter = find_by_source(data).first
      logger.info "Duplicate found by source: #{data[:shelter]} @ [#{data[:source]}]"
    else
      shelter = nil
    end

    if shelter.nil?
      Shelter.create!(data)
      1
    else
      unarchive!(shelter)
      0
    end
  end

  def find_by_address(data)
    Shelter.unscope(:where).where('LOWER(TRIM(address)) = ?', data[:address].strip.downcase)
  end

  def find_by_coordinates(data)
    lat = data[:latitude].to_f
    lon = data[:longitude].to_f
    delta = 0.0002
    Shelter.unscope(:where).where(
      '(latitude between ? and ?) AND (longitude between ? and ?)',
      lat - delta, lat + delta, lon - delta, lon + delta
    )
  end

  def find_by_location_fields(data)
    Shelter.unscope(:where).where(
      'LOWER(TRIM(shelter)) = ? AND LOWER(TRIM(city)) = ? AND LOWER(TRIM(state)) = ? AND LOWER(TRIM(zip)) = ?',
      data[:shelter].strip.downcase, data[:city].strip.downcase, data[:state].strip.downcase, data[:zip].strip.downcase
    )
  end

  def find_by_source(data)
    Shelter.unscope(:where).where('LOWER(TRIM(source)) = ?', data[:source].strip.downcase)
  end

  def unarchive!(shelter)
    unless shelter.active
      logger.info "Unarchiving pre-existing shelter with ID #{shelter.id}"
      shelter.update_columns(active: true, updated_at: Time.now)
    end
  end
end
