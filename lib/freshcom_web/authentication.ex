defmodule FreshcomWeb.Authentication do
  @moduledoc false

  import FCSupport.Normalization, only: [atomize_keys: 2]
  alias Freshcom.{Request, Identity, Account}

  use OK.Pipe

  @token_expiry_seconds 3600
  @errors [
    unsupported_grant_type: {:error, %{error: :unsupported_grant_type, error_description: "\"grant_type\" must be one of \"password\" or \"refresh_token\""}},
    invalid_password: {:error, %{error: :invalid_grant, error_description: "Username and password does not match."}},
    invalid_refresh_token: {:error, %{error: :invalid_grant, error_description: "Refresh token is invalid."}},
    invalid_request: {:error, %{error: :invalid_request, error_description: "Your request is missing required parameters or is otherwise malformed."}},
    invalid_client: {:error, %{error: :invalid_client, error_description: "Client is invalid"}}
  ]

  # Publishable Refresh Token
  # %{ user_id: nil, account_id: "test-test-test-test" }

  # User Refresh Token
  # %{ user_id: "test-test-test-test", account_id: "test-test-test-test" }

  # Publishable Access Token
  # %{ exp: 3600, aud: "", prn: "test-test-test-test", typ: "publishable" }

  # User Access Token
  # %{ exp: 3600, aud: "account-id", prn": "user-id", typ: "user" }

  # Request for Publishable Access Token
  # %{ "grant_type" => "refresh_token", "refresh_token" => "publishable-refresh-token" }

  # Request for User Access Token
  # %{ "grant_type" => "password", "username" => "test1@example.com", "password" => "test1234", "scope" => "aid:test-test-test-test" }
  # %{ "grant_type" => "password", "username" => "test1@example.com", "password" => "test1234" }
  # %{ "grant_type" => "refresh_token", "refresh_token" => "user-refresh-token" }

  alias Freshcom.RefreshToken
  alias FreshcomWeb.JWT

  def create_access_token(%{"grant_type" => grant_type}) when grant_type not in ["refresh_token", "password"] do
    @errors[:unsupported_grant_type]
  end

  def create_access_token(%{"grant_type" => "password", "scope" => scope} = fields) do
    scope = deserialize_scope(scope, %{acc: :account})

    fields
    |> atomize_keys([:grant_type, :username, :password, :client_id])
    |> Map.merge(%{scope: scope})
    |> create_access_token()
  end

  def create_access_token(%{"grant_type" => "password"} = fields) do
    fields
    |> atomize_keys([:grant_type, :username, :password, :client_id])
    |> create_access_token()
  end

  def create_access_token(%{"grant_type" => "refresh_token", "scope" => scope} = fields) do
    scope = deserialize_scope(scope, %{acc: :account})

    fields
    |> atomize_keys([:grant_type, :refresh_token, :client_id])
    |> Map.merge(%{scope: scope})
    |> create_access_token()
  end

  def create_access_token(%{"grant_type" => "refresh_token", "refresh_token" => refresh_token, "client_id" => client_id}) do
    create_access_token(%{grant_type: "refresh_token", refresh_token: refresh_token, client_id: client_id})
  end

  def create_access_token(%{refresh_token: rt_id, client_id: client_id, scope: scope}) do
    rt_id
    |> exchange_refresh_token(account_id(scope[:account]))
    ~>> verify_client(client_id)
    ~> to_access_token(client_id)
    |> normalize_result()
  end

  def create_access_token(%{refresh_token: rt_id, client_id: client_id}) do
    rt_id
    |> get_refresh_token()
    ~>> verify_client(client_id)
    ~> to_access_token(client_id)
    |> normalize_result()
  end

  def create_access_token(%{username: username, password: password, client_id: client_id, scope: scope}) do
    get_user(username, password, account_id(scope[:account]))
    ~>> get_refresh_token(account_id(scope[:account]))
    ~>> verify_client(client_id)
    ~> to_access_token(client_id)
    |> normalize_result()
  end

  def create_access_token(%{username: username, password: password, client_id: client_id}) do
    get_user(username, password)
    ~>> get_refresh_token()
    ~>> verify_client(client_id)
    ~> to_access_token(client_id)
    |> normalize_result()
  end

  def create_access_token(_), do: @errors[:invalid_request]

  defp deserialize_scope(scope_string, abr_mappings) do
    scopes = String.split(scope_string, ",")

    Enum.reduce(scopes, %{}, fn scope, acc ->
      with [key, value] <- String.split(scope, ":") do
        raw_key = String.to_atom(key)
        key = abr_mappings[raw_key] || raw_key
        Map.put(acc, key, value)
      else
        _ -> acc
      end
    end)
  end

  defp get_user(username, password) do
    %Request{
      identifiers: %{
        "type" => "standard",
        "username" => username,
        "password" => password
      },
      _role_: "system"
    }
    |> Identity.get_user()
    |> unwrap_response()
    |> password_result()
  end

  defp get_user(_, _, nil), do: {:error, :not_found}

  defp get_user(username, password, account_id) do
    %Request{
      account_id: account_id,
      identifiers: %{
        "type" => "managed",
        "username" => username,
        "password" => password
      },
      _role_: "system"
    }
    |> Identity.get_user()
    |> unwrap_response()
    |> password_result()
  end

  defp get_refresh_token(user, account_id) do
    %Request{
      account_id: account_id,
      identifiers: %{"user_id" => user.id},
      _role_: "system"
    }
    |> Identity.get_refresh_token()
    |> unwrap_response()
    |> refresh_token_result()
  end

  defp get_refresh_token(id) when is_binary(id) do
    %Request{identifiers: %{"id" => id}, _role_: "system"}
    |> Identity.get_refresh_token()
    |> unwrap_response()
    |> refresh_token_result()
  end

  defp get_refresh_token(user) do
    %Request{
      account_id: user.default_account_id,
      identifiers: %{"user_id" => user.id},
      _role_: "system"
    }
    |> Identity.get_refresh_token()
    |> unwrap_response()
    |> refresh_token_result()
  end

  defp exchange_refresh_token(id, account_id) do
    %Request{
      account_id: account_id,
      identifiers: %{"id" => id},
      _role_: "system"
    }
    |> Identity.exchange_refresh_token()
    |> unwrap_response()
    |> refresh_token_result()
  end

  defp refresh_token_result({:error, _}), do: {:error, :invalid_refresh_token}
  defp refresh_token_result(other), do: other

  defp password_result({:error, _}), do: {:error, :invalid_password}
  defp password_result(other), do: other

  defp to_access_token(%RefreshToken{user_id: nil, account_id: aid, prefixed_id: rtid}, client_id) do
    %{
      access_token: JWT.sign_token(%{
        exp: System.system_time(:second) + @token_expiry_seconds,
        cid: client_id,
        aid: aid,
        typ: "publishable"
      }),
      token_type: "bearer",
      expires_in: @token_expiry_seconds,
      refresh_token: rtid
    }
  end

  defp to_access_token(%RefreshToken{user_id: rid, account_id: aid, prefixed_id: rtid}, client_id) do
    %{
      access_token: JWT.sign_token(%{
        exp: System.system_time(:second) + @token_expiry_seconds,
        cid: client_id,
        aid: aid,
        rid: rid,
        typ: "user"
      }),
      token_type: "bearer",
      expires_in: @token_expiry_seconds,
      refresh_token: rtid
    }
  end

  defp unwrap_response({:ok, %{data: data}}), do: {:ok, data}
  defp unwrap_response(other), do: other

  defp normalize_result({:error, error_code}), do: @errors[error_code]
  defp normalize_result(other), do: other

  defp account_id(account_id_or_handle) do
    case UUID.info(Account.bare_id(account_id_or_handle)) do
      {:ok, _} ->
        account_id_or_handle

      {:error, _} ->
        account_handle_to_id(account_id_or_handle)
    end
  end

  defp account_handle_to_id(handle) do
    request = %Request{
      identifiers: %{"handle" => handle},
      _role_: "system"
    }

    case Identity.get_account(request) do
      {:ok, %{data: account}} -> account.id
      {:error, _} -> UUID.uuid4()
    end
  end

  defp get_app(id) do
    request = %Request{
      identifiers: %{"id" => id},
      _role_: "system"
    }

    case Identity.get_app(request) do
      {:ok, %{data: app}} -> {:ok, app}
      other -> other
    end
  end

  defp verify_app(%{type: "system"} = app, _), do: {:ok, app}
  defp verify_app(%{type: "standard", account_id: aid} = app, taid) when aid == taid, do: {:ok, app}
  defp verify_app(_, _), do: {:error, :invalid_app}

  defp verify_client(%{account_id: account_id} = refresh_token, client_id) do
    result =
      client_id
      |> get_app()
      ~>> verify_app(account_id)

    case result do
      {:ok, _} -> {:ok, refresh_token}
      {:error, _} -> {:error, :invalid_client}
    end
  end
end
