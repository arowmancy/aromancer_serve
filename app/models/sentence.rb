class Sentence < ApplicationRecord
  has_many :sentence_words
  has_many :words, through: :sentence_words
  belongs_to :author, class_name: :Player, optional: true # the player who "writes" the sentence "owns" it (total_points++).
  belongs_to :chapter
  belongs_to :signature, class_name: :Word, optional: true # a word that writes the sentence.

  after_save :configure_value
  # todo: don't forget to set the sentence_instance.value when a sentence
  # gets started by a player. author + value is defined by them but can
  # be overridden by another player if the sentence is left on the scroll.

  def json_sentence
    {
      id: id,
      value: value,
      author: author.present? ? chapter.player_json(author) : nil,
      signature: signature.present? ? signature.json_card : nil,
      words: words.sort_by{|w| [w.value, w.suit]}.map{|w| w.json_card}
    }
  end

  private

  def configure_value
    calc = signature.present? ? signature.value : words.pluck(:value).sum
    update(value: calc) if value != calc
  end
end
