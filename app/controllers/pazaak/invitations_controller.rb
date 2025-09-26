module Pazaak
  class InvitationsController < ApplicationController
    before_action :authenticate_user!

    def create
      invitee = User.find(params[:invitee_id])
      stake = params[:stake].to_i.clamp(0, 1_000_000)
    if current_user.credits.to_i < stake
      redirect_to pazaak_lobbies_path, alert: "Crédits insuffisants pour cette mise." and return
    end
    invitation = PazaakInvitation.create!(inviter: current_user, invitee: invitee, stake: stake)
      respond_to do |format|
        format.turbo_stream do
          Turbo::StreamsChannel.broadcast_replace_to(
            "user_#{invitee.id}",
            target: "pazaak_redirect",
            partial: "pazaak/invitations/invite_modal",
            locals: { invitation: invitation, inviter: current_user }
          )
        end
        format.html { redirect_to pazaak_lobbies_path, notice: "Invitation envoyée." }
      end
    end

    def update
      invitation = PazaakInvitation.find(params[:id])
      authorize_invitation!(invitation)

      case params[:decision]
      when "accept"
      # Vérifier les crédits des deux joueurs
      if invitation.invitee.credits.to_i < invitation.stake.to_i
        redirect_to pazaak_lobbies_path, alert: "Vous n'avez pas assez de crédits pour cette mise." and return
      end
      if invitation.inviter.credits.to_i < invitation.stake.to_i
        redirect_to pazaak_lobbies_path, alert: "L'invitant n'a plus assez de crédits pour cette mise." and return
      end
        invitation.update!(status: :accepted)
        # Réutilise une partie en cours entre ces deux joueurs si elle existe déjà
        game = PazaakGame.where(status: PazaakGame.statuses[:in_progress])
                          .where("(host_id = :a AND guest_id = :b) OR (host_id = :b AND guest_id = :a)", a: invitation.inviter_id, b: invitation.invitee_id)
                          .order(created_at: :desc).first
        unless game
          game = PazaakGame.create!(host: invitation.inviter, guest: invitation.invitee, status: :waiting)
          game.start_game!
        end
        invitation.update!(pazaak_game: game)
        # Redirige l'invité par HTTP et notifie l'invitant via Turbo Stream
        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{invitation.inviter_id}",
          target: "pazaak_redirect",
          partial: "pazaak/redirect",
          locals: { url: pazaak_game_path(game) }
        )
        redirect_to pazaak_game_path(game)
      when "decline"
        invitation.update!(status: :declined)
        redirect_to pazaak_lobbies_path, alert: "Invitation refusée."
      else
        redirect_to pazaak_lobbies_path, alert: "Action inconnue."
      end
    end

    private

    def authorize_invitation!(invitation)
      unless invitation.invitee_id == current_user.id
        redirect_to pazaak_lobbies_path, alert: "Non autorisé." and return
      end
    end
  end
end


