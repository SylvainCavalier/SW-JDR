class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    Rails.logger.debug "Raw params: #{params.inspect}"
  
    unless params[:subscription].present?
      Rails.logger.error "Subscription params missing!"
      render json: { error: "Subscription params are missing" }, status: :unprocessable_entity
      return
    end
  
    subscription_params = params.require(:subscription).permit(:endpoint, :p256dh, :auth)
    Rails.logger.debug "Permitted subscription params: #{subscription_params.inspect}"
  
    # Vérifier si un abonnement avec cet endpoint existe déjà pour cet utilisateur
    subscription = current_user.subscriptions.find_or_initialize_by(endpoint: subscription_params[:endpoint])
  
    if subscription.new_record? || subscription.changed?
      if subscription.update(subscription_params)
        Rails.logger.debug "Subscription created/updated successfully"
        render json: { status: "success" }, status: :ok
      else
        Rails.logger.error "Subscription failed to save: #{subscription.errors.full_messages}"
        render json: { error: subscription.errors.full_messages }, status: :unprocessable_entity
      end
    else
      Rails.logger.debug "Subscription already exists and is unchanged"
      render json: { status: "already_subscribed" }, status: :ok
    end
  end

  def destroy
    subscription = current_user.subscriptions.find_by(endpoint: params[:endpoint])
    subscription&.destroy
    head :ok
  end

  private

  def permitted_subscription_params
    if params[:subscription].is_a?(Hash)
      params.require(:subscription).permit(:endpoint, :p256dh, :auth)
    else
      Rails.logger.error "Unexpected params format: #{params[:subscription].inspect}"
      {}
    end
  end
end