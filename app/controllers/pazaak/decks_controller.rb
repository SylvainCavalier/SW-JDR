module Pazaak
  class DecksController < ApplicationController
    before_action :authenticate_user!

    def show
      @owned_cards = current_user.user_inventory_objects
                                  .joins(:inventory_object)
                                  .where('user_inventory_objects.quantity > 0')
                                  .where(inventory_objects: { category: 'pazaak' })
                                  .includes(:inventory_object)
      @selected = Array(current_user.pazaak_deck).map(&:to_s)
    end

    def update
      selected = Array(params[:deck]).map(&:to_s).first(10)
      current_user.update!(pazaak_deck: selected)
      redirect_to pazaak_deck_path, notice: 'Deck sauvegardé.'
    end
  end
end


