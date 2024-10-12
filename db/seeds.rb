puts "Reset the database..."
User.destroy_all
Group.destroy_all

puts "Create the groups first..."
group1 = Group.create(name: "MJ", description: "Le groupe des Maîtres du Jeu. Prosternez vous.")
group2 = Group.create(name: "PNJ", description: "Le groupe des marchands et auxiliaires de jeu")
group3 = Group.create(name: "PJ", description: "Les joueurs jouent au jeu")
group4 = Group.create(name: "Hackers", description: "Les hackers peuvent hacker les données des autres")

puts "Create the users and assign them to the corresponding groups..."
User.create(username: "MJ", email: "mj@rpg.com", password: "motdepasse", credits: 0, group: group1)

players = [
  { username: "Jarluc de Macharlon", email: "jarluc@rpg.com", race: "Humain", class_name: "Sénateur", hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Kay Noah", email: "kay@rpg.com", race: "Kaminien", class_name: "Bio-savant", hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Nuok", email: "nuok@rpg.com", race: "Codru'Ji", class_name: "Autodidacte", hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Pluto", email: "pluto@rpg.com", race: "Humain", class_name: "Mercenaire", hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Viggo", email: "viggo@rpg.com", race: "Torydarien", class_name: "Cyber-ingénieur", hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Mas Tandor", email: "mas@rpg.com", race: "Clawdite", class_name: "Contrebandier", hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 }
]

players.each do |player|
  User.create(player.merge(password: "password", group: group3))
end

puts "Task completed !"
