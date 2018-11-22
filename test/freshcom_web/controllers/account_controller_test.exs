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
      pat = get_pat(requester.default_account_id)

      conn = put_req_header(conn, "authorization", "Bearer #{pat}")
      conn = get(conn, "/v1/account")

      assert response = json_response(conn, 200)
      assert response["data"]["id"] == requester.default_account_id
    end
  end
end
