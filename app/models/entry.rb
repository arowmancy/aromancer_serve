class Entry < ApplicationRecord
  belongs_to :chapter

  enum :action, [
    :server,
    :add_to_scroll,  # just adding a card. no combinations, expect scroll words passed to be empty
    :begin_sentence, # combine all words passed into an open sentence
    :sign_sentence,  # combine all words passed into a signed sentence
  ]
end
