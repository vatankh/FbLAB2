defmodule SCDictTest do
  use ExUnit.Case
  alias SCDict

  test "adding and retrieving elements" do
    dict = SCDict.new()
    dict = SCDict.put(dict, :a, 1)
    assert {:ok, 1} == SCDict.get(dict, :a)

    dict = SCDict.put(dict, :b, 2)
    assert {:ok, 2} == SCDict.get(dict, :b)
  end

  test "deleting elements" do
    dict = SCDict.new() |> SCDict.put(:a, 1) |> SCDict.put(:b, 2)
    dict = SCDict.delete(dict, :a)

    assert :error == SCDict.get(dict, :a)
    assert {:ok, 2} == SCDict.get(dict, :b)
  end

  test "filtering elements" do
    dict = SCDict.new() |> SCDict.put(:a, 1) |> SCDict.put(:b, 2) |> SCDict.put(:c, 3)
    dict = SCDict.filter(dict, fn _, v -> rem(v, 2) == 0 end)

    assert :error == SCDict.get(dict, :a)
    assert {:ok, 2} == SCDict.get(dict, :b)
    assert :error == SCDict.get(dict, :c)
  end

  test "efficient comparison" do
    dict1 = SCDict.new() |> SCDict.put(:a, 1) |> SCDict.put(:b, 2)
    dict2 = SCDict.new() |> SCDict.put(:a, 1) |> SCDict.put(:b, 2)

    assert SCDict.compare(dict1, dict2)
  end
end
