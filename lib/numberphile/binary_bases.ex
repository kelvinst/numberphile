defmodule Numberphile.BinaryBases do
  @moduledoc """
  This is inspired by the video:

  - https://www.youtube.com/watch?v=LNS1fabDkeA&t
  """

  @doc """
  Finds the lowest number which can be represented by only `0`s
  and `1`s in all bases until `max_base` starting by `offset`.
  """
  def find(max_base, offset \\ 2) when max_base > 1 do
    offset
    |> Stream.iterate(&(&1 + 1))
    |> Stream.map(&IO.inspect/1)
    |> Enum.find(&(digits_used(&1, max_base) == [0, 1]))
  end

  defp digits_used(number, max_base) do
    2..max_base
    |> Stream.flat_map(&Integer.digits(number, &1))
    |> Stream.uniq()
    |> Enum.sort()
  end
end

