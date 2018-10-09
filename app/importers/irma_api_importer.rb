require 'rubygems'
require 'httparty'

class IrmaAPIImporter
  include HTTParty
  base_uri 'https://irma-api.herokuapp.com/api/v1'
  format :json

  def self.needs
    get('/needs')['needs']
  end

  def self.shelters
    get('/shelters')['shelters'].map do |shelter|
      shelter['allow_pets'] = if shelter['pets'] == 'Yes' then true
                              elsif shelter['pets'] == 'No' then false
                              end
      shelter['pets'] = shelter['pets_notes']
      shelter['active'] = true
      shelter['accepting'] =
        if shelter['accepting']
          :yes
        else
          shelter['accpeting'].nil? ? :unknown : :no
        end
      shelter.delete('id')
      shelter.except!('pets_notes')
    end
  end
end
