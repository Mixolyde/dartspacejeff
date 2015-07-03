library game_test;

import 'dart:math';
import 'package:unittest/unittest.dart';

import 'package:dartbase_server/dartbase_server.dart';

void main() {
  group('new game tests', () {
    test('game data init', () {
      Game game = new Game();

      expect(game.isStarted, isFalse);
      expect(game.round, isNull);
      expect(game.players.length, 0);
    });
    test('game add players', () {
      Game game = new Game();

      expect(game.addPlayer("Brian"), isTrue);
      expect(game.players.length, 1);
      expect(game.addPlayer("Brian"), isTrue);
      expect(game.addPlayer("Brian"), isTrue);
      expect(game.addPlayer("Brian"), isTrue);
      expect(game.players.length, 4);

      expect(game.addPlayer("Brian"), isFalse);
      expect(game.players.length, 4);

      expect(game.isStarted, isFalse);
    });
    test('start game', () {
      Game game = new Game();

      expect(game.addPlayer("Brian"), isTrue);
      expect(game.players.length, 1);
      expect(game.startGame(), isFalse);

      expect(game.addPlayer("Brian"), isTrue);
      expect(game.addPlayer("Brian"), isTrue);
      expect(game.players.length, 3);
      expect(game.startGame(), isTrue);
      expect(game.startGame(), isTrue);

      //can't add a player after starting
      expect(game.addPlayer("Brian"), isFalse);
      expect(game.players.length, 3);
      expect(game.startGame(), isTrue);

      expect(game.isStarted, isTrue);
    });
  });
  group('make card selections', () {
    test('make some selections', () {
      //pick first card from 3/4 player's hands
      Game game = createSeededGame(4);
      game.makeSelection(game.players[0], game.round.roundData[game.players[0].playerNum].hand[0]);
      game.makeSelection(game.players[1], game.round.roundData[game.players[1].playerNum].hand[0]);
      game.makeSelection(game.players[2], game.round.roundData[game.players[2].playerNum].hand[1]);

      expect(game.round.roundState, RoundState.make_selections);
      expect(game.round.selections.keys.length, 3);
      expect(game.round.activePlayer, null);
    });
    test('make all deferred selections same card', () {
      Game game = createSeededGame(4);

      //all four seeded hands have a lab
      game.makeSelection(game.players[0], game.round.roundData[game.players[0].playerNum].hand[3]);
      game.makeSelection(game.players[1], game.round.roundData[game.players[1].playerNum].hand[3]);
      game.makeSelection(game.players[2], game.round.roundData[game.players[2].playerNum].hand[3]);

      expect(game.round.roundState, RoundState.make_selections);
      expect(game.round.selections.keys.length, 1);

      //finish selection round
      game.makeSelection(game.players[3], game.round.roundData[game.players[3].playerNum].hand[2]);

      //should move all selections to deferred, draw a card and reset round to next turn
      expect(game.round.roundState, RoundState.make_selections);
      expect(game.round.selections.keys.length, 0);
      expect(game.round.turnCount, 2);
      expect(game.round.activePlayer, null);
      expect(game.round.roundData.keys.every((player) {
        return game.round.roundData[player].hand.length == 5 &&
            game.round.roundData[player].deferred.length == 1 &&
            game.round.roundData[player].deck.length == 14;
      }), isTrue);
    });
    test('make all deferred selections two pairs of cards', () {
      Game game = createSeededGame(4);

      //two coms and two labs
      game.makeSelection(game.players[0], game.round.roundData[game.players[0].playerNum].hand[1]);
      game.makeSelection(game.players[1], game.round.roundData[game.players[1].playerNum].hand[2]);
      game.makeSelection(game.players[2], game.round.roundData[game.players[2].playerNum].hand[3]);

      expect(game.round.roundState, RoundState.make_selections);
      expect(game.round.selections.keys.length, 2);

      //finish selection round
      game.makeSelection(game.players[3], game.round.roundData[game.players[3].playerNum].hand[2]);

      //should move all selections to deferred, draw a card and reset round to next turn
      expect(game.round.roundState, RoundState.make_selections);
      expect(game.round.selections.keys.length, 0);
      expect(game.round.turnCount, 2);
      expect(game.round.activePlayer, null);
      expect(game.round.roundData.keys.every((playerNum) {
        return game.round.roundData[playerNum].hand.length == 5 &&
            game.round.roundData[playerNum].deferred.length == 1 &&
            game.round.roundData[playerNum].deck.length == 14;
      }), isTrue);
    });
    test('make no deferred selections', () {
      Game game = createSeededGame(4);

      //two coms and two labs
      game.makeSelection(game.players[0], game.round.roundData[game.players[0].playerNum].hand[0]);
      game.makeSelection(game.players[1], game.round.roundData[game.players[1].playerNum].hand[0]);
      game.makeSelection(game.players[2], game.round.roundData[game.players[2].playerNum].hand[1]);

      expect(game.round.roundState, RoundState.make_selections);
      expect(game.round.selections.keys.length, 3);

      //finish selection round
      game.makeSelection(game.players[3], game.round.roundData[game.players[3].playerNum].hand[1]);

      //should move all selections to deferred, draw a card and reset round to next turn
      expect(game.round.roundState, RoundState.play_card);
      expect(game.round.selections.keys.length, 4);
      expect(game.round.turnCount, 1);
      expect(game.round.activePlayer, game.players[3]);
      expect(game.round.activePlayer == game.players[3], isTrue);
      expect(game.round.activePlayer == game.players[0], isFalse);
      expect(game.round.roundData.keys.every((playerNum) {
        return game.round.roundData[playerNum].hand.length == 5 &&
            game.round.roundData[playerNum].deferred.length == 1 &&
            game.round.roundData[playerNum].deck.length == 14;
      }), isTrue);
    });
  });
}

Game createSeededGame(int numPlayers) {
  serverRandom = new Random(0);
  //4 player hands:
  //com, com, lab, lab, sab
  //rec, doc, com, lab, fac
  //rec, doc, doc, lab, sab
  //com, lab, lab, fac, pow

  Game game = new Game();
  for (var i = 1; i <= numPlayers; i++) {
    game.addPlayer("TestPlayer${i}");
  }
  game.startGame();
  return game;
}
