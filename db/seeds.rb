puts "Reset the database..."
User.destroy_all
Group.destroy_all
Race.destroy_all
ClassePerso.destroy_all
Skill.destroy_all

puts "Creating groups..."
group1 = Group.create!(name: "MJ", description: "Le groupe des Maîtres du Jeu. Prosternez vous.")
group2 = Group.create!(name: "PNJ", description: "Le groupe des marchands et auxiliaires de jeu")
group3 = Group.create!(name: "PJ", description: "Les joueurs jouent au jeu")
group4 = Group.create!(name: "Hackers", description: "Les hackers peuvent hacker les données des autres")

puts "Creating races..."
human = Race.create!(name: "Humain", description: "Une espèce polyvalente.")
kaminoan = Race.create!(name: "Kaminien", description: "Les bio-savants de Kamino.")
codruji = Race.create!(name: "Codru'Ji", description: "Les êtres à quatre bras de Munto Codru.")
toydarian = Race.create!(name: "Torydarien", description: "Les ingénieurs venus de Toydaria.")
clawdite = Race.create!(name: "Clawdite", description: "Les métamorphes de Zolan.")

puts "Creating classes..."
senator = ClassePerso.create!(name: "Sénateur", description: "Politicien influent.")
bio_savant = ClassePerso.create!(name: "Bio-savant", description: "Expert en sciences de la vie.")
autodidact = ClassePerso.create!(name: "Autodidacte", description: "Un apprenant autonome.")
mercenary = ClassePerso.create!(name: "Mercenaire", description: "Un combattant à louer.")
cyber_engineer = ClassePerso.create!(name: "Cyber-ingénieur", description: "Spécialiste des technologies avancées.")
smuggler = ClassePerso.create!(name: "Contrebandier", description: "Expert dans l'art de la contrebande.")

puts "Creating the users and assigning them to the corresponding groups, races, and classes..."
User.create!(username: "MJ", email: "mj@rpg.com", password: "motdepasse", credits: 100000, group: group1)

players = [
  { username: "Jarluc de Macharlon", email: "jarluc@rpg.com", race: human, classe_perso: senator, hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Kay Noah", email: "kay@rpg.com", race: kaminoan, classe_perso: bio_savant, hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Nuok", email: "nuok@rpg.com", race: codruji, classe_perso: autodidact, hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Pluto", email: "pluto@rpg.com", race: human, classe_perso: mercenary, hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Viggo", email: "viggo@rpg.com", race: toydarian, classe_perso: cyber_engineer, hp_max: 30, hp_current: 30, shield_max: 30, credits: 1000 },
  { username: "Mas Tandor", email: "mas@rpg.com", race: clawdite, classe_perso: smuggler, hp_max: 30, hp_current: 30, shield_max: 30, credits: 1000 }
]

players.each do |player|
  User.create!(player.merge(password: "password", group: group3))
end

puts "Creating skills..."
Skill.create!(name: "Médecine", description: "Soigne les blessures.")

puts "Task completed!"
