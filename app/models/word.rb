# a tarot card
class Word < ApplicationRecord
  # "top" of face-down deck is lowest order_index
  default_scope { order(order_index: :asc) }
  has_many :entries
  has_many :player_words
  has_many :players, through: :player_words
  has_many :sentence_words
  has_many :sentences, through: :sentence_words

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

  def json_card
    suit_display = self.suit.split("")[0].upcase
    {
      id: id,
      value_display: "#{suit_display}(#{number? ? "#{value}" : style[0..3].upcase})",
      suit_display: suit.upcase,
      value: value,
      suit: suit,
      style: style
    }
  end

  def possibilities(player)
    return [] unless player.present?
    #
    # returns list of possible actions for self scoped to player
    #
    # list of possible self contextual reference points:
    #   :player word
    #   :scroll word
    #   :sentence word
    #
    #
    # TODO: use permutations:
    #   example:
    #   result = [1, 2, 3, 4].permutation(2).select { |p| p.sum == 5 }
    #   p result # => [[1, 4], [2, 3], [3, 2], [4, 1]]

    can_sign = []
    can_combine = []
    can_stack = []

    c = dictionary.story.current_chapter

    player_words = dictionary.words.where(id: c.player_words.where(player: player).pluck(:word_id))
    numeric_player_words = player_words.where.not(id: self.id).where(style: :number)
    words_on_scroll = c.scroll_words.where.not(word: self).map{|sw| sw.word}

    for_type = :player_word if player_words.pluck(:id).include?(self.id)
    for_type = :scroll_word if c.scroll_words.pluck(:word_id).include?(self.id)
    for_type = :scroll_sentence if SentenceWord.where(sentence_id: c.unsigned_sentences.pluck(:id)).pluck(:word_id).include?(self.id)

    case for_type
    when :player_word
      #
      #   all scroll words and sentences that equal self.value
      #
      #     can_sign =
      #       self.value == scroll_word.value || self.value == scroll_sentence.value
      #
      #
      can_sign += words_on_scroll.select{|w| (number? && self.value == w.value) || !number? && self.style == w.style}
      can_sign += c.unsigned_sentences.select{|us| number? && self.value == us.value}

      if number?
        #   all scroll words and sentences that sum to value of any other player word.
        #
        #     can_combine =
        #       self.value + scroll_word.value == any_player_word.value ||
        #       self.value + sentence.value == any_player_word.value
        #
        #
        #   note: only do this if self's style is number. no combining face cards right now
        #
        #

        can_combine += words_on_scroll.select{|w|
          w.number? && player_words.where.not(id: self.id).where(style: :number).any?{|pw|
            pw.value == self.value + w.value
          }
        }

        can_combine += c.unsigned_sentences.select{|us|
          player_words.any?{|pw|
            pw.number? && number? && pw.value == self.value + us.value
          }
        }

        #
        #   all scroll/player words and sentences that can form a stack
        #
        #     can_stack = self.value == scroll_word.value && any_other_player_card.value == self.value ||
        #       self.value == sentence.value && any_other_player_card.value == self.value ||
        #
        #
        #
        can_stack += words_on_scroll.select{|w|
          w.number? && (
            self.value == w.value && numeric_player_words.select{|pw|
              pw.value == w.value
            }.length >= 1
          )
        }
        can_stack += c.unsigned_sentences.select{|us|
          self.value == us.value && numeric_player_words.select{|pw|
            pw.value == us.value
          }.length >= 1
        }
      end

    when :scroll_word
      #
      #   all player words that equal self.value
      #
      #     can_sign =
      #       self.value == player_word.value
      #
      #
      can_sign += player_words.select{|w| (number? && self.value == w.value) || !number? && self.style == w.style}

      #
      #   all player/scroll words and sentences that sum to == value of other player word.
      #
      #     can_combine =
      #       self.value + player_word.value == any_player_word.value ||
      #       self.value + scroll_word.value == any_player_word.value ||
      #       self.value + scroll_word.value + any_player_word.value == any_other_player_word.value ||
      #       self.value + unsigned_sentences.value == any_player_word.value ||
      #       self.value + unsigned_sentences.value + any_player_word.value == any_other_player_word.value
      #
      #
      if number?
        can_combine += player_words.select{|w|
          w.number? && numeric_player_words.any?{|pw|
            pw.value == self.value + w.value
          }
        }
        can_combine += words_on_scroll.select{|w|
          w.number? && numeric_player_words.any?{|pw|
            sum = [pw.value, self.value, w.value].sum
            pw.value == self.value + w.value ||
            numeric_player_words.any?{|ppw| ppw.value == sum}
          }
        }
        can_combine += c.unsigned_sentences.select{|us|
          numeric_player_words.any?{|pw|
            sum = [pw.value, self.value, us.value].sum
            pw.value == self.value + us.value ||
            numeric_player_words.any?{|ppw| ppw.value == sum}
          }
        }

        #
        #   all scroll/player words and sentences that can form a stack
        #
        #     can_stack = #todo self.value == scroll_word.value && any_other_player_card.value == self.value ||
        #       self.value == #todo sentence.value && any_other_player_card.value == self.value ||
        #
        #
        #
        # todo:

      end
    when :scroll_sentence
      self_sentence = c.unsigned_sentences.where(id: sentence_words.pluck(:sentence_id)).first
      #
      #   all player words that equal self.sentence.value
      #
      #     can_sign =
      #       self.sentence.value == player_word.value
      #
      can_sign += player_words.select{|w| (number? && self_sentence.value == w.value) || !number? && self.style == w.style}

      #   all player/scroll words and sentences that sum to == value of other player word.
      #
      #     can_combine =
      #       self.sentence.value + player_word.value == any_player_word.value ||
      #       self.sentence.value + scroll_word.value == any_player_word.value ||
      #       self.sentence.value + unsigned_sentences.value == any_player_word.value
      #
      #
      can_combine += player_words.select{|w|
        w.number? && numeric_player_words.any?{|pw|
          pw.value == self_sentence.value + w.value
        }
      }
      can_combine += words_on_scroll.select{|w|
        w.number? && numeric_player_words.any?{|pw|
          pw.value == self_sentence.value + w.value
        }
      }
      can_combine += c.unsigned_sentences.select{|us|
        numeric_player_words.any?{|pw|
          sum = [pw.value, self.value, us.value].sum
          pw.value == self_sentence.value + us.value ||
          numeric_player_words.any?{|ppw| ppw.value == sum}
        }
      }

      #
      #   all scroll/player words and sentences that can form a stack
      #
      #     can_stack = #todo self.value == scroll_word.value && any_other_player_card.value == self.value ||
      #       self.value == #todo sentence.value && any_other_player_card.value == self.value ||
      #
      #
      #
      # todo:

    end

    mapper = Proc.new{|action, o|
      s = nil
      if o.kind_of?(Sentence)
        s = o
      end
      w = o if s.nil?

      {
        action: action,
        word: w&.json_card,
        sentence: s&.json_sentence
      }
    }

    result = []
    result += can_sign.map{|o| mapper.call(:can_sign, o)}
    result += can_combine.map{|o| mapper.call(:can_combine, o)}
    result += can_stack.map{|o| mapper.call(:can_stack, o)}

    {
      word: self.json_card,
      for_type: for_type,
      options: result
    }
  end

end
