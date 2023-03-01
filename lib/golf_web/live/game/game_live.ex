defmodule GolfWeb.Game.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.Game.GameComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Game")}
  end
end
