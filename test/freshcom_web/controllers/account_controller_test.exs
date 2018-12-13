defmodule FreshcomWeb.AccountControllerTest do
  use FreshcomWeb.ConnCase
  import Freshcom.Fixture
  import FreshcomWeb.Shortcut

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  describe "(RetrieveCurrentAccount) GET /v1/account" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/account")

      assert conn.status == 401
    end

    test "given pat", %{conn: conn} do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      pat = get_pat(requester.default_account_id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/account")

      assert response = json_response(conn, 200)
      assert response["data"]["id"] == requester.default_account_id
    end
  end

  describe "(UpdateCurrentAccount) PATCH /v1/account" do
    test "given no access token", %{conn: conn} do
      conn = patch(conn, "/v1/account")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/account", %{
        "data" => %{
          "type" => "Account",
          "attributes" => %{
            "name" => Faker.Company.name()
          }
        }
      })

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      new_name = Faker.Company.name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/account", %{
        "data" => %{
          "type" => "Account",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      assert response = json_response(conn, 200)
      assert response["data"]["attributes"]["name"] == new_name
    end
  end
end
