# Configuration des améliorations de vaisseaux
# Charge depuis le fichier YAML et convertit les clés en symbols pour maintenir la compatibilité
ship_upgrades_data = YAML.load_file(Rails.root.join('config/catalogs/ship_upgrades.yml'))

# Convertit récursivement toutes les clés en symbols, sauf les niveaux qui doivent rester des entiers
SHIP_UPGRADES = ship_upgrades_data.deep_symbolize_keys.tap do |upgrades|
  upgrades.each do |type, config|
    # Convertit les clés de levels de symbol/string à integer pour maintenir la compatibilité
    if config[:levels].is_a?(Hash)
      config[:levels] = config[:levels].transform_keys { |k| k.to_s.to_i }
    end
  end
end.freeze 