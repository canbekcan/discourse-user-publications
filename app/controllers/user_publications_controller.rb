# frozen_string_literal: true

class UserPublicationsController < ::ApplicationController
  requires_login

  def trigger_sync
    user = User.find_by(username: params[:username])
    raise Discourse::NotFound unless user
    
    guardian.ensure_can_edit!(user)
    RateLimiter.new(current_user, "orcid_sync_#{user.id}", 1, 1.minute).performed!

    Jobs.enqueue(:sync_orcid_publications, user_id: user.id)
    render json: success_json
  end

  def create
    guardian.ensure_can_edit!(current_user)
    pub = current_user.user_publications.build(publication_params)
    
    if pub.save
      render json: pub
    else
      render json: failed_json.merge(errors: pub.errors.full_messages), status: 422
    end
  end

  private

  def publication_params
    params.require(:publication).permit(:title, :publication_type, :url)
  end
end