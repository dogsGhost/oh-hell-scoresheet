Ohs =
  init: ->
    @setButtons()
    @cacheVariables()
    @bindNewGame()

  setButtons: ->
    $('button').each ->
      $(@).button() unless $(@).hasClass 'ui-button'
    $('.js-radioset').each ->
      $(@).buttonset() unless $(@).hasClass 'ui-buttonset'

  cacheVariables: ->
    @$namesFormTemplate = Handlebars.compile $('#namesFormTemplate').html()
    @$biddingFormTemplate = Handlebars.compile $('#biddingFormTemplate').html()
    @$correctBidsFormTemplate =
      Handlebars.compile $('#correctBidsFormTemplate').html()
    @$scoreBoardTemplate = Handlebars.compile $('#scoreBoardTemplate').html()
    @$newGameBtn = $ '#newGameBtn'
    @$container = $ '#container'
    @$numPlayersSection = $ '#numPlayersSection'
    @$scoringForm = $ '#scoringForm'
    @previousHands = ''
    @gameStarted = false
    @game = 
      players: []
      settings: {}    
    return

  bindNewGame: ->
    @$newGameBtn.on 'click', @startNewGame
    @$numPlayersSection.on 'click', 'button', @setNumPlayers

  startNewGame: ->
    # Check if this is the first game played.
    # If it is, note a game has been started.
    # Otherwise we have to reset views/variables.
    if not Ohs.gameStarted
      Ohs.gameStarted = true
    else
      Ohs.resetGame()
        
    Ohs.$numPlayersSection.removeClass 'hide'

  resetGame: ->
    # Reset the views and variables.
    @game = 
      players: []
      settings: {}
    @previousHands = ''      
    @$numPlayersSection
      .addClass('hide')
      .show()
    @$scoringForm
      .addClass('hide')
      .show()
      .nextAll()
        .remove()

  setNumPlayers: ->
    Ohs.game.settings.numPlayers = parseInt Ohs.$numPlayersSection.find('input:checked').val(), 10
    
    # Number of players indicates maximum number of cards a player can be dealt.
    p = Ohs.game.settings.numPlayers
    Ohs.game.settings.maxNumCards = if p <= 5 then 10 else Math.floor(52 / p)    
    Ohs.renderNamesForm()

  renderNamesForm: ->
    Utils.transitionTrigger @$numPlayersSection
    Utils.transitionFallback @$numPlayersSection

    # Create object to pass to template.    
    players = 
      count: num for num in [1..@game.settings.numPlayers]

    # Create template html and add to page.
    @$container.append @$namesFormTemplate(players)
    @setButtons()
    $('#namesForm')    
      .on('submit', @setPlayerNames)
      .removeClass('hide')

  setPlayerNames: (e) ->
    e.preventDefault()
    names = $(@).serializeArray()
    
    # Set default name if none given, then add player to the game.
    for name, index in names
      if not name.value then name.value = "Player #{index + 1}"
      Ohs.game.players.push new Player name.value.trim()
    
    Utils.transitionCallback $(@)
    Utils.transitionTrigger $(@)
    Utils.transitionFallback $(@), true
    Ohs.showScoringForm()

  showScoringForm: ->
    @$scoringForm
      .on('submit', @setScoringParams)
      .removeClass 'hide'

  setScoringParams: (e) ->
    e.preventDefault()

    params = $(@).serializeArray()
    
    # params[0] = starting hand size
    if parseInt(params[0].value, 10) is 0
      h = (num for num in [1..Ohs.game.settings.maxNumCards])
      h.push num for num in [(Ohs.game.settings.maxNumCards - 1)..1]
    else
      h = (num for num in [Ohs.game.settings.maxNumCards..1])
      h.push num for num in [2..Ohs.game.settings.maxNumCards]
    Ohs.game.settings.handSizeOrder = h

    # params[1] = trick point value - defaults to 1
    trickVal = parseInt params[1].value, 10
    Ohs.game.settings.trickValue = if trickVal then trickVal else 1

    # params[2] = correct bid point value - defaults to 5
    bidVal = parseInt params[2].value, 10
    Ohs.game.settings.correctBidValue = if bidVal then bidVal else 5

    Utils.transitionTrigger $(@)
    Utils.transitionFallback $(@)    
    Ohs.renderBiddingForm()

  renderBiddingForm: () ->
    # Create object to pass to template.
    data = @game
      
    data.handNum = data.players[0].hands.length + 1    
    data.numCards = data.settings.handSizeOrder[data.handNum - 1]
    data.count = (num for num in [0..data.numCards])
    data.numCards += if data.numCards > 1 then ' cards' else ' card'
    
    # Render template on the page. Assign next view's handler.
    @$container.append @$biddingFormTemplate(data)
    @setButtons()
    $('#biddingForm')
      .on('submit', @setPlayerBids)
      .removeClass('hide')
      .next()
        .on 'click', 'button', @renderCorrectBidsForm

  setPlayerBids: (e) ->
    e.preventDefault()

    # Assign the bids to their respective player.
    bids = $(@).serializeArray()

    for player in Ohs.game.players
      for bid in bids
        player.hands.push(new Hand bid.value) if player.name is bid.name
    
    Utils.transitionCallback $(@)
    # Show next view.
    Utils.transitionTrigger $(@)
    $(@)
      .next()
        .removeClass('hide')
    Utils.transitionFallback $(@), true       

  renderCorrectBidsForm: ->
    # Create object to pass to template.
    data =
      players: []

    i = Ohs.game.players[0].hands.length - 1
    for player in Ohs.game.players
      p =
        name: player.name
        bid: player.hands[i].bid
      p.bid += if p.bid is '1' then ' trick' else ' tricks'
      data.players.push p

    # Add form to page.
    Ohs.$container.append Ohs.$correctBidsFormTemplate(data)
    Ohs.setButtons()
    Ohs.$correctBidsForm = $('#correctBidsForm')

    # Set call back
    Utils.transitionCallback $(@).parent()

    # Change the view.
    Utils.transitionTrigger $(@).parent()
    Utils.transitionFallback $(@).parent(), true       
    
    Ohs.$correctBidsForm
      .on('submit', Ohs.calcBids)
      .removeClass 'hide'

  calcBids: (e) ->
    e.preventDefault()

    # Update results of hand just played.
    results = $(@).serializeArray()
    hand = Ohs.game.players[0].hands.length - 1
    for player in Ohs.game.players
      for result in results
        if result.name is player.name
          player.hands[hand].scoreHand(result.value)
          # Update player's overall score.
          player.totalScore += player.hands[hand].pointsEarned
    
    Ohs.renderScoreBoard()

  renderScoreBoard: ->
    scores = @game
    scores.handNum = scores.players[0].hands.length
    scores.prevHand = @previousHands

    # Find who has highest current score.
    leadScore = (player.totalScore for player in scores.players)
    leadScore = Utils.maxArray leadScore
    for player in scores.players
      if player.totalScore is leadScore
        player.winning = true

    # Add scoreboard html to page.
    @$container.append @$scoreBoardTemplate(scores)
    @setButtons()
    
    Utils.transitionCallback Ohs.$correctBidsForm
    
    # Show scoreboard.
    Ohs.$correctBidsForm
      .next()
        .on('click', 'button', Ohs.playNextHand)
        .find('tbody')
          .append(scores.prevHand)
          .end()
        .removeClass('hide')

    Utils.transitionTrigger Ohs.$correctBidsForm
    Utils.transitionFallback Ohs.$correctBidsForm, true   

    # Re-assign some values for next scoring round.
    @previousHands = $('tbody').html()
    for player in scores.players
      player.winning = false
    return

  playNextHand: ->
    # Start next hand of game.
    Utils.transitionCallback $(@).parent()
    Utils.transitionTrigger $(@).parent()
    Utils.transitionFallback $(@).parent(), true

    Ohs.renderBiddingForm()

Ohs.init()