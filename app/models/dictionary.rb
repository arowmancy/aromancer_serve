# standard 78-card tarot deck
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

  def get_word(code)
    s_code = code.to_s.first
    value = code.to_s.gsub(s_code, "").to_i
    suit = case s_code.to_sym
    when :t
      :trumps
    when :c
      :cups
    when :s
      :swords
    when :p
      :pentacles
    when :w
      :wands
    end

    words.find_by(suit: suit, value: value)
  end

  def t1
    words.find_by(suit: :trumps, value: 1)
  end
  def tii
    words.find_by(suit: :trumps, value: 2)
  end
  def tiii
    words.find_by(suit: :trumps, value: 3)
  end
  def tiv
    words.find_by(suit: :trumps, value: 4)
  end
  def tv
    words.find_by(suit: :trumps, value: 5)
  end
  def tvi
  end

  private

  def generate
    order_index_counter = 0
    Word.suits.keys.each{|current_suit|
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
      else
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
    }

    # do not shuffle for tests
    unless Rails.env.test?
      # this should be all the randomization needed
      shuffled = words.pluck(:order_index).to_a
      Random.rand(2..Random.rand(2..22)).times do
        shuffled.shuffle!
      end
      words.to_a.each_with_index{|w, i|
        w.update(order_index: shuffled[i])
      }
    end

    raise "generate dictionary error! words.count not equal to 78?" unless words.count == 78
  end
end
