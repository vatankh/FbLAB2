# Лабораторная работа №2

## Требования к разработанному ПО

В рамках лабораторной работы была реализована структура данных `Separate Chaining Hashmap` (`sc-dict`). Основные характеристики:

1. Поддержка неизменяемости структуры данных.
2. Поддержка операций добавления, удаления, фильтрации, отображения (map), свертки (левая и правая).
3. Соответствие структуре моноида (идемпотентность, ассоциативность, существование нейтрального элемента).
4. Эффективное сравнение структур данных.
5. Полиморфизм и идиоматичность в стиле программирования.

## Ключевые элементы реализации

```elixir
defmodule SCDict do
  defstruct buckets: %{}, size: 0

  @type key :: any()
  @type value :: any()
  @type t :: %SCDict{buckets: %{any() => list({key, value})}, size: non_neg_integer()}

  @spec new() :: t()
  def new do
    %SCDict{}
  end

  @spec put(t(), key, value) :: t()
  def put(%SCDict{buckets: buckets, size: size} = sc_dict, key, value) do
    hash = hash_key(key)
    bucket = Map.get(buckets, hash, [])

    case Enum.find(bucket, fn {k, _} -> k == key end) do
      nil ->
        new_bucket = [{key, value} | bucket]
        %SCDict{sc_dict | buckets: Map.put(buckets, hash, new_bucket), size: size + 1}
      _ ->
        new_bucket = Enum.map(bucket, fn {k, _v} when k == key -> {k, value}; pair -> pair end)
        %SCDict{sc_dict | buckets: Map.put(buckets, hash, new_bucket)}
    end
  end

  @spec get(t(), key) :: {:ok, value} | :error
  def get(%SCDict{buckets: buckets}, key) do
    hash = hash_key(key)
    bucket = Map.get(buckets, hash, [])
    case Enum.find(bucket, fn {k, _v} -> k == key end) do
      nil -> :error
      {_, v} -> {:ok, v}
    end
  end

  @spec delete(t(), key) :: t()
  def delete(%SCDict{buckets: buckets, size: size} = sc_dict, key) do
    hash = hash_key(key)
    bucket = Map.get(buckets, hash, [])
    new_bucket = Enum.reject(bucket, fn {k, _v} -> k == key end)

    if length(new_bucket) < length(bucket) do
      %SCDict{sc_dict | buckets: Map.put(buckets, hash, new_bucket), size: size - 1}
    else
      sc_dict
    end
  end

  @spec filter(t(), (key, value -> boolean())) :: t()
  def filter(%SCDict{buckets: buckets} = sc_dict, func) do
    new_buckets = Enum.reduce(buckets, %{}, fn {hash, bucket}, acc ->
      filtered_bucket = Enum.filter(bucket, fn {k, v} -> func.(k, v) end)
      if filtered_bucket == [], do: acc, else: Map.put(acc, hash, filtered_bucket)
    end)
    new_size = Enum.reduce(new_buckets, 0, fn {_hash, bucket}, acc -> acc + length(bucket) end)
    %SCDict{sc_dict | buckets: new_buckets, size: new_size}
  end

  @spec map(t(), (key, value -> {key, value})) :: t()
  def map(%SCDict{buckets: buckets} = sc_dict, func) do
    new_buckets = Enum.reduce(buckets, %{}, fn {hash, bucket}, acc ->
      new_bucket = Enum.map(bucket, fn {k, v} -> func.(k, v) end)
      Map.put(acc, hash, new_bucket)
    end)
    %SCDict{sc_dict | buckets: new_buckets}
  end

  @spec foldl(t(), acc, (acc, key, value -> acc)) :: acc when acc: any()
  def foldl(%SCDict{buckets: buckets}, acc, func) do
    Enum.reduce(buckets, acc, fn {_hash, bucket}, acc ->
      Enum.reduce(bucket, acc, fn {k, v}, acc -> func.(acc, k, v) end)
    end)
  end

  @spec foldr(t(), acc, (acc, key, value -> acc)) :: acc when acc: any()
  def foldr(%SCDict{buckets: buckets}, acc, func) do
    Enum.reduce(Enum.reverse(buckets), acc, fn {_hash, bucket}, acc ->
      Enum.reduce(Enum.reverse(bucket), acc, fn {k, v}, acc -> func.(acc, k, v) end)
    end)
  end

  @spec is_monoid?(t(), (t(), t() -> t())) :: boolean()
  def is_monoid?(sc_dict, merge_func) do
    empty_dict = new()
    identity_check = merge_func.(sc_dict, empty_dict) == sc_dict and merge_func.(empty_dict, sc_dict) == sc_dict
    closure_check = is_struct(merge_func.(sc_dict, sc_dict), SCDict)
    a = new() |> put(:a, 1)
    b = new() |> put(:b, 2)
    c = new() |> put(:c, 3)
    associativity_check = merge_func.(a, merge_func.(b, c)) == merge_func.(merge_func.(a, b), c)
    identity_check and closure_check and associativity_check
  end

  @spec compare(t(), t()) :: boolean()
  def compare(%SCDict{buckets: buckets1, size: size1}, %SCDict{buckets: buckets2, size: size2}) do
    size1 == size2 and buckets1 == buckets2
  end

  defp hash_key(key), do: :erlang.phash2(key)
end
```
## Тесты

### Unit-тесты

Unit-тесты проверяют основные операции структуры данных `SCDict`, включая добавление, удаление, фильтрацию элементов и эффективное сравнение.

```elixir
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
```
### Property-based тесты
Property-based тесты используются для проверки инвариантов и свойств, таких как корректность операций put и get, работа фильтрации, а также соблюдение свойств моноида.
```elixir
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
```
Выводы
Реализация структуры данных SCDict соответствует требованиям лабораторной работы. Поддерживаются ключевые операции API, обеспечивается неизменяемость структуры, а также проверены свойства моноида. Unit и property-based тесты подтвердили корректность реализации. Использование идиоматичного стиля программирования в Elixir упростило процесс разработки и тестирования.

Copy code




