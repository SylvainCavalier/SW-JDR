class ApprenticesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_force_user_class, except: [:show]
  before_action :set_apprentice, only: %i[show edit update destroy abandon train]

  def index
    @apprentice = current_user.apprentice
    @force_sensitive_pets = Pet.force_sensitive_humanoids.where(apprentice: nil)

    if @apprentice.present?
      @grouped_skills = @apprentice.grouped_skills
      @apprentice_caracs = @apprentice.apprentice_caracs.includes(:carac).index_by { |ac| ac.carac.name }
    end
  end

  def show
    @grouped_skills = @apprentice.grouped_skills
  end

  def new
    @pet = Pet.find(params[:pet_id])

    unless @pet.category == "humanoïde" && @pet.force?
      redirect_to pet_path(@pet), alert: "Ce familier ne peut pas devenir apprenti."
      return
    end

    if current_user.apprentice.present?
      redirect_to pet_path(@pet), alert: "Vous avez déjà un apprenti. Abandonnez-le d'abord."
      return
    end

    if @pet.apprentice.present?
      redirect_to pet_path(@pet), alert: "Ce familier est déjà l'apprenti de quelqu'un."
      return
    end

    @apprentice = Apprentice.new(pet: @pet, jedi_name: @pet.name)
    @caracs = Carac.all
  end

  def create
    @pet = Pet.find(params[:pet_id])

    unless @pet.category == "humanoïde" && @pet.force?
      redirect_to pet_path(@pet), alert: "Ce familier ne peut pas devenir apprenti."
      return
    end

    if current_user.apprentice.present?
      redirect_to pet_path(@pet), alert: "Vous avez déjà un apprenti."
      return
    end

    if @pet.apprentice.present?
      redirect_to pet_path(@pet), alert: "Ce familier est déjà l'apprenti de quelqu'un."
      return
    end

    @apprentice = Apprentice.new(apprentice_params)
    @apprentice.pet = @pet
    @apprentice.user = current_user
    @apprentice.side = 0
    @apprentice.speciality = "Commun"
    @apprentice.midi_chlorians = rand(5000..20000)
    @apprentice.dark_side_points = 0

    ActiveRecord::Base.transaction do
      if @apprentice.save
        # Initialiser les caractéristiques avec les valeurs du formulaire
        carac_values = {}
        if params[:caracs].present?
          params[:caracs].each do |carac_id, value|
            carac = Carac.find_by(id: carac_id)
            carac_values[carac.name] = value.to_i if carac
          end
        end

        @apprentice.initialize_caracs(carac_values)
        @apprentice.initialize_skills

        redirect_to apprentices_path, notice: "#{@apprentice.jedi_name} est désormais votre apprenti !"
      else
        @caracs = Carac.all
        render :new, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    @caracs = Carac.all
    flash.now[:alert] = "Erreur lors de la création de l'apprenti : #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def edit
    @caracs = Carac.all
  end

  def update
    ActiveRecord::Base.transaction do
      if @apprentice.update(apprentice_update_params)
        # Mettre à jour les caractéristiques
        if params[:caracs].present?
          params[:caracs].each do |carac_id, value|
            apprentice_carac = @apprentice.apprentice_caracs.find_by(carac_id: carac_id)
            apprentice_carac&.update!(mastery: value.to_i)
          end
        end

        # Mettre à jour les compétences
        if params[:skills].present?
          params[:skills].each do |skill_id, values|
            apprentice_skill = @apprentice.apprentice_skills.find_by(skill_id: skill_id)
            if apprentice_skill
              apprentice_skill.update!(
                mastery: values[:mastery].to_i,
                bonus: values[:bonus].to_i
              )
            end
          end
        end

        redirect_to apprentices_path, notice: "Apprenti mis à jour avec succès."
      else
        @caracs = Carac.all
        render :edit, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    @caracs = Carac.all
    flash.now[:alert] = "Erreur lors de la mise à jour : #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  def abandon
    if @apprentice.user == current_user
      @apprentice.destroy
      redirect_to apprentices_path, notice: "Vous avez abandonné l'apprentissage de #{@apprentice.jedi_name}."
    else
      redirect_to apprentices_path, alert: "Vous ne pouvez pas abandonner cet apprenti."
    end
  end

  def destroy
    if @apprentice.user == current_user || current_user.group.name == "MJ"
      name = @apprentice.jedi_name
      @apprentice.destroy
      redirect_to apprentices_path, notice: "#{name} n'est plus un apprenti."
    else
      redirect_to apprentices_path, alert: "Vous ne pouvez pas supprimer cet apprenti."
    end
  end

  def train
    unless @apprentice.user == current_user
      redirect_to apprentices_path, alert: "Vous ne pouvez pas entraîner cet apprenti."
      return
    end

    skill_id = params[:skill_id]
    result = @apprentice.train_skill(skill_id)

    if result[:success]
      if result[:training_success]
        flash[:notice] = "✅ #{result[:message]} (Jet: #{result[:roll]}/#{result[:success_rate]}%, Fatigue: -#{result[:fatigue_cost]})"
      else
        flash[:alert] = "❌ #{result[:message]} (Jet: #{result[:roll]}/#{result[:success_rate]}%, Fatigue: -#{result[:fatigue_cost]})"
      end
    else
      flash[:alert] = result[:message]
    end

    redirect_to apprentices_path
  end

  private

  def set_apprentice
    @apprentice = Apprentice.find(params[:id])
  end

  # Classes autorisées à avoir un apprenti
  FORCE_USER_CLASSES = %w[Jedi Sénateur].freeze

  def ensure_force_user_class
    unless FORCE_USER_CLASSES.include?(current_user.classe_perso&.name) || current_user.group.name == "MJ"
      redirect_to root_path, alert: "Seuls les Jedi et Sénateurs sensibles à la Force peuvent accéder à cette fonctionnalité."
    end
  end

  def apprentice_params
    params.require(:apprentice).permit(:jedi_name, :saber_style)
  end

  def apprentice_update_params
    params.require(:apprentice).permit(:jedi_name, :speciality, :saber_style, :side, :dark_side_points)
  end
end
