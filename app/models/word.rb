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
    {
      id: id,
      display: to_string,
      value: value,
      suit: suit,
      style: style
    }
  end

  def to_string
    "#{self.suit.split("")[0].upcase}#{number? ? value : style}"
  end

end
