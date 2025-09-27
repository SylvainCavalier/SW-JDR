# Charge la liste des causes d'avaries depuis un fichier YAML
require 'yaml'

config_file_path = Rails.root.join('config', 'ship_damage_causes.yml')

begin
  raw_config = YAML.load_file(config_file_path)
  causes = Array(raw_config['causes']).map(&:to_s).reject(&:empty?)
  Rails.application.config.ship_damage_causes = causes.freeze
rescue StandardError => e
  Rails.logger.error("[ShipDamageCauses] Erreur de chargement YAML: #{e.message}")
  Rails.application.config.ship_damage_causes = [].freeze
end


