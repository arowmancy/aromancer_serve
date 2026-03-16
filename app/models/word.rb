# a tarot card
class Word < ApplicationRecord
  # "top" of face-down deck is lowest order_index
  default_scope { order(order_index: :asc) }

  belongs_to :dictionary

  enum :style, [
    :number,
    :page,
    :knight,
    :queen,
    :king,
  ]

  enum :suit, [
    :trumps,
    :cups,
    :swords,
    :pentacles,
    :wands,
  ]

  def json_card
    suit_display = self.suit.split("")[0].upcase
    {
      id: id,
      value_display: suit_display,
      suit_display: number? ? value : style,
      value: value,
      suit: suit,
      style: style
    }
  end

  def to_s
    "the #{number? ? value : style} of #{suit}."
  end

end
