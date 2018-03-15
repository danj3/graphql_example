defmodule GExample do
  require Logger

  @app :graphql_example

  def start( :normal, [] ) do
    { :ok, listen_pid } = Plug.Adapters.Cowboy2.http( __MODULE__, [],
      Application.get_env( @app, :router_opts ) )
    Logger.info( "GExample.HTTP Listening at #{ inspect( :ranch.get_addr( __MODULE__.HTTP ) ) } " )
    { :ok, listen_pid }
  end

  use Plug.Builder

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [ :urlencoded, :multipart, :json ],
    pass: [ "application/json" ],
    json_decoder: Poison,
    keys: :atoms

  plug Plug.Session,
    store: :cookie,
    key: "_example_key",
    signing_salt: "Zx5k/2sF"

  def ping( %{ path_info: [ "ping" ] } = conn, _opts ) do
    conn
    |> send_resp( 200, "pong" )
    |> halt
  end
  def ping( conn, _opts ), do: conn

  defmodule UnauthPlug do
    use Plug.Builder

    plug Absinthe.Plug, schema: GExample.Schema

    def call( %{ path_info: [ "unauth" ] } = conn, opts ) do
      conn
      |> super( opts )
      |> halt
    end
    def call( conn, _opts ), do: conn
  end

  plug :ping

  plug UnauthPlug

  # Below here everything requires authentication
  plug GExample.Auth.Pipeline

  defmodule AuthPlug do
    use Plug.Builder
    plug Absinthe.Plug, schema: GExample.Schema

    def call( %{ path_info: [ "auth" ] } = conn, opts ) do
      conn
      |> super( opts )
      |> halt
    end
    def call( conn, _opts ), do: conn
  end

  plug AuthPlug

end
