defmodule GExample.Auth do

  defmodule Token do
    use Guardian, otp_app: :graphql_example
    def subject_for_token( %{ id: id }, _claims ) do
      { :ok, to_string( id ) }
    end
    def resource_from_claims( %{ "sub" => sub } ) do
      { :ok, sub }
    end
  end

  defmodule ErrorHandler do
    import Plug.Conn

    def auth_error( conn, { :unauthenticated, reason }, _opts ) do
      conn
      |> send_resp( 401, "Login required #{ inspect( reason ) }" )
      |> halt
    end

    def auth_error( conn, { :invalid_token, reason }, _opts ) do
      conn
      |> send_resp( 401, "Login invalid #{ inspect( reason ) }" )
      |> halt
    end

  end

  defmodule Pipeline do
    @claims %{ typ: "access" }
    use Guardian.Plug.Pipeline,
      otp_app: :graphql_example,
      module: GExample.Auth.Token,
      error_handler: GExample.Auth.ErrorHandler

    plug Guardian.Plug.VerifySession, claims: @claims
    plug Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource, ensure: true
  end

end
