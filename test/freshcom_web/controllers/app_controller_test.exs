defmodule FreshcomWeb.AppControllerTest do
  use FreshcomWeb.ConnCase
  import FreshcomWeb.Shortcut

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  describe "(ListApp) GET /v1/apps" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/apps")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      client = standard_app(account_id)
      requester = managed_user(account_id, role: "support_specialist")
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/apps")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      client = system_app()
      account_id = requester.default_account_id
      uat = get_uat(account_id, requester.id, client.id)

      standard_app(account_id)
      standard_app(account_id)


      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/apps")

      assert response = json_response(conn, 200)
      assert length(response["data"]) == 3
      assert response["meta"]["totalCount"] == 3
      assert response["meta"]["allCount"] == 3
    end
  end

  describe "(AddApp) POST /v1/apps" do
    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      client = system_app()
      requester = managed_user(account_id, role: "support_specialist")
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/apps", %{
        "data" => %{
          "type" => "App",
          "attributes" => %{
            "name" => Faker.Company.name()
          }
        }
      })

      assert json_response(conn, 403)
    end

    test "given no attributes", %{conn: conn} do
      requester = standard_user()
      client = system_app()
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/apps", %{
        "data" => %{
          "type" => "App"
        }
      })

      assert json_response(conn, 422)
    end

    test "given valid request", %{conn: conn} do
      requester = standard_user()
      client = system_app()
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/apps", %{
        "data" => %{
          "type" => "App",
          "attributes" => %{
            "name" => Faker.Company.name()
          }
        }
      })

      assert response = json_response(conn, 201)
    end
  end

  describe "(UpdateApp) PATCH /v1/apps/:id" do
    test "given no access token", %{conn: conn} do
      conn = patch(conn, "/v1/apps/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id, role: "support_specialist")
      client = system_app()
      uat = get_uat(account_id, requester.id, client.id)

      app = standard_app(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/apps/#{app.id}", %{
        "data" => %{
          "type" => "App",
          "attributes" => %{
            "name" => Faker.Company.name()
          }
        }
      })

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = system_app()
      uat = get_uat(account_id, requester.id, client.id)

      app = standard_app(account_id)

      new_name = Faker.Company.name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/apps/#{app.id}", %{
        "data" => %{
          "type" => "App",
          "attributes" => %{
            "name" => new_name
          }
        }
      })

      assert response = json_response(conn, 200)
      assert response["data"]["attributes"]["name"] == new_name
    end
  end

  describe "(DeleteApp) DELETE /v1/apps/:id" do
    test "given no access token", %{conn: conn} do
      conn = delete(conn, "/v1/apps/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id, role: "support_specialist")
      client = system_app()
      uat = get_uat(account_id, requester.id, client.id)

      app = standard_app(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/apps/#{app.id}")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = system_app()
      uat = get_uat(account_id, requester.id, client.id)

      app = standard_app(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/apps/#{app.id}")

      assert conn.status == 204
    end
  end
end
