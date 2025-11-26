class GoodsCratesController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_smuggler

  def index
    @goods_crates = current_user.goods_crates.order(created_at: :desc)
    @goods_crate = GoodsCrate.new
  end

  def create
    @goods_crate = current_user.goods_crates.build(goods_crate_params)

    if @goods_crate.save
      redirect_to goods_crates_path, notice: "Caisse de marchandises ajoutée avec succès."
    else
      @goods_crates = current_user.goods_crates.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @goods_crate = current_user.goods_crates.find(params[:id])
    @goods_crate.destroy
    redirect_to goods_crates_path, notice: "Caisse de marchandises supprimée avec succès."
  end

  private

  def goods_crate_params
    params.require(:goods_crate).permit(:content, :quantity, :origin_planet, :price_per_crate)
  end

  def verify_smuggler
    unless current_user.classe_perso&.name == "Contrebandier"
      redirect_to root_path, alert: "Accès réservé aux Contrebandiers."
    end
  end
end

