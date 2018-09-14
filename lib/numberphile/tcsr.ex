defmodule Numberphile.TCSR do
  @moduledoc """
  Taneja's Crazy Sequential Representation

  Read Taneja's paper for more details:

  - https://arxiv.org/abs/1302.1479

  Inspired by the videos:

  - https://www.youtube.com/watch?v=-ruC5A9EzzE
  - https://www.youtube.com/watch?v=pasyRUj7UwM
  """

  alias Numberphile.TCSR

  @funcs [
    |: &TCSR.concatenate/2,
    ^: &TCSR.pow/2,
    *: &Kernel.*/2,
    /: &TCSR.divide/2,
    +: &Kernel.+/2,
    -: &Kernel.-/2
  ]
  @precedence Keyword.keys(@funcs)
  @func_length length(@funcs)
  @digits Enum.to_list(1..9)
  @func_list_length length(@digits) - 1
  @max_guess @func_length |> :math.pow(@func_list_length) |> round() |> Kernel.-(1)

  def stream(start) do
    start
    |> Stream.iterate(&(&1 + 1))
    |> Stream.map(&find/1)
  end

  def find(%Range{} = range) do
    count = Enum.count(range)

    range.first
    |> stream()
    |> Stream.with_index()
    |> Stream.map(fn {value, index} ->
      ProgressBar.render(index + 1, count)
      value
    end)
    |> Enum.to_list()
  end

  def find(number, offset \\ 0) do
    (@max_guess - offset)
    |> Stream.iterate(&(&1 - 1))
    |> Stream.take_while(&(&1 >= 0))
    |> Stream.map(fn(guess) ->
      ProgressBar.render(@max_guess - guess, @max_guess, suffix: :count, width: 80)
      guess
    end)
    |> Stream.map(&guess_to_func_list/1)
    |> Stream.map(&build_full_list(&1, @digits))
    |> Stream.flat_map(&all_possible_groups/1)
    |> Enum.find(&matches?(&1, number))
  end

  def matches?(expresssion, number) when is_list(expresssion) do
    solve(expresssion) == {:ok, number}
  end

  def guess_to_func_list(guess) do
    guess
    |> Integer.digits(@func_length)
    |> pad_leading(@func_list_length, 0)
    |> Enum.map(&Enum.at(@precedence, &1))
  end

  def solve(expression) when is_list(expression) do
    try do
      if valid_expression?(expression) do
        solve(expression, @precedence, [])
      else
        {:error, :invalid_expression}
      end
    rescue
      ArithmeticError -> {:error, :number_too_big}
    end
  end

  defp valid_expression?([_]), do: true
  defp valid_expression?([l, :|, r | _]) when is_list(l) or is_list(r), do: false
  defp valid_expression?([_, _ | t]), do: valid_expression?(t)

  defp solve([result], [], []), do: {:ok, result}

  defp solve([expr | tail], precedence, rest) when is_list(expr) do
    with {:ok, result} <- solve(expr) do
      solve([result | tail], precedence, rest)
    end
  end

  defp solve([last], precedence, rest) do
    solve([], precedence, [last | rest])
  end

  defp solve([], [_ | precedence], rest) do
    rest
    |> Enum.reverse()
    |> solve(precedence, [])
  end

  defp solve([left, operator, right | tail], [operator | _] = precedence, rest) do
    func = Keyword.get(@funcs, operator)
    solve([func.(left, right) | tail], precedence, rest)
  end

  defp solve([left, operator | tail], precedence, rest) do
    solve(tail, precedence, [operator, left | rest])
  end

  defp pad_leading(list, count, pad_with) when length(list) < count do
    zeros_to_add = count - length(list)

    fn -> pad_with end
    |> Stream.repeatedly()
    |> Enum.take(zeros_to_add)
    |> Kernel.++(list)
  end

  defp pad_leading(list, _, _), do: list

  def concatenate(left, right), do: String.to_integer("#{left}#{right}")

  def build_full_list(funcs, digits), do: merge_lists(funcs, digits, [])

  defp merge_lists([], [], acc), do: Enum.reverse(acc)
  defp merge_lists([fh | ft], [dh | dt], acc), do: merge_lists(ft, dt, [fh, dh | acc])
  defp merge_lists([], [dh | dt], acc), do: merge_lists([], dt, [dh | acc])

  def pow(left, right), do: left |> :math.pow(right) |> round()

  def divide(left, right) do
    result = left / right

    if result == round(result) do
      round(result)
    else
      result
    end
  end

  def all_possible_groups(expr) do
    count = Enum.count(expr)

    result =
      3
      |> Stream.iterate(&(&1 + 2))
      |> Stream.take_while(&(&1 <= count - 2))
      |> Enum.flat_map(&possible_groups(expr, &1))

    [expr | result]
  end

  def possible_groups(expr, size) do
    count = Enum.count(expr)

    0
    |> Stream.iterate(&(&1 + 2))
    |> Stream.take_while(&(&1 <= count - size))
    |> Stream.map(&group(expr, &1, size))
    |> Enum.filter(&valid_expression?/1)
  end

  def group(digits, start, size) when is_list(digits) do
    group(digits, start, size, [], [])
  end

  def group(digits, start, size) do
    digits
    |> Enum.to_list()
    |> group(start, size)
  end

  def group([], 0, 0, nil, acc), do: Enum.reverse(acc)
  def group([h | t], 0, 0, nil, acc), do: group(t, 0, 0, nil, [h | acc])
  def group(digits, 0, 0, inside, acc), do: group(digits, 0, 0, nil, [Enum.reverse(inside) | acc])
  def group([h | t], 0, s, inside, acc), do: group(t, 0, s - 1, [h | inside], acc)
  def group([h | t], f, s, inside, acc), do: group(t, f - 1, s, inside, [h | acc])
end
