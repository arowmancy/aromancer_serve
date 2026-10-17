module Uuid
  extend ActiveSupport::Concern

  included do
    before_create :generate_uuid
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid_v4
  end
end