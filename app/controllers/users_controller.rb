class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]

  def create
    user = User.create(user_params)
    if user.valid?
      render json: user.player, status: :created
    else
      respond_with_error :bad_request, user.errors
    end
  end

  private

  def user_params
    params.require(:user).permit([:email_address, :password, :password_confirmation])
  end
end
