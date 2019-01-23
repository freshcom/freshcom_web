defmodule FreshcomWeb.StockableView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :number,
    :barcode,

    :name,
    :label,
    :print_name,
    :unit_of_measure,
    :specification,

    :variable_weight,
    :weight,
    :weight_unit,

    :storage_type,
    :storage_size,
    :storage_description,
    :stackable,

    :width,
    :length,
    :height,
    :dimension_unit,

    :caption,
    :description,
    :custom_data,

    :updated_at,
    :inserted_at
  ]

  def type do
    "Stockable"
  end
end
