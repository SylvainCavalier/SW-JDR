class Holonew < ApplicationRecord
  belongs_to :sender, class_name: "User", foreign_key: "user_id"
  belongs_to :receiver, class_name: "User", foreign_key: "target_user", optional: true
  has_many :readers, through: :holonew_reads, source: :user
  has_many :holonew_reads, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true

  scope :unread, -> { where(read: false) }

  after_create_commit :update_holonews_counter

  def update_holonews_counter
    users = if target_user.present?
              [User.find(target_user)]
            elsif target_group.present? || target_group == 'all'
              User.all
            else
              []
            end
  
    users.each do |user|
      puts "🔔 Envoi d'une notification push à #{user.username}"
      send_push_notification(user, "Nouvelle Holonew", title)
  
      # 🔹 Si l'utilisateur n'a pas encore lue cette Holonew, créer un enregistrement HolonewRead
      unless user.holonew_reads.exists?(holonew: self)
        user.holonew_reads.create(holonew: self, read: false)
      end
  
      # 🔹 Compter les holonews non lues de l'utilisateur
      unread_count = user.holonew_reads.where(read: false).count
  
      puts "📊 Mise à jour compteur pour #{user.username} - Non lus : #{unread_count}"
  
      broadcast_replace_to "user_#{user.id}_holonews_counter",
        target: "user_#{user.id}_holonews_counter",
        partial: "holonews/count",
        locals: { unread_count: { user_id: user.id, count: unread_count } }
    end
  end

  private

  def send_push_notification(user, title, body)
    user.subscriptions.each do |subscription|
      begin
        puts "📨 Tentative d'envoi de notification à #{user.username} (#{subscription.endpoint})"
  
        Webpush.payload_send(
          message: JSON.generate({ title: title, body: body }),
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh,
          auth: subscription.auth,
          vapid: {
            subject: Rails.application.config.vapid_keys[:subject],
            public_key: Rails.application.config.vapid_keys[:public_key],
            private_key: Rails.application.config.vapid_keys[:private_key]
          }
        )
  
        puts "✅ Notification envoyée à #{user.username} !"
  
      rescue StandardError => e
        puts "⚠️ Erreur WebPush pour #{user.username} : #{e.message}"
      end
    end
  end
end