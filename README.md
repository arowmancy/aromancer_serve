# ino

# client:
# gdevelop

# server:
# rails (api-only, https, wss)


# scoring (1 story):
#   points | description
# --------------------------------------
#   1      | total cards
#   1      | total trumps
#   1      | total face cards
#   1      | total swords (masculine)
#   1      | total wands (masculine)
#   1      | 10 of cups (feminine)
#   1      | 10 of pentacles (feminine)
#   4      | aces (1 point each)
# +___________________________
#   11       total
#

# models:

class Chapter
  has_many :sentences # a stack of 2 or more cards, one of which writes the sentence.
  belongs_to :story
end

#
class Sentence
  has_many :words # a "word" is a card
  has_one :signature # a word that writes the sentence.
  has_one :author # the player who "writes" the sentence "owns" it (total_points++).
  belongs_to :chapter

  # r g model Sentence
end

# a tarot card
class Word
  # rails g model Word suit:integer numeric:integer

  # enum suit
end

# standard 78-card tarot deck
class Dictionary
  has_many :words
end

# 00) arenas
#   a) types
#     - practice (1 legend, no stakes)
#     - legacy (> 1 legend, stakes)
#       note: a "legacy" is a collection of legends