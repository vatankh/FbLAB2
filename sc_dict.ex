defmodule SCDict do
  @moduledoc """
  Implementation of a Separate Chaining Hashmap in Elixir with efficient comparison.
  """

  defstruct buckets: %{}, size: 0

  @type key :: any()
  @type value :: any()
  @type t :: %SCDict{
               buckets: %{any() => list({key, value})},
               size: non_neg_integer()
             }

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
        new_bucket= [{key, value} | bucket]

        %SCDict{sc_dict |
         buckets: Map.put(buckets, hash, new_bucket), size: size + 1}

      _ ->
        new_bucket = Enum.map(bucket, fn
          {k, _v} when k == key -> {k, value}
          pair -> pair
        end)

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
      %SCDict{
        sc_dict
      | buckets: Map.put(buckets, hash, new_bucket),
        size: size - 1
      }
    else
      sc_dict
    end
  end

  @spec filter(t(), (key, value -> boolean())) :: t()
  def filter(%SCDict{buckets: buckets} = sc_dict, func) do
    new_buckets =
      Enum.reduce(buckets, %{}, fn {hash, bucket}, acc ->
        filtered_bucket = Enum.filter(bucket, fn {k, v} -> func.(k, v) end)
        if filtered_bucket == [], do: acc, else: Map.put(acc, hash, filtered_bucket)
      end)

    new_size = Enum.reduce(new_buckets, 0, fn {_hash, bucket}, acc -> acc + length(bucket) end)

    %SCDict{sc_dict | buckets: new_buckets, size: new_size}
  end

  @spec map(t(), (key, value -> {key, value})) :: t()
  def map(%SCDict{buckets: buckets} = sc_dict, func) do
    new_buckets =
      Enum.reduce(buckets, %{}, fn {hash, bucket}, acc ->
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

    # Check Identity Element
    identity_check = merge_func.(sc_dict, empty_dict) == sc_dict and merge_func.(empty_dict, sc_dict) == sc_dict

    # Check Closure
    closure_check = is_struct(merge_func.(sc_dict, sc_dict), SCDict)

    # Check Associativity
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
