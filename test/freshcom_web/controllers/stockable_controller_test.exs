defmodule FreshcomWeb.StockableControllerTest do
  use FreshcomWeb.ConnCase
  import Freshcom.Fixture.Goods
  import FreshcomWeb.Shortcut
  alias Faker.Commerce

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  describe "(ListStockable) GET /v1/stockables" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/stockables")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      client = standard_app(account_id)
      requester = managed_user(account_id, role: "customer")
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/stockables")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      stockable(account_id)
      stockable(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/stockables")

      assert response = json_response(conn, 200)
      assert length(response["data"]) == 2
      assert response["meta"]["totalCount"] == 2
      assert response["meta"]["allCount"] == 2
    end
  end

  describe "(AddStockable) POST /v1/stockables" do
    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      client = standard_app(account_id)
      requester = managed_user(account_id, role: "customer")
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/stockables", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => Commerce.product_name()
          }
        }
      })

      assert json_response(conn, 403)
    end

    test "given no attributes", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/stockables", %{
        "data" => %{
          "type" => "Stockable"
        }
      })

      assert json_response(conn, 422)
    end

    test "given valid request", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/stockables", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => Commerce.product_name()
          }
        }
      })

      assert response = json_response(conn, 201)
    end
  end

  describe "(RetrieveStockable) GET /v1/stockables/:id" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/stockables/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id, role: "customer")
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      stockable = stockable(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/stockables/#{stockable.id}")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      stockable = stockable(requester.default_account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/stockables/#{stockable.id}")

      assert response = json_response(conn, 200)
      assert response["data"]["id"] == stockable.id
    end
  end

  describe "(UpdateStockable) PATCH /v1/stockables/:id" do
    test "given no access token", %{conn: conn} do
      conn = patch(conn, "/v1/stockables/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id, role: "support_specialist")
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      stockable = stockable(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/stockables/#{stockable.id}", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => Commerce.product_name()
          }
        }
      })

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      stockable = stockable(account_id)

      new_name = Commerce.product_name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/stockables/#{stockable.id}", %{
        "data" => %{
          "type" => "Stockable",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      assert response = json_response(conn, 200)
      assert response["data"]["attributes"]["name"] == new_name
    end
  end

  describe "(DeleteStockable) DELETE /v1/stockables/:id" do
    test "given no access token", %{conn: conn} do
      conn = delete(conn, "/v1/stockables/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id, role: "support_specialist")
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      stockable = stockable(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/stockables/#{stockable.id}")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      stockable = stockable(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/stockables/#{stockable.id}")

      assert conn.status == 202
    end
  end
end
