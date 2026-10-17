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
      return nil unless request.headers[:authorization.to_s.capitalize].present?
      @api_player = Player.find_by(
        api_key: request.headers[:authorization.to_s.capitalize].gsub(:bearer.to_s.capitalize, "").strip
      )
      Thread.current[:player] = @api_player
      @api_player
    end

    def request_authentication
      respond_with_error(:unauthorized, "not signed in") # TODO: localization eg: I18n.t("errors.not_signed_in")
      return
    end

    def start_new_session_for(user)
      @api_player = user.player
      @api_player.set_api_key
      @api_player.save
      @api_player.reload
      Thread.current[:player] = @api_player
    end

    def terminate_session
      if authenticated?
        @api_player.update(api_key: nil)
        Thread.current[:player] = nil
      end
    end
end
