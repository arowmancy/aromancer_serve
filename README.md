# ino_legacy_server

client: `gdevelop`
server: `rails (api-only, https, wss)`


scoring (1 story):

-  points => description
-  1 => total cards
-  1 => total trumps
-  1 => total face cards
-  1 => total swords (masculine)
-  1 => total wands (masculine)
-  1 => 10 of cups (feminine)
-  1 => 10 of pentacles (feminine)
-  4 => aces (1 point each)
-  11 => total


###todos:
- basic email/password login/verification
  - [tutorial](https://sdrmike.medium.com/rails-7-api-only-app-with-devise-and-jwt-for-authentication-1397211fb97c)
- websockets
- prepare for android play accounts
  - [sign in with google](https://github.com/basecamp/google_sign_in?tab=readme-ov-file)


### jwt ApplicationCable example
```
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      header_array = request.headers[:HTTP_SEC_WEBSOCKET_PROTOCOL]&.split(',')
      token = header_array&.last&.strip

      decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256')
      user_id = decoded_token.first['sub']
      User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      reject_unauthorized_connection
    end
  end
end
```