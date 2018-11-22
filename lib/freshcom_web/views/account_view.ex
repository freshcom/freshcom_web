defmodule FreshcomWeb.AccountView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :name,
    :mode,
    :legal_name,
    :website_url,
    :support_email,
    :tech_email,
    :is_ready_for_live_transaction,
    :default_locale,
    :test_account_id,
    :live_account_id,
    :caption,
    :description,
    :custom_data
  ]

  def type do
    "Account"
  end
end
