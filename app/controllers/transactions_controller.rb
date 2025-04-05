class TransactionsController < ApplicationController
  before_action :authenticate_user!

  def new
    @transaction = Transaction.new
    @transfer_users = User.where.not(id: current_user.id)
                          .includes(avatar_attachment: :blob)
                          .order(:username)
  end

  def create
    if params[:transaction][:receiver_username].downcase == "headquarter"
      receiver = Headquarter.first
    else
      receiver = User.where('LOWER(username) = ?', params[:transaction][:receiver_username].downcase).first
    end
  
    if receiver.nil?
      flash.now[:alert] = 'Destinataire introuvable'
      render :new, status: :unprocessable_entity and return
    end
  
    if receiver == current_user
      flash.now[:alert] = 'Vous ne pouvez pas vous envoyer des crédits à vous-même.'
      render :new, status: :unprocessable_entity and return
    end
  
    @transaction = Transaction.new(transaction_params)
    @transaction.sender = current_user
  
    if receiver.is_a?(Headquarter)
      # Transfert vers la base
      if @transaction.amount <= current_user.credits && @transaction.amount > 0
        ActiveRecord::Base.transaction do
          current_user.update!(credits: current_user.credits - @transaction.amount)
          receiver.update!(credits: receiver.credits + @transaction.amount)
        end
  
        current_user.broadcast_credits_update
        flash[:notice] = 'Transfert réussi vers la base.'
        redirect_to new_transaction_path
      else
        flash.now[:alert] = 'Transfert échoué, crédits insuffisants.'
        render :new, status: :unprocessable_entity
      end
    else
      # Transfert entre joueurs (inchangé)
      @transaction.receiver = receiver
  
      if @transaction.amount <= current_user.credits && @transaction.amount > 0
        ActiveRecord::Base.transaction do
          current_user.update!(credits: current_user.credits - @transaction.amount)
          receiver.update!(credits: receiver.credits + @transaction.amount)
          @transaction.save!
  
          current_user.broadcast_credits_update
          receiver.broadcast_credits_update
        end
  
        flash[:notice] = 'Transfert réussi.'
        redirect_to new_transaction_path
      else
        flash.now[:alert] = 'Transfert échoué, crédits insuffisants.'
        render :new, status: :unprocessable_entity
      end
    end
  rescue => e
    flash.now[:alert] = "Une erreur s'est produite : #{e.message}"
    render :new, status: :internal_server_error
  end

  private

  def transaction_params
    params.require(:transaction).permit(:amount, :receiver_username)
  end
end
