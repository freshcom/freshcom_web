defmodule FreshcomWeb.AuthenticationTest do
  use FreshcomWeb.ConnCase

  import Freshcom.{Fixture, Shortcut}

  alias Freshcom.Identity
  alias FreshcomWeb.Authentication

  test "create_access_token/1 given invalid refresh token" do
    input = %{
      "grant_type" => "refresh_token",
      "refresh_token" => UUID.uuid4()
    }

    assert {:error, error} = Authentication.create_access_token(input)
  end

  describe "create_access_token/1 given live urt" do
    test "and no scope" do
      user = standard_user()
      client = standard_app(user.default_account_id)
      urt = get_urt(user.default_account_id, user.id)

      input = %{
        "grant_type" => "refresh_token",
        "client_id" => client.id,
        "refresh_token" => urt.prefixed_id
      }

      assert {:ok, result} = Authentication.create_access_token(input)
      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt.prefixed_id
      assert result.token_type
    end

    test "and scope on test account" do
      user = standard_user(include: "default_account")
      client = system_app()
      live_account_id = user.default_account_id
      test_account_id = user.default_account.test_account_id
      urt_live = get_urt(live_account_id, user.id)
      urt_test = get_urt(test_account_id, user.id)

      input = %{
        "grant_type" => "refresh_token",
        "refresh_token" => urt_live.prefixed_id,
        "client_id" => client.id,
        "scope" => "acc:#{test_account_id}"
      }

      assert {:ok, result} = Authentication.create_access_token(input)
      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt_test.prefixed_id
      assert result.token_type
    end
  end

  test "create_access_token/1 given live prt and no scope" do
    user = standard_user()
    client = standard_app(user.default_account_id)
    prt = get_prt(user.default_account_id)
    input = %{
      "grant_type" => "refresh_token",
      "client_id" => client.id,
      "refresh_token" => prt.prefixed_id
    }

    assert {:ok, result} = Authentication.create_access_token(input)
    assert result.expires_in
    assert result.access_token
    assert result.refresh_token == prt.prefixed_id
    assert result.token_type
  end

  describe "create_access_token/1 given incorrect credentials" do
    test "and no scope" do
      input = %{
        "grant_type" => "password",
        "client_id" => uuid4(),
        "username" => "invalid",
        "password" => "invalid"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end

    test "and scope" do
      input = %{
        "grant_type" => "password",
        "client_id" => uuid4(),
        "username" => "invalid",
        "password" => "invalid",
        "scope" => "acc:#{uuid4()}"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end
  end

  describe "create_access_token/1 given correct standard user credentials" do
    test "and no scope" do
      user = standard_user()
      client = standard_app(user.default_account_id)
      urt = get_urt(user.default_account_id, user.id)
      input = %{
        "grant_type" => "password",
        "client_id" => client.id,
        "username" => user.username,
        "password" => "test1234"
      }

      assert {:ok, result} = Authentication.create_access_token(input)
      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt.prefixed_id
      assert result.token_type
    end

    test "and scope" do
      user = standard_user()
      input = %{
        "grant_type" => "password",
        "client_id" => uuid4(),
        "username" => user.username,
        "password" => "test1234",
        "scope" => "acc:#{user.default_account_id}"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end
  end

  describe "create_access_token/1 given correct managed user credentials" do
    test "and no scope" do
      %{default_account_id: account_id} = standard_user()
      user = managed_user(account_id)

      input = %{
        "grant_type" => "password",
        "client_id" => uuid4(),
        "username" => user.username,
        "password" => "test1234"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end

    test "and invalid scope" do
      %{default_account_id: account_id} = standard_user()
      user = managed_user(account_id)
      %{default_account_id: other_account_id} = standard_user()

      input = %{
        "grant_type" => "password",
        "client_id" => uuid4(),
        "username" => user.username,
        "password" => "test1234",
        "scope" => "acc:#{other_account_id}"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end

    test "and valid scope" do
      %{default_account_id: account_id} = standard_user()
      client = standard_app(account_id)
      user = managed_user(account_id)
      urt = get_urt(account_id, user.id)

      input = %{
        "grant_type" => "password",
        "client_id" => client.id,
        "username" => user.username,
        "password" => "test1234",
        "scope" => "acc:#{account_id}"
      }

      assert {:ok, result} = Authentication.create_access_token(input)
      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt.prefixed_id
      assert result.token_type
    end

    test "and valid scope using account handle" do
      %{default_account_id: account_id} = standard_user()
      client = standard_app(account_id)
      user = managed_user(account_id)
      urt = get_urt(account_id, user.id)

      Identity.update_account_info(%Request{
        _role_: "system",
        account_id: account_id,
        fields: %{"handle" => "test"}
      })

      input = %{
        "grant_type" => "password",
        "client_id" => client.id,
        "username" => user.username,
        "password" => "test1234",
        "scope" => "acc:test"
      }

      assert {:ok, result} = Authentication.create_access_token(input)
      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt.prefixed_id
      assert result.token_type
    end
  end
end
