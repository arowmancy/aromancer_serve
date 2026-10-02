class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  # rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))
    if user.present?
      start_new_session_for(user)
      render json: @api_player, status: :created
    else
      # {code: 404, name: :not_found}
      respond_with_error :not_found, I18n.t("errors.invalid")
    end
  end

  def destroy
    terminate_session
    render json: {}, status: :ok
  end
end
