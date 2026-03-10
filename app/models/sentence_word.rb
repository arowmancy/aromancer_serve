class SentenceWord < ApplicationRecord
  belongs_to :sentence
  belongs_to :word
end
