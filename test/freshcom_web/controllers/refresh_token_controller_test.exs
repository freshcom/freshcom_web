defmodule FreshcomWeb.RefreshTokenControllerTest do
  use FreshcomWeb.ConnCase
  import FreshcomWeb.Shortcut

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  describe "(RetrieveRefreshToken) GET /v1/refresh_token" do
    test "given no access token", %{conn: conn} do
      conn = get(conn, "/v1/refresh_token")

      assert conn.status == 401
    end

    test "given valid request", %{conn: conn} do
      requester = standard_user()
      account_id = requester.default_account_id
      client = system_app()
      uat = get_uat(account_id, requester.id, client.id)

      conn = put_req_header(conn, "authorization", "Bearer #{uat}")
      conn = get(conn, "/v1/refresh_token")

      assert response = json_response(conn, 200)
      assert response["data"]["id"]
    end
  end
end
