puts "Reset the database..."
User.destroy_all
Group.destroy_all

puts "Create the groups first..."
group1 = Group.create(name: "MJ", description: "Le groupe des Maîtres du Jeu. Prosternez vous.")
group2 = Group.create(name: "PNJ", description: "Le groupe des marchands et auxiliaires de jeu")
group3 = Group.create(name: "PJ", description: "Les joueurs jouent au jeu")
group4 = Group.create(name: "Hackers", description: "Les hackers peuvent hacker les données des autres")

puts "Create the users and assign them to the corresponding groups..."
user1 = User.create(username: "Ewan Kenobi", email: "ewan@wanadoo.fr", password: "azerty", credits: 200, group: group1)
user2 = User.create(username: "Arnax", email: "arnax@wanadoo.fr", password: "azerty", credits: 100, group: group2)
user3 = User.create(username: "Nuok", email: "nuok@wanadoo.fr", password: "azerty", credits: 100, group: group3)
user4 = User.create(username: "Viggo", email: "viggo@wanadoo.fr", password: "azerty", credits: 100, group: group4)

puts "Task completed !"
