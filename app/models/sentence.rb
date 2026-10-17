class Sentence < ApplicationRecord
  has_many :sentence_words, dependent: :destroy
  has_many :words, through: :sentence_words
  belongs_to :mathematica, class_name: :Word, optional: true
  belongs_to :author, class_name: :Player, optional: true # the player who "writes" the sentence "owns" it (total_points++).
  belongs_to :chapter
  belongs_to :signature, class_name: :Word, optional: true # a word that writes the sentence.

  after_save :configure_value, :configure_language
  before_create :configure_language
  after_create :configure_value

  enum :language, [
    :plus,
    :minus,
    :times,
    :over
  ]

  def value_display
    "#{to_s}#{Word::UNICODE[:equals]}#{value}"
  end

  def weight
    (signature&.weight || 0) + words.where.not(id: signature&.id).map{|w| w.weight}.sum
  end

  def to_s
    sig = signature.present? ? signature.value_display + "(SIG)_" : ""
    wds = words.map{|w| w.value_display}.join("_")
    stk = is_stack ? "_(STK)" : ""
    mth = "#{mathematica.present? ? mathematica.value_display : "#{Word::UNICODE[:integral]}(#{Word::UNICODE[:OPERATORS][:plus]})"}"
    "#{mth}#{Word::UNICODE[:equals]}[#{sig}#{wds}]#{stk}".gsub(" ", "_")
  end

  def json_sentence
    {
      id: id,
      value: value,
      value_display: value_display,
      author: author.present? ? chapter.player_json(author).except(:words) : nil,
      signature: signature.present? ? signature.json_card : nil,
      words: words.sort_by{|w| [w.value, w.suit]}.map{|w| w.json_card},
      is_stack: is_stack,
      style: words.first&.style || :number
    }
  end

  private

  def configure_language
    # default
    new_language = :plus.to_s
    self.language ||= new_language

    # mathematica override
    if mathematica.present?
      new_language = Word.language_for_mathematica(mathematica) || :plus.to_s
    end
    self.language ||= new_language

    # update if needed
    self.update(language: new_language) unless self.language.to_sym == new_language.to_sym || self.new_record?
  end

  def configure_value
    configure_language if self.language.nil?

    calc = value
    if signature.present? && value != signature.value
      calc = signature.value
    elsif signature.nil?
      vals = words.pluck(:value)
      if !is_stack
        writable_option = WritableOption.find_by(id: Thread.current[:writable_option_id])
        if writable_option.present?
          # clean up
          calc = JSON.parse(writable_option.payload || "{}").symbolize_keys[:value] || 0
        else
          calc = vals.sum
        end
      else
        calc = value || vals.max
      end
    end

    self.update(value: calc) unless calc == value || self.new_record?

  end

end
