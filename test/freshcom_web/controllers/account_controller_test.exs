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

  describe "(ListAccount) GET /v1/accounts" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/accounts")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      client = system_app()
      requester = managed_user(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/accounts")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      client = system_app()
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      account(requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/accounts")

      assert response = json_response(conn, 200)
      assert length(response["data"]) == 2
      assert response["meta"]["totalCount"] == 2
      assert response["meta"]["allCount"] == 2
    end
  end

  describe "(CreateAccount) POST /v1/accounts" do
    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      client = system_app()
      requester = managed_user(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/accounts", %{
        "data" => %{
          "type" => "Account",
          "attributes" => %{
            "name" => Faker.Company.name(),
            "defaultLocale" => "en"
          }
        }
      })

      assert json_response(conn, 403)
    end

    test "given valid request", %{conn: conn} do
      requester = standard_user()
      client = system_app()
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/accounts", %{
        "data" => %{
          "type" => "Account",
          "attributes" => %{
            "name" => Faker.Company.name(),
            "defaultLocale" => "zh-CN"
          }
        }
      })

      assert response = json_response(conn, 201)
      assert response["data"]["attributes"]["defaultLocale"] == "zh-CN"
    end
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

  describe "(CloseAccount) DELETE /v1/accounts/:id" do
    test "given no access token", %{conn: conn} do
      conn = delete(conn, "/v1/accounts/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      client = system_app()
      uat = get_uat(account_id, requester.id, client.id)

      account = account(requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/accounts/#{account.id}")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = system_app()
      uat = get_uat(account_id, requester.id, client.id)

      account = account(requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/accounts/#{account.id}")

      assert conn.status == 202
    end
  end
end
