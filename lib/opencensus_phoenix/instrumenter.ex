defmodule OpencensusPhoenix.Instrumenter do
  @moduledoc """
  Phoenix instrumenter callback module to automatically create spans for
  Phoenix Controller and View information.
  Configure your Phoenix `Endpoint` to use this library as one of its
  `instrumenters`:
  ```elixir
  config :my_app, MyAppWeb.Endpoint,
  # ... existing config ...
  instrumenters: [OpencensusPhoenix.Instrumenter]
  ```
  More details can be found in [the Phoenix documentation].
  [the Phoenix documentation]: https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#module-phoenix-default-events
  """

  @doc false
  def phoenix_controller_call(:start, _compiled_meta, %{conn: conn}) do
    parent_span_ctx =
      Map.get_lazy(conn.private, :opencensus_span_ctx, fn ->
        :oc_propagation_http_tracecontext.from_headers(conn.req_headers)
      end)

    :ocp.with_span_ctx(parent_span_ctx)

    user_agent =
      conn
      |> Plug.Conn.get_req_header("user-agent")
      |> List.first()

    route_info = route_info(conn)

    attributes = %{
      "http.host" => conn.host,
      "http.method" => conn.method,
      "http.path" => conn.request_path,
      "http.user_agent" => user_agent,
      "http.url" => Plug.Conn.request_url(conn),
      "phoenix.controller" => Phoenix.Controller.controller_module(conn),
      "phoenix.action" => Phoenix.Controller.action_name(conn),
      "http.route" => route_info[:route] || ""
    }

    conn
    |> span_name(route_info)
    |> :ocp.with_child_span(attributes)

    span_ctx = :ocp.current_span_ctx()

    :ok = unquote(__MODULE__).set_logger_metadata(span_ctx)

    {span_ctx, parent_span_ctx}
  end

  @doc false
  def phoenix_controller_call(:stop, _time_diff, {span_ctx, parent_span_ctx}) do
    # TODO: instrument a better way so we can set status...
    # {status, msg} = span_status(conn, opts)
    # :oc_trace.set_status(status, msg, span_ctx)

    :oc_trace.finish_span(span_ctx)
    :ocp.with_span_ctx(parent_span_ctx)
  end

  @doc false
  def phoenix_controller_render(:start, _compiled_meta, meta) do
    %{conn: conn, view: view, template: template, format: format} = meta

    parent_span_ctx =
      Map.get_lazy(conn.private, :opencensus_span_ctx, fn ->
        :oc_propagation_http_tracecontext.from_headers(conn.req_headers)
      end)

    attributes = %{
      "phoenix.view" => view,
      "phoenix.template" => template,
      "phoenix.format" => format
    }

    :ocp.with_child_span(view, attributes)
    span_ctx = :ocp.current_span_ctx()

    :ok = unquote(__MODULE__).set_logger_metadata(span_ctx)

    {span_ctx, parent_span_ctx}
  end

  @doc false
  def phoenix_controller_render(:stop, _time_diff, {span_ctx, parent_span_ctx}) do
    :oc_trace.finish_span(span_ctx)
    :ocp.with_span_ctx(parent_span_ctx)
  end

  defp span_name(conn, _) do
    controller_action(conn)
  end

  defp controller_action(conn) do
    controller = Phoenix.Controller.controller_module(conn)
    action = Phoenix.Controller.action_name(conn)
    "#{controller}.#{action}"
  end

  # Version 1.4 or higher
  phoenix_version_supports_route_info? =
    Code.ensure_compiled?(Phoenix.Router) &&
      :erlang.function_exported(Phoenix.Router, :route_info, 4)

  if phoenix_version_supports_route_info? do
    defp span_name(_conn, %{route: route}) do
      route
    end
  else
    defp span_name(conn, _) do
      controller_action(conn)
    end
  end

  if phoenix_version_supports_route_info? do
    defp route_info(%{method: method, request_path: request_path, host: host} = conn) do
      router = conn.private[:phoenix_router]

      Phoenix.Router.route_info(router, method, request_path, host)
    end
  else
    defp route_info(_) do
      nil
    end
  end

  def span_status(conn, _opts),
    do: {:opencensus.http_status_to_trace_status(conn.status), ""}

  ## PRIVATE

  # TODO: Move this to opencensus_elixir so the plug and phoenix apps can share
  require Record

  Record.defrecordp(
    :ctx,
    Record.extract(:span_ctx, from_lib: "opencensus/include/opencensus.hrl")
  )

  @doc false
  def set_logger_metadata(span) do
    trace_id = List.to_string(:io_lib.format("~32.16.0b", [ctx(span, :trace_id)]))
    span_id = List.to_string(:io_lib.format("~16.16.0b", [ctx(span, :span_id)]))

    Logger.metadata(
      trace_id: trace_id,
      span_id: span_id,
      trace_options: ctx(span, :trace_options)
    )

    :ok
  end
end
