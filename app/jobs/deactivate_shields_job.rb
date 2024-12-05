class DeactivateShieldsJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    user.deactivate_all_shields
    Rails.logger.info "Les boucliers de l'utilisateur #{user.username} ont été désactivés automatiquement."
  end
end