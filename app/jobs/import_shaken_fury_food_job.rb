class ImportShakenFuryFoodJob < ApplicationJob
  queue_as :default

  def perform(*args)
    logger.info "Starting ImportFemaDistributionPointsJob #{Time.now}"
    food_data = ShakenFuryFoodImporter.distribution_points.compact
    imported = 0
    food_data.each { |data| imported += deduplicated_import!(data, true) }
    logger.info "ImportFemaDistributionPointsJob Complete - Records received: #{food_data.length}, Imported DistributionPoints: #{imported}"
  end

private

  def deduplicated_import!(data, skip_dedup = false)
    # This is a very naive deduplication effort, yes it does
    # an unindexed scan of the database against several columns of text
    #
    # TODO: Use Arel for the where named functions
    # arel = DistributionPoint.arel_table

    if data.nil?
      puts 'We got a snag with bad data here.'
      return 0
    end

    if skip_dedup
      pod = nil
    else
      if pod = find_by_address(data).first
        logger.info "Duplicate found by address: #{data[:facility_name]} @ #{data[:address]}"
      elsif pod = find_by_coordinates(data).first
        logger.info "Duplicate found by coordinates: #{data[:facility_name]} @ [#{data[:latitude]}, #{data[:longitude]}]"
      elsif pod = find_by_location_fields(data).first
        logger.info "Duplicate found by fields: #{data[:facility_name]} @ [#{data[:city]}, #{data[:state]}, #{data[:zip]}]"
      elsif pod = find_by_source(data).first
        logger.info "Duplicate found by source: #{data[:facility_name]} @ [#{data[:source]}]"
      else
        pod = nil
      end
    end

    if pod.nil?
      pod = DistributionPoint.create!(data)
      pod.geocode
      pod.recode_geofields
      pod.save
      1
    else
      unarchive!(pod)
      0
    end
  end

  def find_by_address(data)
    DistributionPoint.unscope(:where).where('LOWER(TRIM(address)) = ?', data[:address].strip.downcase)
  end

  def find_by_coordinates(data)
    lat = data[:latitude].to_f
    lon = data[:longitude].to_f
    delta = 0.0002
    DistributionPoint.unscope(:where).where(
      '(latitude between ? and ?) AND (longitude between ? and ?)',
      lat - delta, lat + delta, lon - delta, lon + delta
    )
  end

  def find_by_location_fields(data)
    DistributionPoint.unscope(:where).where(
      'LOWER(TRIM(facility_name)) = ? AND LOWER(TRIM(city)) = ? AND LOWER(TRIM(state)) = ? AND LOWER(TRIM(zip)) = ?',
      data[:facility_name].strip.downcase, data[:city].strip.downcase, data[:state].strip.downcase, data[:zip].strip.downcase
    )
  end

  def find_by_source(data)
    DistributionPoint.unscope(:where).where('LOWER(TRIM(source)) = ?', data[:source].strip.downcase)
  end

  def unarchive!(pod)
    if pod.archived
      logger.info "Unarchiving pre-existing distribution point with ID #{pod.id}"
      pod.update_columns(archived: false, updated_at: Time.now)
    end
  end
end
