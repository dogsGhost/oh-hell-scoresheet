/**
 * @fileoverview Handles all functionality for executing the Oh Hell Scoresheet web application
 * that allows the user to track the scores of everyone during a game of Oh Hell.
 * Dependencies: jQuery 1.7+
 * @author davwilh.com
 */

jQuery(function ($) {

    // standard variables
    var game,
        bid,
        bidGuess,
        cardCount,
        cor,
        correctBidValue,
        eachName,
        fields,
        gLen,
        hand,
        handFormat,
        handSeq,
        has,
        i,
        j,
        k,
        len,
        maxNumCards,
        maxScore,
        n,
        names,
        numHands,
        numPlayers,
        scoreArr,
        tmp,
        tmpArr,
        tmpNum,
        trickValue,
        winner;
        
    // jQuery variables
    var    $bidList = $('form#playerBidList'),
        $correctBidForm = $('form#correctBidForm'),
        $handFinished = $('button#handFinished'),
        $namesForm = $('form#namesForm'),
        $newGame = $('form#newGame'),
        $nextHand = $('button#nextHand'),
        $numPlayersForm = $('form#numberPlayers'),
        $overlay = $('div.overlay'),
        $scoreBoard = $('div#scoreBoard'),
        $scoringForm = $('form#scoringForm'),
    
    // Player object used for items in game array, hold player's name, total score, and array of Hand objects
        Player = function (name) {
            this.name = name;
            this.hands = [];
            this.totalScore = 0;
        },
    
    // Hand object used for item in hands array, contains the bid, score, and if the bid was matched for each hand of a Player in a game
        Hand = function (bid) {
            this.bid = bid;
            this.correct = true;
            this.handScore = function (a) {
        return a ? ((this.bid * trickValue) + correctBidValue) : 0;
            };
        };

    // FUNCTIONS
    // find the max value in an array
    function maxArray(array) {
        return Math.max.apply(null, array);
    }

    // removes whitespace before/after strings
    function trim(string) {
        var tmp = string;
        tmp = tmp.replace(/^\s+|\s+$/g, '');
        return tmp;
    }

    // hides current element and shows its immediate sibling element
    function showNext(container) {
        $(container)
            .toggleClass('hidden')
            .next().toggleClass('hidden');
    }

    // inserts label/input for each player's name based on number of players selected
    function insertNameForms(selector, num) {
        var tmp = '';
        for (i = 1; i <= num; i += 1) {
            tmp += '<li><label for="name' + i + '">Player ' + i + 's name:</label>' +
            '<input type="text" size="16" class="player-name" name="name' + i + '" id="name' +
            i +  '" placeholder="Player'  + i + '" /></li>';
        }
        $(selector).prepend(tmp);
    }

    // use maxNumCards in conjunction with game format selected to set value of numHands; set sequence for num of cards per hand
    function numberOfHands(format) {
        var handFormat = Number(format);
        var tmpArr = [];
        var handSeq = [];
        var tmp = "";
        var numHands = handFormat <= 1 ? maxNumCards + (maxNumCards - 1) : maxNumCards;

        if (handFormat < 1 || handFormat === 2) {
            for (i = 1; i <= maxNumCards; i += 1) {
                handSeq.push(i);
                tmpArr.push(i);
            }
            if (handFormat < 1) {
                tmpArr = tmpArr.reverse();
                tmpArr.splice(0, 1);
                handSeq = handSeq.concat(tmpArr);
            }
        } else {
            for (i = maxNumCards; i >= 1; i -= 1) {
                handSeq.push(i);
                tmpArr.push(i);
            }
            if (handFormat < 2) {
                tmpArr = tmpArr.reverse();
                tmpArr.splice(0, 1);
                handSeq = handSeq.concat(tmpArr);
            }
        }
        for (i = 1; i <= numHands; i += 1) {
            tmp += "<tr data-hand-num='" + (i - 1) + "' class='hand'>" +
            "<th scope='row'>Hand " + i + "</th></tr>";
        }
        $scoreBoard.find("tbody").append(tmp);
    }

    // loads bidding form
    function bidInputForm(arr) {
        hand = arr[0].hands;
        hand = (hand.length) + 1;
        cardCount = handSeq[(hand - 1)];
        tmp = "";

        $bidList.find("h2").prepend('Hand ' + hand + ' (' + cardCount + ' Cards)');

        for (i = 0; i <= cardCount; i += 1) {
            tmp += '<option>' + i + '</option>';
        }
        
        for (i = 0; i < numPlayers; i += 1) {
            eachName = arr[i].name;
            $bidList.find("ul").append('<li><label for="player' + i + 'bids">' +
                'How many tricks does ' + eachName + ' bid?</label>' +
            '<select name="player' + i + 'bids" id="player' + i + 'bids">' + tmp +
            '</select></li>');
        }
    }

    // loads form for checking if bids were correct
    function correctBidsForm(arr) {
        hand -= 1;
        for (i = 0; i < numPlayers; i += 1) {
            eachName = arr[i].name;
            bidGuess = arr[i].hands[hand].bid;
            $correctBidForm.find("ul").append('<li>Did ' + eachName + ' win ' + bidGuess +
                ' tricks?<br />' + '<input type="radio" name=group"' + i + '" value="1"' +
                ' checked="checked" /> Yes <br /><input type="radio" name=group"' + i +
                '" value="0" /> No</li>');
        }
    }

    // starts a new game - resets game, empty's containers with generated content, hides sections
    $newGame.on('submit', newGameFunc);

    function newGameFunc (e) {
        e.preventDefault();
        
        game = [];
        numPlayers = 0;
        
        $scoreBoard
            .find("thead")
                .find("tr")
                    .empty()
                    .append("<th>&nbsp;</th>")
                .end()
            .end()
            .find("tbody")
                .empty()
            .end()
            .find('p')
                .hide()
                .empty()
            .end()
            .addClass('hidden');
        $('div.wrapper > form').addClass('hidden');
        $nextHand.show();
        $namesForm.find("ul").empty();
        $numPlayersForm.removeClass('hidden');

    }

    // submits how many players there will be
    $numPlayersForm.submit(function (e) {
        e.preventDefault();
        numPlayers = Number($("#numPlayers").val());
        insertNameForms("form#namesForm ul", numPlayers);
        showNext(this);
        // number of players dictates maximum number of cards a player can be dealt
        maxNumCards = numPlayers <= 5 ? 10 : Math.floor(52 / numPlayers);
    });

    // sets player names and inserts them on page; if no name given than PlayerX is assigned as name
    $namesForm.submit(function (e) {
        e.preventDefault();
        names = $(this).serializeArray();
        i = 0;
        $.each(names, function (i, name) {
            n = trim(name.value);
            return n || (n = "Player " + (i + 1)),
            game.push(new Player(n)),
            $scoreBoard.find("thead").find("tr").append("<th scope='col'>" + n + "</th>");
        });
        showNext(this);
    });

    // set game format and scoring value then initiate first round of bidding for game
    $scoringForm.submit(function (e) {
        e.preventDefault();

        fields = $(this).serializeArray();

        trickValue = parseInt(fields[1].value, 10);
        correctBidValue = parseInt(fields[2].value, 10);

        numberOfHands(fields[0].value);
        if (!trickValue || isNaN(trickValue)) {
            trickValue = 1;
        }
        if (!correctBidValue || isNaN(correctBidValue)) {
            correctBidValue = 10;
        }
        bidInputForm(game);
        $overlay.toggleClass('hidden');
        showNext(this);
    });

    // adds bids as property of Hand obj in array of hand property of Player obj
    $bidList.submit(function (e) {
        e.preventDefault();
        
        var bids = $(this).serializeArray();
        len = bids.length;
        gLen = game.length;
        for (i = 0; i < len; i += 1) {
            bid = parseInt(bids[i].value, 10);
            for (j = 0; j < gLen; j += 1) {
                if (i === j) {
                    (game[j].hands).push(new Hand(bid));
                }
            }
        }
        
        showNext(this);
        correctBidsForm(game);
        $bidList.find("h2")
            .empty()
        .end().find("ul")
            .empty();
    });

    // Closes the 'play hand!' window and moves on the stating if bids were correct
    $handFinished.on('click', function () {
        showNext($(this).parent("div"));
    });

    // get correct values and set hand.correct value accordingly
    $correctBidForm.submit(function (e) {
        e.preventDefault();
        
        fields = $(this).serializeArray();
        len = fields.length;
        scoreArr = [];
        for (i = 0; i < len; i += 1) {
            cor = parseInt(fields[i].value, 10);
            if (!cor) {
                for (j = 0; j < gLen; j += 1) {
                    if (j === i) {
                        game[j].hands[hand].correct = false;
                    }
                }
            }
        }
        
        // calcute each players score and output to the scoretable
        for (i = 0; i < gLen; i += 1) {
            j = game[i].hands[hand].correct;
            k = game[i].hands[hand].handScore(j);
            
            game[i].totalScore += k;
            scoreArr.push(game[i].totalScore);

        }
        // find max of scoreArr then loop over scoreArr wrapping in td's and adding to tmp, when you get max score add a class to the td
        maxScore = maxArray(scoreArr);
        tmp = "";
        len = scoreArr.length;
        for (i = 0; i < len; i += 1) {
            tmp += scoreArr[i] === maxScore ?
                "<td class='high-score'>" + scoreArr[i] + "</td>" :
                "<td>" + scoreArr[i] + "</td>";
        }

        $scoreBoard
            .find("tbody")
            .find("tr[data-hand-num='" + hand + "']")
            .append(tmp)
            .show();
        hand = game[0].hands.length;

        // check if the game is over and show the winner
        if (numHands === hand) {
            // to find winner : loop over game and get total from each player, push to an array
            // find max of that array, loop over array, if item matches max log game[i].name as the winner
            tmpArr = [];
            winner = [];

            for (i = 0; i < gLen; i += 1) {
                tmpArr.push(game[i].totalScore);
            }
            
            len = tmpArr.length;
            tmpNum = maxArray(tmpArr);
            for (i = 0; i < len; i += 1) {
                if (tmpArr[i] === tmpNum) {
                    winner.push(game[i].name);
                }
            }
            
            has = "has";
            if (winner.length > 1) {
                has = "have";
            }
            winner = winner.join(" and ");
            
            $nextHand.hide();
            $scoreBoard.find("p")
                .html("The game is over, " + winner + " " + has + " won!")
                .show();
        }

        // hide the overlay so scoClassr'hidden'e can be viewed and set up overlay Classc'hidden'ontents for next round
        $overlay
            .toggleClass('hidden')
            .find(".modal").addClass('hidden')
            .first().toggleClass("hidden");
        $correctBidForm.find("ul").empty();
    });

    $nextHand.on("click", function () {
        // Fire Next Hand
        bidInputForm(game);
        $overlay.toggleClass('hidden');
    });

});
