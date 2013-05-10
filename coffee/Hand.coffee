class Hand
  constructor: (@bid) ->
    @pointsEarned = 0
    @correctBid = false

  scoreHand: (guess) ->
    if guess is 'correct'
      @correctBid = true
      @pointsEarned = 
        @bid * Ohs.settings.trickValue + Ohs.settings.correctBidValue
    return