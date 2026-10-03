# a tarot card
class Word < ApplicationRecord
  # "top" of face-down deck is lowest order_index
  default_scope { order(order_index: :asc) }
  has_many :entries
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
  def player
    @player
  end

  def story
    dictionary.story
  end

  def chapter
    story.current_chapter
  end

  def player_words
    return [] unless player.present? && chapter.present?
    dictionary.words.where(id: chapter.player_words.where(player: player).pluck(:word_id))
  end

  def numeric_player_words
    player_words.where(style: :number).where.not(id: self.id)
  end

  def scroll_words
    return [] unless chapter.present?
    dictionary.words.where(id: chapter.scroll_words.pluck(:word_id))
  end

  def scroll_sentences
    return [] unless chapter.present?
    chapter.unsigned_sentences
  end

  def self_sentence
    return nil unless chapter.present?
    chapter.sentences.where(id: SentenceWord.where(word_id: self.id).pluck(:sentence_id)).first
  end

  # if self is used in a sentence,
  # return self_sentence.value else return self.value
  def absolute_value
    return self_sentence.value unless self_sentence.nil?

    self.value
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

  def json_card
    suit_display = self.suit.split("")[0].upcase
    {
      id: id,
      value_display: "#{suit_display}(#{number? ? "#{value}" : style[0..3].upcase})",
      suit_display: suit.upcase,
      value: value,
      suit: suit,
      style: style,
      humanized: to_s
    }
  end

  def possibility_for_type
    return @for_type unless @for_type.nil?

    # self is a player word
    for_type = :player_word if player_words.include?(self)
    # self is a scroll word
    for_type = :scroll_word if scroll_words.include?(self) if !for_type
    # self is a scroll sentence
    for_type = :scroll_sentence if SentenceWord.where(sentence_id: scroll_sentences.pluck(:id)).pluck(:word_id).include?(self.id) if !for_type

    @for_type = for_type
    @for_type
  end

  def signature_matcher(words)
    words.select{|w|
      (number? && self.absolute_value == w.value) ||
      !number? && self.style == w.style
    }
  end

  def can_sign_options
    case possibility_for_type
    when :player_word
      #
      # => get all scroll words and sentences that equal self.value
      #
      #     can_sign =
      #       self.value == scroll_word.value || self.value == scroll_sentence.value
      #
      return signature_matcher(scroll_words) +
        scroll_sentences.select{|ss| number? && self.absolute_value == ss.value}
    when :scroll_word, :scroll_sentence
      # when :scroll_word
      #
      # => get all player words that equal self.value
      #
      #     can_sign =
      #       self.value == player_word.value
      #
      #

      # when :scroll_sentence
      #
      # => all player words that equal self.sentence.value
      #
      #     can_sign =
      #       self.sentence.value == player_word.value
      #

      return signature_matcher(player_words)
    end
  end

  def can_combine_options
    return [] unless number?

    case possibility_for_type
    when :player_word
      #
      # => all scroll words and sentences that sum to value of any other player word.
      #
      #     can_combine =
      #       self.value + scroll_word.value == any_player_word.value ||
      #       self.value + sentence.value == any_player_word.value
      #
      #
      #   note: only do this if self's style is number. no combining face cards right now
      #
      #
      return scroll_words.select{|w|
        w.number? && player_words.where.not(id: self.id).where(style: :number).any?{|pw|
          pw.value == self.absolute_value + w.value
        }
      } + scroll_sentences.select{|ss|
        player_words.any?{|pw|
          pw.number? && pw.value == self.absolute_value + ss.value
        }
      }
    when :scroll_word
      #
      # => all player/scroll words and sentences that sum to == value of other player word.
      #
      #     can_combine =
      #       self.value + player_word.value == any_player_word.value ||
      #       self.value + scroll_word.value == any_player_word.value ||
      #       self.value + unsigned_sentences.value == any_player_word.value ||
      #
      #
      return player_words.select{|w|
        w.number? && numeric_player_words.any?{|pw|
          pw.value == self.absolute_value + w.value
        }
      } + scroll_words.select{|w|
        w.number? && numeric_player_words.any?{|pw|
          pw.value == self.absolute_value + w.value
        }
      } + scroll_sentences.select{|ss|
        numeric_player_words.any?{|pw|
          pw.value == self.absolute_value + ss.value
        }
      }
    when :scroll_sentence
      # => all player/scroll words and sentences that sum to == value of other player word.
      #
      #     can_combine =
      #       self.sentence.value + player_word.value == any_player_word.value ||
      #       self.sentence.value + scroll_word.value == any_player_word.value ||
      #       self.sentence.value + unsigned_sentences.value == any_player_word.value
      #
      #
      return player_words.select{|w|
        w.number? && numeric_player_words.any?{|pw|
          pw.value == self_sentence.value + w.value
        }
      } + scroll_words.select{|w|
        w.number? && numeric_player_words.any?{|pw|
          pw.value == self_sentence.value + w.value
        }
      } + scroll_sentences.select{|ss|
        numeric_player_words.any?{|pw|
          pw.value == self_sentence.value + ss.value
        }
      }
    end
  end

  def can_stack_options
    return [] unless number?

    case possibility_for_type
    when :player_word
      #
      # => all scroll/player words and sentences that can form a stack
      #
      #     can_stack = self.value == scroll_word.value && any_other_player_card.value == self.value ||
      #       self.value == sentence.value && any_other_player_card.value == self.value
      #
      return scroll_words.select{|w|
        w.number? && (
          self.absolute_value == w.value && numeric_player_words.select{|pw|
            pw.value == w.value
          }.any?
        )
      } + scroll_sentences.select{|ss|
        self.absolute_value == ss.value && numeric_player_words.select{|pw|
          pw.value == ss.value
        }.any?
      }
    when :scroll_word
      #
      # => all scroll/player words and sentences that can form a stack
      #
      #     can_stack = self.value == player_word.value && any_other_player_card.value == self.value ||
      #       self.value == scroll_word.value && any_other_player_card.value == self.value ||
      #       self.value == sentence.value && any_other_player_card.value == self.value
      #
      #
      return player_words.select{|w|
        w.number? && (
          self.absolute_value == w.value && numeric_player_words.select{|pw|
            pw.value == w.value
          }.any?
        )
      } + scroll_words.select{|w|
        w != self && w.number? && (
          self.absolute_value == w.value && numeric_player_words.select{|pw|
            pw.value == w.value
          }.any?
        )
      } + scroll_sentences.select{|ss|
        self.absolute_value == ss.value && numeric_player_words.select{|pw|
          pw.value == ss.value
        }.any?
      }
    when :scroll_sentence
      #
      #   all scroll/player words and sentences that can form a stack
      #
      #     can_stack = #todo self.value == scroll_word.value && any_other_player_card.value == self.value ||
      #       self.value == #todo sentence.value && any_other_player_card.value == self.value ||
      #
      #
      #
      # todo:

      return []
    end
  end

  def possibilities(player)
    return [] unless player.present?
    @player = player

    mapper = Proc.new{|action, o|
      s = nil
      http_verb = :post
      payload = {}
      if o.kind_of?(Sentence)
        s = o
      end
      w = o if s.nil?
      case action
      when :can_sign
        if s.nil?
          if self_sentence.nil?
            # create new sentence & sign with self
            payload = {
              word_id: self.id,
              sentence: {
                signature_id: self.id,
                word_ids: [w.id]
              }
            }
          else
            # sign self_sentence with w
            payload = {
              sentence_id: self_sentence.id,
              sentence: {
                signature_id: w.id
              }
            }
          end
        else
          payload = {
            sentence_id: s.id,
            sentence: {
              signature_id: self.id
            }
          }
        end
      when :can_combine
        if s.nil?
          if self_sentence.nil?
            # combine self with w
            payload = {
              word_id: self.id,
              sentence: {
                word_ids: [self.id, w.id]
              }
            }
          else
            # add w to self_sentence
            payload = {
              sentence_id: self_sentence.id,
              sentence: {
                word_ids: self_sentence.words.pluck(:id) + [w.id]
              }
            }
          end
        else
          if self_sentence.nil?
            # add self to s
            payload = {
              sentence_id: s.id,
              sentence: {
                word_ids: s.words.pluck(:id) + [self.id]
              }
            }
          else
            # merge self_sentence & s
            http_verb = :put
            payload = {
              sentence_ids: [self_sentence.id, s.id],
              value: self_sentence.value
            }
          end
        end
      when :can_stack

        if s.nil?
          if self_sentence.nil?
            # combine self with w
            payload = {
              word_id: self.id,
              sentence: {
                word_ids: [self.id, w.id],
                is_stack: true
              }
            }
          else
            # add w to self_sentence
            payload = {
              sentence_id: self_sentence.id,
              sentence: {
                word_ids: self_sentence.words.pluck(:id) + [w.id],
                is_stack: true
              }
            }
          end
        else
          if self_sentence.nil?
            # add self to s
            payload = {
              sentence_id: s.id,
              sentence: {
                word_ids: s.words.pluck(:id) + [self.id],
                is_stack: true
              }
            }
          else
            # merge self_sentence & s
            http_verb = :put
            payload = {
              sentence_ids: [self_sentence.id, s.id],
              value: self_sentence.value,
              is_stack: true
            }
          end
        end
      end

      {
        action: action,
        word: w&.json_card,
        sentence: s&.json_sentence,
        payload: payload.to_json,
        http_verb: http_verb
      }
    }

    result = []
    result += (can_sign_options || []).map{|o| mapper.call(:can_sign, o)}
    result += (can_combine_options || []).map{|o| mapper.call(:can_combine, o)}
    result += (can_stack_options || []).map{|o| mapper.call(:can_stack, o)}

    {
      word: self.json_card,
      for_type: possibility_for_type,
      options: result
    }
  end

end
