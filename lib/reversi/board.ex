defmodule Reversi.Board do

  @directions for(x <- -1..1, y <- -1..1, do: [x, y])|> List.delete([0, 0])
  def directions, do: @directions

  @initial_board for(x <- 0..7, y <- 0..7, do: {{x, y}, :blank}, into: Map.new)
  def initial_board, do: @initial_board

  def new do
    @initial_board
    |> Map.merge(%{{3, 3} => :white})
    |> Map.merge(%{{4, 4} => :white})
    |> Map.merge(%{{3, 4} => :black})
    |> Map.merge(%{{4, 3} => :black})
  end

  def stats(board \\ new()) do
    Enum.reduce(
      board,
      %{black: 0, white: 0, blank: 0},
      fn({_cord, type}, stat) -> Map.update!(stat, type, &(&1 + 1)) end
    )
  end

  def drop_at(board \\ new(), x, y, color) do
    if {x, y} in possible_moves(board, color) do
      Enum.reduce(@directions, board, fn([dx, dy], board) ->
        if is_possible_direction(board, [dx, dy], [x, y], color) do
          for(i <- 1..10, do: [i*dx, i*dy])
          |> Enum.map(fn [dx, dy] -> [x+dx, y+dy] end) # map dx, dy plus cur pos
          |> Enum.filter(&is_in_bounds/1) # filter in bound pos
          |> Enum.split_while(fn [x, y] -> Map.get(board, {x, y}) == flip(color) end)
          |> elem(0)
          |> Enum.reduce(board, fn ([x, y], board) -> Map.merge(board, %{{x, y} => color}) end)
          |> Map.merge(%{{x, y} => color}) # set drop at color
        else
          board # not changed
        end
      end)
    else
      raise "not availalbe position"
    end
  end

  def possible_moves(board \\ new(), color) do
    board
    |> Enum.filter(fn {_, type} -> type == :blank end)
    |> Enum.filter(fn {cord, _} -> is_available(board, Tuple.to_list(cord), color) end)
    |> Enum.map(fn {cord, _} -> cord end)
  end

  def is_available(board \\ new(), cord, color) do
    Enum.reduce(@directions, false, fn([dx, dy], acc) ->
      acc || is_possible_direction(board, [dx, dy], cord, color)
    end)
  end

  defp is_possible_direction(board, [dx, dy], [x, y], color) do
    color_groups = for(i <- 1..10, do: [i*dx, i*dy])
    |> Enum.map(fn [dx, dy] -> [x+dx, y+dy] end) # map dx, dy plus cur pos
    |> Enum.filter(&is_in_bounds/1) # filter in bound pos
    |> Enum.map(fn list -> Map.get(board, List.to_tuple(list)) end) # map to color
    |> Enum.reduce([], fn(cur_color, groups) ->
        ele = List.last(groups)
        if ele == nil || ele != cur_color do
          groups ++ [cur_color]
        else
          groups
        end
      end) # group by color

    opp_color = Enum.at(color_groups, 0)
    my_color = Enum.at(color_groups, 1)

    my_color == color && opp_color == flip(my_color)
  end

  defp is_in_bounds [x, y] do
    0 <= x && x <= 7 && 0 <= y && y <= 7
  end

  defp flip(color) do
    case color do
      :black -> :white
      :white -> :black
      _ -> raise "Wrong color"
    end
  end

end
