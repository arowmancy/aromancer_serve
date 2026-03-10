class PlayerWord < ApplicationRecord
  belongs_to :player
  belongs_to :word
end
