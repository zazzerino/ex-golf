defmodule GolfWeb.GameComponents do
  use GolfWeb, :html

  @game_width 600
  def game_width, do: @game_width

  @game_height 500
  def game_height, do: @game_height

  @game_viewbox "#{-@game_width / 2}, #{-@game_height / 2}, #{@game_width}, #{@game_height}"
  def game_viewbox, do: @game_viewbox

  @card_width 60
  def card_width, do: @card_width

  @card_height 84
  def card_height, do: @card_height

  @card_scale "10%"
  def card_scale, do: @card_scale

  attr :name, :string, required: true
  attr :class, :string
  attr :x, :integer, default: 0
  attr :y, :integer, default: 0
  attr :width, :string, default: @card_scale
  attr :highlight, :boolean, default: false
  attr :rest, :global

  def card_image(assigns) do
    class =
      case {assigns[:class], assigns[:highlight]} do
        {nil, true} -> "card highlight"
        {nil, _} -> "card"
        {c, true} -> "card #{c} highlight"
        {c, _} -> "card #{c}"
      end

    assigns = assign(assigns, class: class)

    ~H"""
    <image
      class={@class}
      href={"/images/cards/#{@name}.svg"}
      x={@x - card_width() / 2}
      y={@y - card_height() / 2}
      width={@width}
      {@rest}
    />
    """
  end

  def deck_x(:not_started), do: 0
  def deck_x(_game_state), do: -@card_width / 2

  attr :game_state, :atom, required: true
  attr :playable, :boolean, default: false

  def deck(assigns) do
    class =
      case assigns.game_state do
        :not_started -> "deck deal"
        _ -> "deck"
      end

    assigns = assign(assigns, class: class)

    ~H"""
    <.card_image
      class={@class}
      name="2B"
      x={deck_x(@game_state)}
      highlight={@playable}
      phx-value-playable={@playable}
      phx-click="deck_click"
    />
    """
  end

  def table_card_x, do: @card_width / 2

  attr :name, :string, required: true
  attr :playable, :boolean, required: true

  def table_card_0(assigns) do
    class = "table"
    assigns = assign(assigns, class: class)

    ~H"""
    <.card_image
      class={@class}
      name={@name}
      x={table_card_x()}
      highlight={@playable}
      phx-value-playable={@playable}
      phx-click="table_click"
    />
    """
  end

  attr :name, :string, required: true

  def table_card_1(assigns) do
    ~H"""
    <.card_image name={@name} x={table_card_x()} />
    """
  end

  attr :table_card_0, :string, required: true
  attr :table_card_1, :string, required: true
  attr :playable_cards, :list, required: true

  def table_cards(assigns) do
    ~H"""
    <.table_card_1
      :if={@table_card_1}
      name={@table_card_1}
    />

    <.table_card_0
      :if={@table_card_0}
      name={@table_card_0}
      playable={:table in @playable_cards}
    />
    """
  end

  def hand_card_x(index) do
    case index do
      i when i in [0, 3] -> -@card_width
      i when i in [1, 4] -> 0
      i when i in [2, 5] -> @card_width
    end
  end

  def hand_card_y(index) do
    case index do
      i when i in 0..2 -> -@card_height / 2
      _ -> @card_height / 2
    end
  end

  def hand_positions(player_count) do
    case player_count do
      1 -> [:bottom]
      2 -> [:bottom, :top]
      3 -> [:bottom, :left, :right]
      4 -> [:bottom, :left, :top, :right]
    end
  end

  def hand_card_playable?(user_id, player_id, playable_cards, index) do
    if user_id == player_id do
      card = String.to_existing_atom("hand_#{index}")
      card in playable_cards
    end
  end

  attr :cards, :list, required: true
  attr :position, :atom, required: true
  attr :user_id, :integer, required: true
  attr :player_id, :integer, required: true
  attr :playable_cards, :list, required: true

  def hand(assigns) do
    ~H"""
    <g class={"hand #{@position}"}>
      <%= for {%{card: card, face_up?: face_up?}, index} <- Enum.with_index(@cards) do %>
        <.card_image
          class={"hand #{@position}"}
          name={if face_up?, do: card, else: "2B"}
          x={hand_card_x(index)}
          y={hand_card_y(index)}
          highlight={hand_card_playable?(@user_id, @player_id, @playable_cards, index)}
          phx-value-index={index}
          phx-value-player-id={@player_id}
          phx-value-face-up={face_up?}
          phx-click="hand_click"
        />
      <% end %>
    </g>
    """
  end

  attr :name, :string, required: true
  attr :position, :atom, required: true

  def held_card(assigns) do
    ~H"""
    <.card_image class={"held #{assigns.position}"} name={@name} />
    """
  end
end
