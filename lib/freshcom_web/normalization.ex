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

  def underscore(map, root_key, key) when is_map(map) do
    value =
      map
      |> Map.get(root_key)
      |> Map.get(key)

    if is_binary(value) do
      root_value =
        map
        |> Map.get(root_key)
        |> Map.put(key, underscore(value))

      Map.put(map, root_key, root_value)
    else
      map
    end
  end

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
          acc ++ [%{code: reason, source: error_source(key), meta: Enum.into(meta, %{})}]
        {:error, key, reason} ->
          acc ++ [%{code: reason, source: error_source(key), meta: %{}}]
      end
    end)
  end

  defp error_source(key) do
    %{pointer: "/data/attributes/#{key}"}
  end
end