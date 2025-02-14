class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    subscription = current_user.subscriptions.find_or_initialize_by(endpoint: params[:subscription][:endpoint])
    subscription.update(
      p256dh: params[:subscription][:p256dh],
      auth: params[:subscription][:auth]
    )

    if subscription.save
      render json: { status: "success" }, status: :ok
    else
      render json: { error: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    subscription = current_user.subscriptions.find_by(endpoint: params[:endpoint])
    subscription&.destroy

    head :ok
  end
end