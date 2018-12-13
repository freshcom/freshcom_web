defmodule FreshcomWeb.Shortcut do
  import Freshcom.Shortcut
  alias FreshcomWeb.Authentication

  def get_uat(account_id, user_id, client_id \\ nil) do
    urt = get_urt(account_id, user_id)

    {:ok, %{access_token: uat}} = Authentication.create_access_token(%{refresh_token: urt.prefixed_id, client_id: client_id})

    uat
  end

  def get_pat(account_id, client_id \\ nil) do
    prt = get_prt(account_id)

    {:ok, %{access_token: pat}} = Authentication.create_access_token(%{refresh_token: prt.prefixed_id, client_id: client_id})

    pat
  end
end