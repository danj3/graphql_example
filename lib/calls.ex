defmodule GExample.Calls do

  @app :graphql_example

  def query_test( query, vars \\ %{} ) do
    Absinthe.run(
      query,
      GExample.Schema,
      variables: vars
    )
  end

  def bearer_get do
    { :ok, token, _claims } =
      GExample.Auth.Token.encode_and_sign( %{ id: 1 } )
    "Bearer " <> token
  end

  def gql_request( doc, method, uri, header_add \\ [] ) do
    port = Application.get_env( @app, :router_opts )[:port]
    HTTPoison.request( method,
      "http://localhost:#{ port }" <> uri,
      Poison.encode!( doc ),
      [
	{ "Content-Type", "application/json; charset=utf-8" }
      ] ++ header_add
    )
    |> result_formatter
  end

  def result_formatter( { :ok, %HTTPoison.Response{ body: body } = r } ) do
    case Poison.decode( body ) do
      { :ok, d } -> { :ok, %{ r | body: d } }
      any -> { :ok, r }
    end
  end

  def ping_simple do
    port = Application.get_env( @app, :router_opts )[:port]
    HTTPoison.get( "http://localhost:#{ port }/ping",
      [
	{ "Content-Type", "application/json" }
      ] )
  end

  def ping_test do
    %{ query: "query { ping }" }
    |> gql_request( :post, "/unauth" )
  end

  def ping_auth_test do
    %{ query: "query { ping }" }
    |> gql_request( :post, "/auth", [
	  { "Authorization", bearer_get() }
	] )
  end

  def ping_auth_broken_test do
    %{ query: "query { ping }" }
    |> gql_request( :post, "/auth", [
	  { "Authorization", "Bearer abcd" }
	] )
  end

  def complex_test do
    %{ query: """
    query { s1( in1: "foo" ) { a b  } }
    """ }
    |> gql_request( :post, "/unauth" )
  end

  def complex_test2 do
    %{ query: """
    query { y: s1( in1: "foo" ) { a b  }, z: s1( in1: "bar" ) { a b } }
    """ }
    |> gql_request( :post, "/unauth" )
  end

  def list_test do
    %{
      query: "query run {
      a: simple_list { x },
      b: simple_list { y }
      }"
    }
    |> gql_request( :post, "/unauth" )
  end
end
