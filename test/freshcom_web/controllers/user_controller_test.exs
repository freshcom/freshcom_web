defmodule FreshcomWeb.UserControllerTest do
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

  describe "(ListUser) GET /v1/users" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/users")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      client = standard_app(account_id)
      requester = managed_user(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      account_id = requester.default_account_id
      managed_user(account_id)
      managed_user(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users")

      assert response = json_response(conn, 200)
      assert length(response["data"]) == 2
      assert response["meta"]["totalCount"] == 2
      assert response["meta"]["allCount"] == 2
    end
  end

  describe "(RegisterUser) POST /v1/users" do
    test "given no attributes", %{conn: conn} do
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User"
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) > 0
    end

    test "given valid attributes", %{conn: conn} do
      client = system_app()
      email = Faker.Internet.email()

      conn = put_req_header(conn, "authorization", "Bearer #{client.prefixed_id}")
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "name" => Faker.Name.name(),
            "username" => email,
            "email" => email,
            "password" => "test1234",
            "isTermAccepted" => true
          }
        }
      })

      assert body = json_response(conn, 201)
      assert body["data"]["id"]
    end
  end

  describe "(AddUser) POST /v1/users" do
    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      client = standard_app(account_id)
      user = managed_user(account_id)
      uat = get_uat(account_id, user.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "username" => Faker.Internet.user_name(),
            "password" => "test1234",
            "role" => "supportSpecialist"
          }
        }
      })

      assert json_response(conn, 403)
    end

    test "given no attributes", %{conn: conn} do
      user = standard_user()
      client = standard_app(user.default_account_id)
      uat = get_uat(user.default_account_id, user.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User"
        }
      })

      assert json_response(conn, 422)
    end

    test "given valid request", %{conn: conn} do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "username" => Faker.Internet.user_name(),
            "password" => "test1234",
            "role" => "supportSpecialist"
          }
        }
      })

      assert response = json_response(conn, 201)
    end
  end

  describe "(RetrieveCurrentUser) GET /v1/user" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/user")

      assert conn.status == 401
    end

    test "given uat", %{conn: conn} do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/user")

      assert response = json_response(conn, 200)
      assert response["data"]["id"] == requester.id
    end
  end

  describe "(RetrieveUser) GET /v1/users/:id" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/users/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      user = managed_user(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{user.id}")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      client = standard_app(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id, client.id)

      user = managed_user(requester.default_account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{user.id}")

      assert response = json_response(conn, 200)
      assert response["data"]["id"] == user.id
    end
  end

  describe "(UpdateUser) PATCH /v1/users/:id" do
    test "given no access token", %{conn: conn} do
      conn = patch(conn, "/v1/users/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      user = managed_user(account_id)


      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/users/#{user.id}", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "username" => Faker.Internet.user_name()
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

      user = managed_user(account_id)

      new_username = Faker.Internet.user_name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/users/#{user.id}", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "username" => new_username
          }
        }
      })

      assert response = json_response(conn, 200)
      assert response["data"]["attributes"]["username"] == new_username
    end
  end

  describe "(ChangeUserRole) PUT /v1/users/:id/role" do
    test "given no access token", %{conn: conn} do
      conn = put(conn, "/v1/users/#{uuid4()}/role")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      user = managed_user(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = put(conn, "/v1/users/#{user.id}/role", %{
        "data" => %{
          "type" => "Role",
          "attributes" => %{
            "value" => "supportSpecialist"
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
      user = managed_user(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = put(conn, "/v1/users/#{user.id}/role", %{
        "data" => %{
          "type" => "Role",
          "attributes" => %{
            "value" => "supportSpecialist"
          }
        }
      })

      assert response = json_response(conn, 200)
      assert response["data"]["attributes"]["role"] == "supportSpecialist"
    end
  end

  describe "(GeneratePasswordResetToken) POST /v1/password_reset_tokens" do
    test "given empty request", %{conn: conn} do
      conn = post(conn, "/v1/password_reset_tokens", %{})

      assert response = json_response(conn, 404)
    end

    test "given valid request", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      user = managed_user(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/password_reset_tokens?id=#{user.id}", %{
        "data" => %{
          "type" => "PasswordResetToken"
        }
      })

      assert conn.status == 204
    end
  end

  describe "(ChangePassword) PUT /v1/password" do
    test "given no access token", %{conn: conn} do
      conn = put(conn, "/v1/password", %{})

      assert response = json_response(conn, 422)
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)
      user = managed_user(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = put(conn, "/v1/password?id=#{user.id}", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "newPassword" => "test1234"
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

      user = managed_user(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = put(conn, "/v1/password?id=#{user.id}", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "newPassword" => "test1234"
          }
        }
      })

      assert response = json_response(conn, 200)
    end
  end

  describe "(DeleteUser) DELETE /v1/users/:id" do
    test "given no access token", %{conn: conn} do
      conn = delete(conn, "/v1/users/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)

      user = managed_user(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/users/#{user.id}")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = standard_app(account_id)
      uat = get_uat(account_id, requester.id, client.id)
      user = managed_user(account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = delete(conn, "/v1/users/#{user.id}")

      assert conn.status == 204
    end
  end
end
