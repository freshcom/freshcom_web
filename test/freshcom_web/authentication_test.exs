defmodule FreshcomWeb.AuthenticationTest do
  use FreshcomWeb.ConnCase

  alias FreshcomWeb.Authentication
  alias Freshcom.Identity

  defp register_user(opts \\ []) do
    req = %Request{
      fields: %{
        name: Faker.Name.name(),
        username: Faker.Internet.user_name(),
        email: Faker.Internet.email(),
        password: "test1234",
        is_term_accepted: true
      },
      include: opts[:include]
    }

    {:ok, %{data: user}} = Identity.register_user(req)

    user
  end

  defp add_user(account_id) do
    req = %Request{
      account_id: account_id,
      fields: %{
        "username" => Faker.Internet.user_name(),
        "role" => "developer",
        "password" => "test1234"
      },
      _role_: "sysdev"
    }

    {:ok, %{data: user}} = Identity.add_user(req)

    user
  end

  defp get_urt(account_id, user_id) do
    req = %Request{
      account_id: account_id,
      identifiers: %{"user_id" => user_id},
      _role_: "system"
    }

    {:ok, %{data: urt}} = Identity.get_refresh_token(req)

    urt
  end

  defp get_prt(account_id) do
    req = %Request{
      account_id: account_id,
      identifiers: %{"user_id" => nil},
      _role_: "system"
    }

    {:ok, %{data: prt}} = Identity.get_refresh_token(req)

    prt
  end

  test "create_access_token/1 given invalid refresh token" do
    input = %{
      "grant_type" => "refresh_token",
      "refresh_token" => UUID.uuid4()
    }

    assert {:error, error} = Authentication.create_access_token(input)
  end

  describe "create_access_token/1 given live urt" do
    test "and no scope" do
      user = register_user()
      urt = get_urt(user.default_account_id, user.id)
      input = %{
        "grant_type" => "refresh_token",
        "refresh_token" => urt.prefixed_id
      }

      assert {:ok, result} = Authentication.create_access_token(input)
      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt.prefixed_id
      assert result.token_type
    end

    test "and scope on test account" do
      user = register_user(include: "default_account")
      live_account_id = user.default_account_id
      test_account_id = user.default_account.test_account_id
      urt_live = get_urt(live_account_id, user.id)
      urt_test = get_urt(test_account_id, user.id)

      input = %{
        "grant_type" => "refresh_token",
        "refresh_token" => urt_live.prefixed_id,
        "scope" => "aid:#{test_account_id}"
      }

      assert {:ok, result} = Authentication.create_access_token(input)
      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt_test.prefixed_id
      assert result.token_type
    end
  end

  test "create_access_token/1 given live prt and no scope" do
    user = register_user()
    prt = get_prt(user.default_account_id)
    input = %{
      "grant_type" => "refresh_token",
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
        "username" => "invalid",
        "password" => "invalid"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end

    test "and scope" do
      input = %{
        "grant_type" => "password",
        "username" => "invalid",
        "password" => "invalid",
        "scope" => "aid:#{uuid4()}"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end
  end

  describe "create_access_token/1 given correct standard user credentials" do
    test "and no scope" do
      user = register_user()
      urt = get_urt(user.default_account_id, user.id)
      input = %{
        "grant_type" => "password",
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
      user = register_user()
      input = %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{user.default_account_id}"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end
  end

  describe "create_access_token/1 given correct managed user credentials" do
    test "and no scope" do
      %{default_account_id: account_id} = register_user()
      user = add_user(account_id)

      input = %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end

    test "and invalid scope" do
      %{default_account_id: account_id} = register_user()
      user = add_user(account_id)
      %{default_account_id: other_account_id} = register_user()

      input = %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{other_account_id}"
      }

      assert {:error, %{error: :invalid_grant}} = Authentication.create_access_token(input)
    end

    test "and valid scope" do
      %{default_account_id: account_id} = register_user()
      user = add_user(account_id)
      urt = get_urt(account_id, user.id)

      input = %{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{account_id}"
      }

      assert {:ok, result} = Authentication.create_access_token(input)
      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt.prefixed_id
      assert result.token_type
    end
  end
end
