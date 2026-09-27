module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      @api_player.present?
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      @api_player ||= Player.find_by(api_key: params[:api_key])
    end

    def request_authentication
      respond_with_error(:unauthorized, "not signed in") # TODO: I18n.t("errors.not_signed_in")
    end

    def start_new_session_for(user)
      @api_player = user.player
      @api_player.set_api_key
      @api_player.save
    end

    def terminate_session
      if authenticated?
        @api_player.update(api_key: nil)
      end
    end
end
