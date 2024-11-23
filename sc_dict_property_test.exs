defmodule SCDictPropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  alias SCDict

  property "put followed by get always retrieves the inserted value" do
    check all key <- term(),
          value <- term() do
      dict = SCDict.new() |> SCDict.put(key, value)
      assert {:ok, value} == SCDict.get(dict, key)
    end
  end

  property "filter only keeps elements that satisfy the predicate" do
    check all kv_pairs <- list_of({term(), integer()}) do
      dict =
        Enum.reduce(kv_pairs, SCDict.new(), fn {k, v}, acc ->
          SCDict.put(acc, k, v)
        end)

      even_dict = SCDict.filter(dict, fn _k, v -> rem(v, 2) == 0 end)

      SCDict.foldl(even_dict, true, fn _, _k, v ->
        rem(v, 2) == 0
      end)
    end
  end

  property "empty dictionary acts as monoid identity" do
    check all kv_pairs <- list_of({term(), term()}) do
      dict =
        Enum.reduce(kv_pairs, SCDict.new(), fn {k, v}, acc ->
          SCDict.put(acc, k, v)
        end)

      merge_func = fn d1, d2 ->
        SCDict.foldl(d2, d1, fn acc, k, v -> SCDict.put(acc, k, v) end)
      end

      assert SCDict.is_monoid?(dict, merge_func)
    end
  end
end
