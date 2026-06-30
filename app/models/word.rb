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
      value_display: number? ? value : style[0..2].upcase,
      suit_display: suit.upcase,
      value: value,
      suit: suit,
      style: style
    }
  end

  def to_s
    "the #{number? ? value : style} of #{suit}."
  end

  def weight
    # 1 => total cards
    # 1 => total trumps
    # 1 => total face cards
    # 1 => total swords (masculine)
    # 1 => total wands (masculine)
    # 1 => ten of cups (feminine)
    # 1 => ten of pentacles (feminine)
    # 4 => aces (1 point each)
    w = (1.0 / 78.0) if true == true
    w += (1.0 / 22.0) if trumps?
    w += (1.0 / 16.0) unless number? || trumps?
    w +=  1.0 if (cups? || pentacles?) && self.value == 10
    w += (1.0 / 14.0) if (swords? || wands?)
    w +=  1.0 if self.value == 1 && number? && !trumps?
    w
  end

end
