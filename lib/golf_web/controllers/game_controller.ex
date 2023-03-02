defmodule GolfWeb.GameController do
  use GolfWeb, :controller

  alias Golf.{Game, GameServer, GameSupervisor}

  def create_game(conn, _params) do
    user = conn.assigns.current_user
    game_id = GameServer.gen_game_id()
    host = Game.Player.new(user.id, user.email)
    game = Game.new(game_id, host)

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        GameSupervisor,
        {GameServer, game}
      )

    conn
    |> put_session(:game_id, game_id)
    |> redirect(to: ~p"/game/#{game_id}")
  end

  def leave_game(conn, params) do
    user = conn.assigns.current_user
    game_id = params["game_id"]
    GameServer.remove_player(game_id, user.id)

    conn
    |> delete_session(:game_id)
    |> redirect(to: ~p"/")
  end
end
