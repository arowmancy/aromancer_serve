class Player < ApplicationRecord
  has_many :player_legends
  has_many :legends, through: :player_legends
  has_many :legend_wins, class_name: :Legend, foreign_key: :winner_id
  has_many :story_wins, class_name: :Story, foreign_key: :winner_id

  enum :status, [
    :gone,
    :lobby,
    :ready,
    :playing,
  ]
end
