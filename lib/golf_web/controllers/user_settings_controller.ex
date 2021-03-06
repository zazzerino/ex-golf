defmodule GolfWeb.UserSettingsController do
  use GolfWeb, :controller

  alias Golf.Accounts
  alias GolfWeb.UserAuth

  plug :assign_name_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_name"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_name(user, password, user_params) do
      {:ok, _applied_user} ->
        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", name_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_name(conn, %{"token" => token}) do
    case Accounts.update_user_name(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Name changed successfully.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Name change link is invalid or it has expired.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  defp assign_name_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:name_changeset, Accounts.change_user_name(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
