defmodule FreshcomWeb.StockableController do
  use FreshcomWeb, :controller

  alias Freshcom.Goods

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # ListStockable
  def index(conn, _) do
    conn
    |> build_request(:index)
    |> list_and_count(&Goods.list_stockable/1, &Goods.count_stockable/1)
    |> send_response(conn, :index)
  end

  # AddStockable
  def create(conn, %{"data" => %{"type" => "Stockable"}}) do
    conn
    |> build_request(:create)
    |> Goods.add_stockable()
    |> send_response(conn, :create)
  end

  # UpdateStockable
  def update(conn, _) do
    conn
    |> build_request(:update)
    |> Goods.update_stockable()
    |> send_response(conn, :show)
  end

  # RetrieveStockable
  def show(conn, %{"id" => _}) do
    conn
    |> build_request(:show)
    |> Goods.get_stockable()
    |> send_response(conn, :show)
  end

  # DeleteStockable
  def delete(conn, _) do
    conn
    |> build_request(:delete, identifier: ["id"])
    |> Goods.delete_stockable()
    |> send_response(conn, :delete, status: :accepted)
  end
end
