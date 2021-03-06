defmodule Golf.Game.Event do
  alias __MODULE__
  alias Golf.Game.Player

  @derive Jason.Encoder
  defstruct [:action, :player_id, :data]

  @type action :: :take_from_deck | :take_from_table | :swap | :uncover

  @type t :: %Event{
          action: action,
          player_id: Player.id(),
          data: %{}
        }

  def new(action, player_id, data \\ %{}) do
    %Event{action: action, player_id: player_id, data: data}
  end
end
