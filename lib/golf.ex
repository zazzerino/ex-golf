defmodule Golf do
  @doc """
  Generates a random six character string consisting of numbers and capital letters.
  # https://dreamconception.com/tech/elixir-simple-way-to-create-random-reference-ids/
  """
  def gen_id() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end

  def gen_game_id() do
    case Registry.lookup(Golf.GameRegistry, id = Golf.gen_id()) do
      # name hasn't been registered, so we'll return it
      [] -> id
      # name has already been registered, so we'll try again
      _ -> gen_game_id()
    end
  end

  def lookup_game(game_id) do
    Registry.lookup(Golf.GameRegistry, game_id)
  end
end
