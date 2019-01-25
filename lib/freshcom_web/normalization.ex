defmodule FreshcomWeb.Normalization do
  def underscore(map, keys) when is_map(map) do
    Enum.reduce(map, map, fn({k, v}, acc) ->
      if Enum.member?(keys, k) && acc[k] do
        %{acc | k => Inflex.underscore(v)}
      else
        acc
      end
    end)
  end

  def underscore(str) when is_binary(str) do
    Inflex.underscore(str)
  end

  @doc """
  Recursively underscore the keys of a given map.
  """
  def underscore_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn({key, value}, acc) ->
      Map.put(acc, underscore(key), underscore_keys(value))
    end)
  end

  def underscore_keys(list) when is_list(list) do
    Enum.map(list, &underscore_keys/1)
  end

  def underscore_keys(item), do: item

  def camelize(str) do
    Inflex.camelize(str, :lower)
  end

  def camelize_keys(map) do
    Enum.reduce(map, %{}, fn({key, value}, acc) ->
      Map.put(acc, camelize(key), value)
    end)
  end

  def to_jsonapi_errors(errors) do
    Enum.reduce(errors, [], fn(error, acc) ->
      case error do
        {:error, key, {reason, meta}} ->
          acc ++ [%{code: camelize(reason), source: error_source(key), meta: Enum.into(meta, %{})}]
        {:error, key, reason} ->
          acc ++ [%{code: camelize(reason), source: error_source(key), meta: %{}}]
      end
    end)
  end

  defp error_source(key) do
    %{pointer: "/data/attributes/#{camelize(key)}"}
  end
end