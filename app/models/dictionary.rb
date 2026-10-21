# standard 78-card tarot deck with 6 mathematica operator words:
#
# 2-each of ["-", "×", "÷"]
#
# note: there are no "+" mathematica words because this
# is the default "language" of each sentence.
#
# total count in a dictionary is 84 words.
# one "story" is one full pass through the full tarot
# deck broken down by chapters.
#
# players are dealt the same number of words in each chapter.
#
# a standard 2-player story has 4 chapters
#
#   2 players x 11 words/each x 3 chapters = 66 words
#   2x11x3=(66) words each (3 chapters)
#
#   2 players x 9 words/each x 1 chapter = 18 words
#   2x9x1=(18) words each (last chapter)
#
# total: 84 = 66+18
#

class Dictionary < ApplicationRecord
  belongs_to :story
  has_many :words

  after_create :generate

  def get_top_word
    top = words.where(is_drawn: false).first
    return nil if top.nil?

    top.update(is_drawn: true)
    top
  end

  private

  def generate
    order_index_counter = 0
    Word.suits.keys.each do |current_suit|
      total_words = 14
      case current_suit.to_sym
      when :trumps
        total_words = 22
        1..total_words.times do |i|
          words.create(
            suit: current_suit,
            value: i == 0 ? total_words : i,
            order_index: order_index_counter
          )
          order_index_counter += 1
        end
      when :mathematica # math operation cards that get applied to a sentence
        total_words = 6 # include 2-each of non-addition languages
        [
          # plus is the default for all game-play
          # :plus,
          :minus,
          :times,
          :over
        ].each do |language|
          2.times do
            words.create(
              suit: current_suit,
              order_index: order_index_counter,
              style: Word.style_for_language(language)
            )
            order_index_counter += 1
          end
        end
      else # minor arcana
        1..total_words.times do |i|
          i = i + 1
          w = words.create(
            suit: current_suit,
            value: i,
            order_index: order_index_counter
          )
          order_index_counter += 1
          case i
          when 11
            w.update(style: :page, value: 0)
          when 12
            w.update(style: :knight, value: 0)
          when 13
            w.update(style: :queen, value: 0)
          when 14
            w.update(style: :king, value: 0)
          end
        end
      end

    end

    # this should be all the randomization needed
    shuffled = words.pluck(:order_index).to_a
    SecureRandom.rand(22..SecureRandom.rand(22..44)).times do
      shuffled.shuffle!
    end
    words.to_a.each_with_index{|w, i|
      w.update(order_index: shuffled[i])
    }

    raise "generate dictionary error! words.count not equal to 84?" unless words.count == 84
  end
end
