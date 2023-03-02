defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.GameComponents

  alias Golf.Game
  alias Golf.GameServer

  @impl true
  def mount(%{"game_id" => game_id} = _params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Golf.PubSub, "game:#{game_id}")
      send(self(), {:load_game, game_id})
    end

    {:ok,
     assign(socket,
       page_title: "Game",
       game_id: game_id,
       game_state: nil,
       table_card_0: nil,
       table_card_1: nil,
       players: [],
       playable_cards: [],
       last_event: nil,
       last_action: nil,
       last_event_pos: nil,
       can_start_game?: nil,
       chat_messages: [],
       draw_table_cards_first?: nil,
       trigger_leave_game?: nil
     )}
  end

  def assign_game_data(socket, game) do
    user = socket.assigns.current_user
    table_card_0 = Enum.at(game.table_cards, 0)
    table_card_1 = Enum.at(game.table_cards, 1)

    positions = hand_positions(length(game.players))
    user_index = Enum.find_index(game.players, &(&1.id == user.id))

    players =
      Enum.zip_with(positions, game.players, fn position, player ->
        player
        |> Map.put(:position, position)
        |> Map.put(:score, Game.Player.score(player))
      end)
      |> Golf.rotate(user_index)

    last_event = Enum.at(game.events, 0)
    last_action = if last_event, do: last_event.action

    last_event_pos =
      if last_event do
        player = Enum.find(players, &(&1.id == last_event.player_id))
        player.position
      end

    playable_cards = Game.playable_cards(game, user.id)
    can_start_game? = game.state == :not_started and user.id == game.host_id
    draw_table_cards_first? = last_action in [:take_from_deck, :take_from_table]

    assign(socket,
      game_state: game.state,
      table_card_0: table_card_0,
      table_card_1: table_card_1,
      players: players,
      last_event: last_event,
      last_action: last_action,
      last_event_pos: last_event_pos,
      playable_cards: playable_cards,
      can_start_game?: can_start_game?,
      draw_table_cards_first?: draw_table_cards_first?
    )
  end

  @impl true
  def handle_info({:load_game, game_id}, socket) do
    if pid = GameServer.lookup_game_pid(game_id) do
      {:ok, game, chat_messages} = GameServer.fetch_state(pid)

      socket =
        socket
        |> assign_game_data(game)
        |> assign(:chat_messages, chat_messages)

      {:noreply, socket}
    else
      {:noreply, assign(socket, trigger_leave_game?: true)}
    end
  end

  @impl true
  def handle_info({:game_state, game}, socket) do
    {:noreply, assign_game_data(socket, game)}
  end

  @impl true
  def handle_info(:game_inactive, socket) do
    {:noreply, assign(socket, trigger_leave_game?: true)}
  end

  @impl true
  def handle_event("start_game", _value, socket) do
    %{current_user: user, game_id: game_id} = socket.assigns
    GameServer.start_game(game_id, user.id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("deck_click", value, socket) do
    if Map.has_key?(value, "playable") do
      %{current_user: user, game_id: game_id} = socket.assigns
      event = Game.Event.new(:take_from_deck, user.id)
      GameServer.handle_game_event(game_id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("table_click", value, socket) do
    if Map.has_key?(value, "playable") do
      %{current_user: user, game_id: game_id} = socket.assigns
      event = Game.Event.new(:take_from_table, user.id)
      GameServer.handle_game_event(game_id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("hand_click", value, socket) do
    %{current_user: user, playable_cards: playable_cards} = socket.assigns
    player_id = String.to_integer(value["player-id"])
    index = String.to_integer(value["index"])
    card = String.to_existing_atom("hand_#{index}")

    if user.id == player_id and card in playable_cards do
      %{game_id: game_id, game_state: game_state} = socket.assigns

      case game_state do
        s when s in [:flip_two, :flip] ->
          unless Map.has_key?(value, "face-up") do
            event = Game.Event.new(:flip, player_id, %{index: index})
            GameServer.handle_game_event(game_id, event)
          end

        :hold ->
          event = Game.Event.new(:swap, player_id, %{index: index})
          GameServer.handle_game_event(game_id, event)
      end
    end

    {:noreply, socket}
  end
end
