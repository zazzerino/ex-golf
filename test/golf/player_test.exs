defmodule Golf.Game.PlayerTest do
  use ExUnit.Case, async: true
  alias Golf.Game.Player

  test "create player" do
    alice = Player.new("1234", "Alice")
    assert is_nil(alice.held_card)
    assert length(alice.hand) == 0
  end

  test "give cards" do
    alice = Player.new("1234", "Alice")
    alice2 = Player.give_cards(alice, ["AS", "5H"])
    assert length(alice2.hand) == 2
  end

  test "flip card" do
    alice = Player.new("1234", "Alice")

    alice2 = Player.give_cards(alice, ["AS", "5H"])
    %{face_up?: false} = Enum.at(alice2.hand, 1)

    alice3 = Player.flip_card(alice2, 1)
    %{face_up?: true} = Enum.at(alice3.hand, 1)
  end

  test "hold and discard" do
    alice = Player.new("1234", "Alice")

    alice2 = Player.hold_card(alice, "9C")
    assert is_binary(alice2.held_card)

    {card, alice3} = Player.discard(alice2)
    assert card == "9C"
    assert is_nil(alice3.held_card)
  end
end
