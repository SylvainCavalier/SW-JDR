class XpChannel < ApplicationCable::Channel
    def subscribed
      stream_from "xp_channel"
    end
  end