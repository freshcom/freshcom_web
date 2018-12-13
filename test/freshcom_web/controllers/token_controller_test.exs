defmodule FreshcomWeb.TokenControllerTest do
  use FreshcomWeb.ConnCase
  import Freshcom.{Fixture, Shortcut}

  setup do
    conn =
      build_conn()
      |> put_req_header("content-type", "application/x-www-form-urlencoded")

    {:ok, conn: conn}
  end

  describe "(CreateAccessToken) POST /v1/token" do
    test "given invalid grant type", %{conn: conn} do
      conn = post(conn, "/v1/token", %{
        "grant_type" => "lol",
        "client_id" => uuid4(),
        "username" => "invalid",
        "password" => "invalid"
      })

      assert response = json_response(conn, 400)
      assert response["error_description"]
      assert response["error"] == "unsupported_grant_type"
    end

    test "given missing required parameters", %{conn: conn} do
      conn = post(conn, "/v1/token", %{})

      assert response = json_response(conn, 400)
      assert response["error_description"]
      assert response["error"] == "invalid_request"
    end

    test "given valid standard user credentials and no scope", %{conn: conn} do
      user = standard_user()
      client = standard_app(user.default_account_id)
      urt = get_urt(user.default_account_id, user.id)
      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "client_id" => client.id,
        "username" => user.username,
        "password" => "test1234"
      })

      assert response = json_response(conn, 200)
      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"] == urt.prefixed_id
    end

    test "given valid managed user credentials and scope", %{conn: conn} do
      %{default_account_id: account_id} = standard_user()
      user = managed_user(account_id)
      client = standard_app(account_id)
      urt = get_urt(account_id, user.id)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "password",
        "client_id" => client.id,
        "username" => user.username,
        "password" => "test1234",
        "scope" => "acc:#{account_id}"
      })

      assert response = json_response(conn, 200)
      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"] == urt.prefixed_id
    end

    test "given valid refresh token and scope", %{conn: conn} do
      user = standard_user()
      client = standard_app(user.default_account_id)
      urt = get_urt(user.default_account_id, user.id)

      conn = post(conn, "/v1/token", %{
        "grant_type" => "refresh_token",
        "client_id" => client.id,
        "refresh_token" => urt.prefixed_id
      })

      assert response = json_response(conn, 200)
      assert response["access_token"]
      assert response["expires_in"]
      assert response["refresh_token"] == urt.prefixed_id
    end
  end
end
