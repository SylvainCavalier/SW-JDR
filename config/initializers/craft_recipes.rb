# Charge les recettes de craft depuis le fichier YAML
# Les clés internes (difficulty, ingredients) sont converties en symbols pour maintenir la compatibilité
craft_recipes_data = YAML.load_file(Rails.root.join('config/catalogs/craft_recipes.yml'))

CRAFT_RECIPES = craft_recipes_data.deep_symbolize_keys