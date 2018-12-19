defmodule FreshcomWeb.IdentifierView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  def type(struct, _) do
    Map.get(struct, :type) || Enum.at(Module.split(struct.__struct__), 0)
  end
end
