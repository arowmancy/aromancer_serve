class Writable < ApplicationRecord
  include Uuid

  belongs_to :word
  belongs_to :player_legend
  has_many :writable_options, dependent: :destroy

  def write!
    # todo: validations
    # todo: handle success/failure
    player_legend.player.submit_turn(word)
  end
end
