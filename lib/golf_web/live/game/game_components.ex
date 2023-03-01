defmodule GolfWeb.Game.GameComponents do
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

  def card_image(assigns) do
    class =
      case {assigns[:class]} do
        {nil} -> "card"
        _ -> "card #{assigns[:class]}"
      end

    assigns = assign(assigns, class: class)

    ~H"""
    <image
      class={@class}
      href={"/images/cards/#{@name}.svg"}
      x={@x - card_width() / 2}
      y={@y - card_height() / 2}
      width={@width}
    />
    """
  end

  def deck_x(:not_started), do: 0
  def deck_x(_game_state), do: -@card_width / 2

  attr :game_state, :atom, required: true

  def deck(assigns) do
    class =
      case assigns.game_state do
        :not_started -> "deck deal"
        _ -> "deck"
      end

    assigns = assign(assigns, class: class)

    ~H"""
    <.card_image class={@class} name="2B" x={deck_x(@game_state)} />
    """
  end

  def table_card_x, do: @card_width / 2

  attr :name, :string, required: true

  def table_card_0(assigns) do
    class = "table"
    assigns = assign(assigns, class: class)

    ~H"""
    <.card_image class={@class} name={@name} x={table_card_x()} />
    """
  end

  attr :name, :string, required: true

  def table_card_1(assigns) do
    ~H"""
    <.card_image name={@name} x={table_card_x()} />
    """
  end

  def table_cards(assigns) do
    ~H"""
    <.table_card_1 :if={@table_card_1} name={@table_card_1} />
    <.table_card_0 :if={@table_card_0} name={@table_card_0} />
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

  attr :cards, :list, required: true
  attr :position, :atom, required: true

  def hand(assigns) do
    ~H"""
    <g class={"hand #{@position}"}>
      <%= for {%{card: card, face_up?: face_up?}, index} <- Enum.with_index(@cards) do %>
        <.card_image
          class={"hand #{@position}"}
          name={if face_up?, do: card, else: "2B"}
          x={hand_card_x(index)}
          y={hand_card_y(index)}
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
