class TransactionsController < ApplicationController
  before_action :authenticate_user!

  def new
    @transaction = Transaction.new
  end

  def create
    receiver = User.where('LOWER(username) = ?', params[:transaction][:receiver_username].downcase).first

    if receiver.nil?
      redirect_to new_transaction_path, alert: 'Destinataire introuvable'
      return
    end
  
    @transaction = Transaction.new(transaction_params)
    @transaction.sender = current_user
    @transaction.receiver = receiver
  
    if @transaction.amount <= current_user.credits && @transaction.amount > 0
      ActiveRecord::Base.transaction do
        current_user.update!(credits: current_user.credits - @transaction.amount)
        @transaction.receiver.update!(credits: @transaction.receiver.credits + @transaction.amount)
        @transaction.save!
        
        current_user.broadcast_credits_update
        receiver.broadcast_credits_update
      end
  
      if current_user.group.name == "MJ"
        redirect_to new_transaction_path, notice: 'Transfert réussi'
      else
        redirect_to new_transaction_path, notice: 'Transfert réussi'
      end
    else
      redirect_to new_transaction_path, alert: 'Transfert échoué, crédits insuffisants'
    end
  rescue => e
    redirect_to new_transaction_path, alert: 'Une erreur s\'est produite'
  end

  private

  def transaction_params
    params.require(:transaction).permit(:amount, :receiver_username)
  end
end
