defmodule FreshcomWeb.PaginationPlug do
  import Plug.Conn

  @defaults %{number: 1, size: 25}

  def init(_), do: []

  def call(%{query_params: query_params} = conn, _) do
    assign(conn, :pagination, pagination(query_params["page"]))
  end

  defp pagination(%{"number" => number} = raw) do
    number = to_int(number) || @defaults[:number]
    size = to_int(raw["size"]) || @defaults[:size]

    %{number: number, size: size}
  end

  defp pagination(%{"before_id" => before_id} = raw) do
    size = to_int(raw["size"]) || @defaults[:size]
    %{before_id: before_id, size: size}
  end

  defp pagination(%{"after_id" => after_id} = raw) do
    size = to_int(raw["size"]) || @defaults[:size]
    %{after_id: after_id, size: size}
  end

  defp pagination(_), do: @defaults

  defp to_int(i) when is_integer(i), do: i

  defp to_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp to_int(_), do: nil
end
