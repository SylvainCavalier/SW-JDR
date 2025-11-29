# Charge les recettes de craft depuis le fichier YAML
# Les clés internes (difficulty, ingredients) sont converties en symbols pour maintenir la compatibilité
# Les clés de premier niveau (noms des items) restent en strings pour correspondre aux noms en base de données
craft_recipes_data = YAML.load_file(Rails.root.join('config/catalogs/craft_recipes.yml'))

# Symbolise uniquement les clés internes (difficulty, ingredients), pas les noms d'items
CRAFT_RECIPES = craft_recipes_data.transform_values { |v| v.deep_symbolize_keys }