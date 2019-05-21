defmodule GameTest do
  use ExUnit.Case

  alias Hangman.Game

  test "new_game returns structure" do
    game = Game.new_game()
    assert game.turns_left == 7
    assert game.game_state == :initializing
    assert length(game.letters) > 0
  end

  test "state isn't changed for :won or :lost game" do
    for state <- [:won, :lost] do
      game = Game.new_game() |> Map.put(:game_state, state)
      assert {^game, _} = Game.make_move(game, "x")
    end
  end

  test "a guessed word is recognized with all good moves" do
    assert_game_moves("wibble", [
      {"w", :good_guess, 7, "w_____"},
      {"i", :good_guess, 7, "wi____"},
      {"b", :good_guess, 7, "wibb__"},
      {"l", :good_guess, 7, "wibbl_"},
      {"e", :won, 7, "wibble"}
    ])
  end

  test "a guessed word is recognized with some good and some bad moves" do
    assert_game_moves("rome", [
      {"r", :good_guess, 7, "r___"},
      {"o", :good_guess, 7, "ro__"},
      {"n", :bad_guess, 6, "ro__"},
      {"c", :bad_guess, 5, "ro__"},
      {"m", :good_guess, 5, "rom_"},
      {"m", :already_used, 5, "rom_"},
      {"e", :won, 5, "rome"}
    ])
  end

  test "a word is not guessed with some good and some bad moves" do
    assert_game_moves("mate", [
      {"m", :good_guess, 7, "m___"},
      {"x", :bad_guess, 6, "m___"},
      {"v", :bad_guess, 5, "m___"},
      {"v", :already_used, 5, "m___"},
      {"p", :bad_guess, 4, "m___"},
      {"k", :bad_guess, 3, "m___"},
      {"e", :good_guess, 3, "m__e"},
      {"f", :bad_guess, 2, "m__e"},
      {"s", :bad_guess, 1, "m__e"},
      {"h", :lost, 0, "m__e"}
    ])
  end

  test "a word is not guessed with only bad moves" do
    assert_game_moves("pain", [
      {"q", :bad_guess, 6, "____"},
      {"r", :bad_guess, 5, "____"},
      {"r", :already_used, 5, "____"},
      {"t", :bad_guess, 4, "____"},
      {"v", :bad_guess, 3, "____"},
      {"x", :bad_guess, 2, "____"},
      {"z", :bad_guess, 1, "____"},
      {"m", :lost, 0, "____"}
    ])
  end

  def assert_game_moves(word, moves) do
    Enum.reduce(
      moves,
      Game.new_game(word),
      fn {guess, state, turns_left, word}, game ->
        {game, tally} = Game.make_move(game, guess)

        assert game.game_state == state
        assert game.turns_left == turns_left

        assert tally.game_state == state
        assert tally.turns_left == turns_left
        assert tally.letters == String.codepoints(word)

        game
      end
    )
  end
end
