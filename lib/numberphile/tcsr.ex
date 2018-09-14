defmodule Numberphile.TCSR do
  @funcs [
    |: &Numberphile.concatenate/2,
    ^: &Numberphile.pow/2,
    *: &Kernel.*/2,
    /: &Numberphile.divide/2,
    +: &Kernel.+/2,
    -: &Kernel.-/2
  ]
  @precedence Keyword.keys(@funcs)
  @func_length length(@funcs)
  @digits Enum.to_list(1..9)
  @func_list_length length(@digits) - 1
  @max_guess @func_length |> :math.pow(@func_list_length) |> round() |> Kernel.-(1)

  def find(%Range{} = range) do
    count = Enum.count(range)

    range
    |> Stream.map(&find/1)
    |> Stream.with_index()
    |> Stream.map(fn {value, index} ->
      ProgressBar.render(index + 1, count)
      value
    end)
    |> Enum.to_list()
  end

  def find(number) do
    find(number, solve(@max_guess), @max_guess)
  end

  defp find(_, _, -1), do: {:error, :not_found}

  defp find(number, {:ok, number}, guess), do: {:ok, guess_to_func_list(guess)}

  defp find(number, _wrong_guess, guess) do
    find(number, solve(guess - 1), guess - 1)
  end

  def guess_to_func_list(guess) do
    guess
    |> Integer.digits(@func_length)
    |> pad_leading(@func_list_length, 0)
    |> Enum.map(&Enum.at(@precedence, &1))
  end

  def solve(guess) when is_integer(guess) do
    guess
    |> guess_to_func_list()
    |> solve()
  end

  def solve(func_list) when is_list(func_list) and length(func_list) == @func_list_length do
    try do
      func_list
      |> build_full_list()
      |> solve(@precedence, [])
    rescue
      ArithmeticError -> {:error, :number_too_big}
    end
  end

  def solve(_), do: {:error, :bad_func_list}

  defp solve([result], [], []), do: {:ok, result}

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

  def build_full_list(funcs), do: merge_lists(@digits, funcs, [])

  defp merge_lists([], [], acc), do: Enum.reverse(acc)
  defp merge_lists([dh | dt], [fh | ft], acc), do: merge_lists(dt, ft, [fh, dh | acc])
  defp merge_lists([dh | dt], [], acc), do: merge_lists(dt, [], [dh | acc])

  def pow(left, right), do: left |> :math.pow(right) |> round()

  def divide(left, right) do
    result = left / right

    if result == round(result) do
      round(result)
    else
      result
    end
  end
end
