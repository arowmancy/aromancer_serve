class Entry < ApplicationRecord
  belongs_to :chapter
  belongs_to :player
  belongs_to :word

  enum :action, [
    :server,
    :add_to_scroll,  # just adding a word. no combinations, expect scroll words passed to be empty
    :edit_sentence, # combine all words passed into an open sentence
    :sign_sentence,  # combine all words passed into a signed sentence
  ]
end
