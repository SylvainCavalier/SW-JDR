module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def subscribed
      logger.info "User #{current_user.id} subscribed to #{params[:stream]}"
    end

    def unsubscribed
      logger.info "User #{current_user.id} unsubscribed from #{params[:stream]}"
    end
  end
end
