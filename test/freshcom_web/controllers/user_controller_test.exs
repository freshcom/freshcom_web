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
      requester = managed_user(account_id)
      uat = get_uat(account_id, requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      managed_user(account_id)
      managed_user(account_id)
      uat = get_uat(account_id, requester.id)

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
      email = Faker.Internet.email()
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
      user = managed_user(account_id)
      uat = get_uat(account_id, user.id)

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
      uat = get_uat(user.default_account_id, user.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = post(conn, "/v1/users", %{
        "data" => %{
          "type" => "User"
        }
      })

      assert json_response(conn, 422)
    end

    test "given valid request", %{conn: conn} do
      user = standard_user()
      uat = get_uat(user.default_account_id, user.id)

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
      uat = get_uat(requester.default_account_id, requester.id)

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
      user = managed_user(account_id)
      uat = get_uat(account_id, requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{user.id}")

      assert conn.status == 403
    end

    test "given valid uat", %{conn: conn} do
      requester = standard_user()
      user = managed_user(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/users/#{user.id}")

      assert response = json_response(conn, 200)
      assert response["data"]["id"] == user.id
    end
  end

  describe "(UpdateCurrentUser) PATCH /v1/user" do
    test "given no access token", %{conn: conn} do
      conn = patch(conn, "/v1/user", %{
        "data" => %{
          "type" => "User",
          "attributes" => %{
            "username" => Faker.Internet.user_name()
          }
        }
      })

      assert conn.status == 401
    end

    test "given uat", %{conn: conn} do
      requester = standard_user()
      uat = get_uat(requester.default_account_id, requester.id)

      new_username = Faker.Internet.user_name()
      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/user", %{
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

  describe "(UpdateUser) PATCH /v1/users/:id" do
    test "given no access token", %{conn: conn} do
      conn = patch(conn, "/v1/users/#{uuid4()}")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      user = managed_user(account_id)
      uat = get_uat(account_id, requester.id)

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
      user = managed_user(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id)

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

  describe "(ChangeUserRole) PATCH /v1/users/:id/role" do
    test "given no access token", %{conn: conn} do
      conn = patch(conn, "/v1/users/#{uuid4()}/role")

      assert conn.status == 401
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      user = managed_user(account_id)
      uat = get_uat(account_id, requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/users/#{user.id}/role", %{
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
      user = managed_user(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/users/#{user.id}/role", %{
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

  describe "(ChangePassword) PATCH /v1/password" do
    test "given no access token", %{conn: conn} do
      conn = patch(conn, "/v1/password", %{})

      assert response = json_response(conn, 422)
    end

    test "given unauthorized uat", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      requester = managed_user(account_id)
      user = managed_user(account_id)
      uat = get_uat(account_id, requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/password?id=#{user.id}", %{
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
      user = managed_user(requester.default_account_id)
      uat = get_uat(requester.default_account_id, requester.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = patch(conn, "/v1/password?id=#{user.id}", %{
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

  # # Delete a managed user
  # describe "DELETE /v1/users/:id" do
  #   test "without UAT", %{conn: conn} do
  #     conn = delete(conn, "/v1/users/#{UUID.generate()}")

  #     assert conn.status == 401
  #   end

  #   test "with UAT targeting a standard user", %{conn: conn} do
  #     user1 = standard_user_fixture()
  #     user2 = standard_user_fixture()
  #     uat = get_uat(user1.default_account, user1)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = delete(conn, "/v1/users/#{user2.id}")

  #     # This endpoint should not expose standard user
  #     assert conn.status == 404
  #   end

  #   test "with UAT targeting a managed user", %{conn: conn} do
  #     standard_user = standard_user_fixture()
  #     managed_user = managed_user_fixture(standard_user.default_account)
  #     uat = get_uat(standard_user.default_account, standard_user)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = delete(conn, "/v1/users/#{managed_user.id}")

  #     assert conn.status == 204
  #   end

  #   test "with test UAT targeting a live managed user", %{conn: conn} do
  #     standard_user = standard_user_fixture()
  #     managed_user = managed_user_fixture(standard_user.default_account)
  #     test_account = standard_user.default_account.test_account
  #     uat = get_uat(test_account, standard_user)

  #     conn = put_req_header(conn, "authorization", "Bearer #{uat}")
  #     conn = delete(conn, "/v1/users/#{managed_user.id}")

  #     assert conn.status == 404
  #   end
  # end
end
