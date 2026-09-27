class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :player

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  after_create :create_player

  private

  def create_player
    return unless player.nil?

    self.player = Player.create(alias: self.email_address.split("@")[0], user: self)
  end
end
