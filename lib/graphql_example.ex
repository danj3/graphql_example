defmodule GraphqlExample do

  @app :graphql_example

  def query_test( query, vars \\ %{} ) do
    Absinthe.run(
      query,
      GraphqlExample.Schema,
      variables: vars
    )
  end

  def start( :normal, [] ) do
    Plug.Adapters.Cowboy2.http( __MODULE__, [],
      Application.get_env( @app, :router_opts ) )
  end

  defmodule AuthToken do
    use Guardian, otp_app: :graphql_example
    def subject_for_token( %{ id: id }, _claims ) do
      { :ok, to_string( id ) }
    end
    def resource_from_claims( %{ "sub" => sub } ) do
      { :ok, sub }
    end
  end


  defmodule AuthErrorHandler do
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

  defmodule AuthPipeline do
    @claims %{ typ: "access" }
    use Guardian.Plug.Pipeline,
      otp_app: :graphql_example,
      module: GraphqlExample.AuthToken,
      error_handler: GraphqlExample.AuthErrorHandler

    plug Guardian.Plug.VerifySession, claims: @claims
    plug Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource, ensure: true
  end


  defmodule Types do
    use Absinthe.Schema.Notation

    object :pong do
      field :status, :string
    end

    object :complex_status do
      field :a, :string
      field :b, :string do
	resolve fn parent, args, _ ->
	  IO.inspect( { parent, args } )
	  { :ok, "foo" }
	end
      end
    end

  end

  defmodule Schema do
    use Absinthe.Schema
    import_types GraphqlExample.Types

    query do
      field :ping, :string do
	resolve fn _p, _a, _i -> {:ok, "pong" } end
      end

      field :s1, :complex_status do
	arg :in1, :string
	resolve fn  parent, args, _  ->
	  IO.inspect( { :top, parent, args, self() } )
	  { :ok, %{ a: args[:in1] } }
	end
      end
    end

    mutation do
    end
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

  defmodule Unauth do
    use Plug.Builder

    plug Absinthe.Plug, schema: GraphqlExample.Schema

    def call( %{ path_info: [ "unauth" ] } = conn, opts ) do
      conn
      |> super( opts )
      |> halt
    end
    def call( conn, _opts ), do: conn
  end

  plug :ping

  plug Unauth

  # Below here everything requires authentication
  plug AuthPipeline

  defmodule Auth do
    use Plug.Builder
    plug Absinthe.Plug, schema: GraphqlExample.Schema

    def call( %{ path_info: [ "auth" ] } = conn, opts ) do
      conn
      |> super( opts )
      |> halt
    end
    def call( conn, _opts ), do: conn
  end

  plug Auth

  def bearer_get do
    { :ok, token, _claims } = AuthToken.encode_and_sign( %{ id: 1 } )
    "Bearer " <> token
  end

  def ping_simple do
    port = Application.get_env( @app, :router_opts )[:port]
    HTTPoison.get( "http://localhost:#{ port }/ping",
      [
	{ "Content-Type", "application/json" }
      ] )
  end

  def ping_test do
    port = Application.get_env( @app, :router_opts )[:port]
    HTTPoison.post( "http://localhost:#{ port }/unauth",
      Poison.encode!( %{ query: "query { ping }" } ),
      [
	{ "Content-Type", "application/json" }
      ] )
  end

  def ping_auth_test do
    port = Application.get_env( @app, :router_opts )[:port]
    HTTPoison.post( "http://localhost:#{ port }/auth",
      Poison.encode!( %{ query: "query { ping }" } ),
      [
	{ "Content-Type", "application/json" },
	{ "Authorization", bearer_get() }
      ] )
  end

  def ping_auth_broken_test do
    port = Application.get_env( @app, :router_opts )[:port]
    HTTPoison.post( "http://localhost:#{ port }/auth",
      Poison.encode!( %{ query: "query { ping }" } ),
      [
	{ "Content-Type", "application/json" },
	{ "Authorization", "Bearer abcd" }
      ] )
  end

  def complex_test do
    port = Application.get_env( @app, :router_opts )[:port]
    HTTPoison.post( "http://localhost:#{ port }",
      Poison.encode!( %{ query: """
      query { s1( in1: "foo" ) { a b  } }
      """ } ),
      [
	{ "Content-Type", "application/json" }
      ] )
  end
  def complex_test2 do
    port = Application.get_env( @app, :router_opts )[:port]
    HTTPoison.post( "http://localhost:#{ port }",
      Poison.encode!( %{ query: """
      query { y: s1( in1: "foo" ) { a b  }, z: s1( in1: "bar" ) { a b } }
      """ } ),
      [
	{ "Content-Type", "application/json" }
      ] )
  end
end
