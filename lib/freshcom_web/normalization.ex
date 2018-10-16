defmodule FreshcomWeb.Normalization do
  def underscore(map, keys) do
    Enum.reduce(map, map, fn({k, v}, acc) ->
      if Enum.member?(keys, k) && acc[k] do
        %{acc | k => Inflex.underscore(v)}
      else
        acc
      end
    end)
  end

  def errors(errors) do
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