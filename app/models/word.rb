class Word < ApplicationRecord
  # "top" of face-down deck is lowest order_index
  default_scope { order(order_index: :asc) }
  has_many :entries
  has_many :sentence_words
  has_many :sentences, through: :sentence_words
  has_many :writables

  has_one :mathematica_sentence, class_name: Sentence.to_s, foreign_key: :mathematica_id
  has_one :mathematica_player_legend, class_name: PlayerLegend.to_s, foreign_key: :mathematica_id

  belongs_to :dictionary

  UNICODE = {
    OPERATORS: {
      plus: "\u002b",
      minus: "\u002d",
      times: "\u00d7",
      over: "\u00f7"
    },
    integral: "\u222b",
    equals: "\u003d"
  }

  enum :style, [
    :number,
    :page,
    :knight,
    :queen,
    :king,
    :"_\u002b_".to_sym,
    :"_\u002d_".to_sym,
    :"_\u00d7_".to_sym,
    :"_\u00f7_".to_sym
  ]

  enum :suit, [
    :trumps,
    :cups,
    :swords,
    :pentacles,
    :wands,
    :mathematica
  ]

  def weight
    # aromancer rules:

    # => each story has a total possible of 11 points.
    # => addition is the default language.
    # => mathematica words change the player's language for their next sentence.

    # !todo: not fully implemented in code yet!
    #
    #
    # => if player has >= 1 authored, unsigned sentence(s) on the scroll,
    # => they can only:
    #   => place word on the scroll
    #   => sign anything else
    #   => create/stack sentences that equal value of authored, unsigned sentence(s)
    #   => modify authored, unsigned sentence to equal value of any other player word
    #
    #
    # !todo: not fully implemented in code yet!

    # scoring:

    # 1 => most words
    # 1 => most trumps
    # 1 => most face words
    # 1 => most swords (masculine)
    # 1 => most wands (masculine)
    # 1 => ten of cups (feminine)
    # 1 => ten of pentacles (feminine)
    # 4 => aces (1 each)

    # the following code is where the score is calculated:

    # mathematica words get zero weight
    return 0 if mathematica?
    # self is a non-mathematica word
    wt = (1.0 / 78.0) if true == true
    # self is a trumps word
    wt += (1.0 / 22.0) if self.trumps?
    # self is a face word
    wt += (1.0 / 16.0) unless self.number? || self.trumps?
    # self is a 10 of cups or pentacles
    wt +=  1.0 if (self.cups? || self.pentacles?) && self.value == 10
    # self is a swords or wands
    wt += (1.0 / 14.0) if (self.swords? || self.wands?)
    # self is an ace
    wt +=  1.0 if self.value == 1 && self.number? && !self.trumps?

    # return total weight
    wt
  end

  def player_word?
    player_words.include?(self)
  end

  def player
    Thread.current[:player]
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

    return mathematica_sentence if mathematica? # this returns optional language override if self is mathematica

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

  def value_display
    return "#{Word::UNICODE[:integral]}(#{style.to_s.gsub("_", "")})" if mathematica?
    "#{self.suit.split("")[0].upcase}(#{number? ? value : style[0..1].upcase})"
  end

  def json_card
    {
      id: id,
      value_display: value_display,
      suit_display: suit.upcase,
      value: value,
      suit: suit,
      style: style,
      humanized: to_s
    }
  end

  def self.language_for_mathematica(mathematica)
    return :plus unless mathematica.present? && mathematica.mathematica?
    UNICODE[:OPERATORS].keys.select{|k| mathematica.style.to_s.gsub("_", "") == UNICODE[:OPERATORS][k]}.first.to_sym
  end

  def self.style_for_language(language)
    :"_#{UNICODE[:OPERATORS][language].to_sym}_".to_s
  end

  def self.generate_possibilities_for_player(scope_player)
    return # todo
    return unless scope_player.present?

    Thread.current[:player] = scope_player
    return unless player_words.any?
  end

  def possibilities(scope_player)
    Thread.current[:player] = scope_player
    return {
      word: self.json_card,
      for_type: possibility_for_type,
      options: []
    } unless Thread.current[:player].present?

    player_legend = player.player_legends.where(legend: player.active_legend).first
    writable = player_legend.writables.create(word: self)

    mapper = Proc.new{|action, o|
      http_verb = :post
      humanized_title = "#{self_sentence.present? ? self_sentence.value_display : value_display}#{player.current_language.present? ? " #{player.current_language.value_display}" : ""} #{action}"
      total_weight = 0

      payload = {}
      s = nil
      if o.kind_of?(Sentence)
        s = o
      end
      w = o if s.nil?

      result_value = 0
      case action
      when :can_sign
        if s.nil?
          if self_sentence.nil?
            # create new sentence & sign with self
            result_value = self.absolute_value
            humanized_title += " a new sentence with #{w.value_display}"
            total_weight = self.weight + w.weight
            payload = {
              word_id: self.id,
              sentence: {
                signature_id: self.id,
                word_ids: [w.id]
              }
            }
          else
            # sign self_sentence with w
            result_value = w.absolute_value
            humanized_title += " a new sentence with #{w.value_display}"
            total_weight = self_sentence.weight + w.weight
            payload = {
              sentence_id: self_sentence.id,
              sentence: {
                signature_id: w.id
              }
            }
          end
        else
          result_value = self.absolute_value
          humanized_title += " #{s.value_display}"
          total_weight = self.weight + s.weight
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
            result_value = self.combined_with_value(w)
            humanized_title += " with #{w.value_display} = #{result_value}"
            total_weight = self.weight + w.weight
            payload = {
              word_id: possibility_for_type == :player_word ? self.id : w.id,
              sentence: {
                word_ids: [self.id, w.id]
              }
            }
          else
            # add w to self_sentence
            result_value = self.combined_with_value(w)
            humanized_title += " with #{w.value_display} = #{result_value}"
            total_weight = self_sentence.weight + w.weight
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
            result_value = self.combined_with_value(s.words.first)
            humanized_title += " with #{s.value_display} = #{result_value}"
            total_weight = s.weight + self.weight
            payload = {
              sentence_id: s.id,
              sentence: {
                word_ids: s.words.pluck(:id) + [self.id]
              }
            }
          else
            # merge self_sentence & s
            result_value = self.combined_with_value(s.words.first)
            humanized_title += " with #{s.value_display} = #{result_value}"
            total_weight = self_sentence.weight + s.weight
            http_verb = :put
            payload = {
              sentence_ids: [self_sentence.id, s.id],
              value: result_value
            }
          end
        end
      when :can_stack
        result_value = self.absolute_value
        if s.nil?
          if self_sentence.nil?
            # stack self with w
            humanized_title += " with #{w.value_display}"
            total_weight = self.weight + w.weight
            payload = {
              word_id: self.id,
              sentence: {
                word_ids: [self.id, w.id],
                is_stack: true
              }
            }
          else
            # add w to self_sentence
            humanized_title += " with #{w.value_display}"
            total_weight = self_sentence.weight + w.weight
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
            humanized_title += " with #{s.value_display}"
            total_weight = self.weight + s.weight
            payload = {
              sentence_id: s.id,
              sentence: {
                word_ids: s.words.pluck(:id) + [self.id],
                is_stack: true
              }
            }
          else
            # merge self_sentence & s
            humanized_title += " with #{s.value_display}"
            total_weight = self_sentence.weight + s.weight
            http_verb = :put
            payload = {
              sentence_ids: [self_sentence.id, s.id],
              value: result_value,
              is_stack: true
            }
          end
        end
      end

      # todo: caching writables

      option = writable.writable_options.create(payload: {
        body: payload,
        http_verb: http_verb,
        entry_text: humanized_title.gsub("", "_"),
        value: result_value
      }.to_json)

      {
        uuid: option.uuid,
        action: action,
        word: w&.json_card,
        sentence: s&.json_sentence,
        humanized_title: humanized_title,
        total_weight: total_weight.round(4),
        result_value: result_value
      }
    }

    result = []
    result += (can_sign_options || []).map{|o| mapper.call(:can_sign, o)}
    result += (can_combine_options || []).map{|o| mapper.call(:can_combine, o)}
    result += (can_stack_options || []).map{|o| mapper.call(:can_stack, o)}

    {
      uuid: writable.uuid,
      word: self.json_card,
      for_type: possibility_for_type,
      options: result.sort_by{|o| o[:total_weight]}.reverse
    }
  end

  # private

    def possibility_for_type
      return @for_type unless @for_type.nil?

      # self is a player word
      for_type = :player_word if player_words.include?(self)
      # self is a scroll word
      for_type = :scroll_word if !for_type &&
        scroll_words.include?(self)
      # self is a scroll sentence
      for_type = :scroll_sentence if !for_type &&
        SentenceWord.where(sentence_id: scroll_sentences.pluck(:id)).pluck(:word_id).include?(self.id)

      @for_type = for_type
      @for_type
    end

    def signature_matcher(words)
      words.select{|w|
        (number? && w.number? && self.absolute_value == w.absolute_value) || # numbers
        (self.style == w.style && !number? && !w.number? && !mathematica? && !w.mathematica?) # face words
      }
    end

    def can_sign_options
      return [] if mathematica?

      case possibility_for_type
      when :player_word
        #
        # => get all scroll words and sentences that equal self.value
        #
        #     can_sign =
        #       self.value == scroll_word.value || self.value == scroll_sentence.value
        #
        return signature_matcher(scroll_words) +
          scroll_sentences.select{|ss|
            self.absolute_value == ss.value
          }

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
        return [] if self_sentence.present? && self_sentence.is_stack
        return signature_matcher(player_words)
      end
    end

    def can_combine_options
      return [] unless number?
      player_aus = player.authored_unsigned_sentences.filter{|s| s.id != self_sentence&.id}

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
          w.number? && numeric_player_words.any?{|pw|
            pw.value == combined_with_value(w) &&
            (!player_aus.any? || player_aus.first.value == pw.value)
          }
        } + scroll_sentences.select{|ss|
          !ss.is_stack && numeric_player_words.any?{|pw|
            pw.number? && pw.value == combined_with_value(ss.words.first)
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
            pw.value == combined_with_value(w) &&
            (!player_aus.any? || player_aus.first.value == pw.value)
          }
        } + scroll_words.select{|w|
          w.id != self.id && w.number? && numeric_player_words.any?{|pw|
            pw.value == combined_with_value(w) &&
            (!player_aus.any? || player_aus.first.value == pw.value)
          }
        } + scroll_sentences.select{|ss|
          !ss.is_stack && numeric_player_words.any?{|pw|
            pw.value == combined_with_value(ss.words.first) &&
            (!player_aus.any? || player_aus.first.value == pw.value)
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
        return [] if self_sentence.present? && self_sentence.is_stack
        return player_words.select{|w|
          w.number? && numeric_player_words.any?{|pw|
            pw.value == combined_with_value(w) &&
            (!player_aus.any? || player_aus.first.value == pw.value)
          }
        } + scroll_words.select{|w|
          w.number? && numeric_player_words.any?{|pw|
            pw.value == combined_with_value(w) &&
            (!player_aus.any? || player_aus.first.value == pw.value)
          }
        } + scroll_sentences.select{|ss|
          (self_sentence.nil? || self_sentence.id != ss.id) &&
          numeric_player_words.any?{|pw|
            pw.value == combined_with_value(ss.words.first) &&
            (!player_aus.any? || player_aus.first.value == pw.value)
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
        #     can_stack = self.value == scroll_word.value && any_other_player_word.value == self.value ||
        #       self.value == sentence.value && any_other_player_word.value == self.value
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
      when :scroll_word, :scroll_sentence
        # when :scroll_word
        #
        # => all scroll/player words and sentences that can form a stack
        #
        #     can_stack = self.value == player_word.value && any_other_player_word.value == self.value ||
        #       self.value == scroll_word.value && any_other_player_word.value == self.value ||
        #       self.value == sentence.value && any_other_player_word.value == self.value
        #
        #
        # when :scroll_sentence
        #
        # => all scroll/player words and sentences that can form a stack
        #
        #     can_stack = self.sentence.value == player_word.value && any_other_player_word.value == self.sentence.value ||
        #       self.sentence.value == scroll_word.value && any_other_player_word.value == self.sentence.value ||
        #       self.sentence.value == sentence.value && any_other_player_word.value == self.sentence.value ||
        #
        #
        return player_words.select{|w|
          w.number? && (
            self.absolute_value == w.value && numeric_player_words.select{|pw|
              w.id != pw.id && pw.value == w.value
            }.any?
          )
        } + scroll_words.select{|w|
          w.id != self.id && w.number? && (
            self.absolute_value == w.value && numeric_player_words.select{|pw|
              pw.value == w.value
            }.any?
          )
        } + scroll_sentences.select{|ss|
          (self_sentence.nil? || self_sentence.id != ss.id) &&
          self.absolute_value == ss.value && numeric_player_words.select{|pw|
            pw.value == ss.value
          }.any?
        }
      end
    end

    # force_language is used for mathematica calculations
    def combined_with_value(combined_with_word, force_language = nil)
      return 0 unless number? && combined_with_word.number?

      # if the player currently has a mathematica applied, use it
      force_language = Word.language_for_mathematica(player.current_language) unless player.current_language.nil?
      language = force_language

      if language.nil?
        if self_sentence.present?
          # if self is a sentence word, apply rules from self_sentence language

          # cannot combine sentences if languages do not match
          return 0 if combined_with_word.self_sentence.present? &&
            self_sentence.language != combined_with_word.self_sentence.language

          # cannot combine
          return 0 if self_sentence.is_stack && combined_with_word.absolute_value != self.absolute_value

          language = (force_language || self_sentence.language || :plus).to_sym
        elsif combined_with_word.self_sentence.present?
          # if combined_with_word is a sentence word, apply rules from combined_with_word.self_sentence language

          # cannot combine
          return 0 if combined_with_word.self_sentence.is_stack && combined_with_word.absolute_value != self.absolute_value

          language = (force_language || combined_with_word.self_sentence.language || :plus).to_sym
        end
      end

      case language || :plus
      when :plus
        return self.absolute_value + combined_with_word.absolute_value
      when :minus
        return self.absolute_value - combined_with_word.absolute_value
      when :times
        return self.absolute_value * combined_with_word.absolute_value
      when :over
        return self.absolute_value.to_f / combined_with_word.absolute_value.to_f
      end
    end


end
