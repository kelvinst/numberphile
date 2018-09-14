defmodule Numberphile.TCSRTest do
  use ExUnit.Case
  doctest Numberphile.TCSR

  test "find 10958" do
    assert Numberphile.TCSR.find(10958) == {:error, :not_found}
  end

  test "solve works" do
    assert fn -> :+ end |> Stream.repeatedly() |> Enum.take(8) |> Numberphile.TCSR.solve() ==
             {:ok, 45}

    assert Numberphile.TCSR.solve([:*, :+, :+, :*, :+, :+, :+, :+]) == {:ok, 55}
  end
end
