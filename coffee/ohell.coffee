###
* @fileOverview Handles all functionality for executing the Oh Hell Scoresheet
* web application that allows the user to track the scores of everyone during a
* game of Oh Hell.
* Dependencies: jQuery, Handlebars
* @author David Wilhelm
* @version 2.3.9
###

Ohs =
  init: ->
    @cacheVariables()
    @bindNewGame()
    # Add trim method for IE8 support.
    Utils.trimCheck()

  cacheVariables: ->
    @$namesFormTemplate = Handlebars.compile $('#namesFormTemplate').html()
    @$biddingFormTemplate = Handlebars.compile $('#biddingFormTemplate').html()
    @$correctBidsFormTemplate = Handlebars.compile $('#correctBidsFormTemplate').html()
    @$scoreBoardTemplate = Handlebars.compile $('#scoreBoardTemplate').html()
    @$newGameBtn = $ '#newGameBtn'
    @$container = $ '#container'
    @$numPlayersSection = $ '#numPlayersSection'
    
    @gameStarted = false
    @game = []
    @settings = {}

    @$newGameBtn.button()
    true

  bindNewGame: ->
    @$newGameBtn.on 'click', @startNewGame
    @$numPlayersSection.find('button').on 'click', @setNumPlayers

  startNewGame: ->
    # Check if this is the first game played.
    # If it is, note a game has been started.
    # Otherwise we have to reset views/variables.
    if not Ohs.gameStarted
      Ohs.gameStarted = true
    else
      # do stuff
      Ohs.game = []
      Ohs.settings = {}

    Ohs.$numPlayersSection
      .slideDown()
      .removeClass 'hide'

  setNumPlayers: ->
    Ohs.settings.numPlayers = parseInt $('#numPlayers').val(), 10
    
    # Number of players indicates maximum number of cards a player can be dealt.
    p = Ohs.settings.numPlayers
    Ohs.settings.maxNumCards = if p <= 5 then 10 else Math.floor(52 / p)    
    Ohs.renderNamesForm()

  renderNamesForm: ->
    @$numPlayersSection.slideUp().addClass('hide')

    # Create object to pass to template.    
    players = 
      count: num for num in [1..@settings.numPlayers]

    # Create template html and add to page.
    @$container.append @$namesFormTemplate(players)
    $('#nameForm')    
      .on('submit', @setPlayerNames)
      .slideDown()
      .removeClass('hide')

  setPlayerNames: (e) ->
    e.preventDefault()
    names = $(@).serializeArray()
    
    # Set default name if none given, then add player to the game.
    for name, index in names
      if not name.value then name.value = "Player #{index + 1}"
      Ohs.game.push new Player name.value.trim()
    
    $(@).slideUp 400, -> $(@).remove()
    Ohs.renderScoringForm()

  renderScoringForm: ->
    $('#scoringForm')
      .on('submit', @setScoringParams)
      .slideDown()
      .removeClass('hide')

  setScoringParams: (e) ->
    e.preventDefault()

    params = $(@).serializeArray()
    
    # params[0] = starting hand size
    if parseInt(params[0].value, 10) is 0
      h = (num for num in [1..Ohs.settings.maxNumCards])
      h.push num for num in [(Ohs.settings.maxNumCards - 1)..1]
    else
      h = (num for num in [Ohs.settings.maxNumCards..1])
      h.push num for num in [2..Ohs.settings.maxNumCards]
    Ohs.settings.handSizeOrder = h

    # params[1] = trick point value - defaults to 1
    trickVal = parseInt params[1].value, 10
    Ohs.settings.trickValue = if trickVal then trickVal else 1

    # params[2] = correct bid point value - defaults to 5
    bidVal = parseInt params[2].value, 10
    Ohs.settings.correctBidValue = if bidVal then bidVal else 5

    $(@).slideUp(400, -> $(@).addClass('hide'))
    Ohs.renderBiddingForm()

  renderBiddingForm: () ->
    # Create object to pass to template.
    data =
      players: @game
      handNum: @game[0].hands.length + 1
    
    data.numCards = @settings.handSizeOrder[data.handNum - 1]
    data.count = (num for num in [0..data.numCards])
    data.numCards += if data.numCards > 1 then ' cards' else ' card'
    
    # Render template on the page. Assign next view's handler.
    @$container.append @$biddingFormTemplate(data)
    $('#biddingForm')
      .on('submit', @setPlayerBids)
      .slideDown()
      .removeClass('hide')
      .next()
        .find('button')
          .on 'click', @renderCorrectBidsForm

  setPlayerBids: (e) ->
    e.preventDefault()

    # Assign the bids to their respective player.
    bids = $(@).serializeArray()
    for player in Ohs.game
      for bid in bids
        player.hands.push(new Hand bid.value) if player.name is bid.name
    
    #
    $(@).slideUp 300, ->
      $(@)
        .next()
          .slideDown()
          .removeClass('hide')
          .end()
        .remove()

  renderCorrectBidsForm: ->
    # Create object to pass to template.
    data =
      players: []

    i = Ohs.game[0].hands.length - 1
    for player in Ohs.game
      p =
        name: player.name
        bid: player.hands[i].bid
      p.bid += if p.bid is 1 then ' trick' else ' tricks'
      data.players.push p

    # Change the view.
    Ohs.$container.append Ohs.$correctBidsFormTemplate(data)
    $(@).parent().slideUp 400, -> $(@).remove()
    $('#correctBidsForm')
      .on('submit', Ohs.calcBids)
      .slideDown()
      .removeClass 'hide'

  calcBids: ->
    results = $(@).serializeArray()
    true
    

  renderScoreBoard: (e) ->
    e.preventDefault()
    scores =
      players: Ohs.game

    # Ohs.$container.append Ohs.$scoreBoardTemplate(scores)
    
    $(@).slideUp 600, ->
      $(@)
        .next()
          .slideDown()
          .removeClass('hide')
          .end()
        .remove()

Ohs.init()