defmodule OpencensusPhoenix.Telemetry do
  @moduledoc """
  Phoenix 1.5+ has abandoned instrumenters in favour of publishing `:telemetry` events.
  This module will automatically create spans for Phoenix controllers (including LiveView views and components).

  To use:

  Add `#{__MODULE__}.setup([:my_app, :endpoint])` somewhere when your application is starting up.
  """

  def setup(prefix) do
    %{
      "phoenix endpoint stop" => prefix ++ [:stop],
      "phoenix router_dispatch start" => [:phoenix, :router_dispatch, :start],
      "phoenix live view mount start" => [:phoenix, :live_view, :mount, :start],
      "phoenix live view mount stop" => [:phoenix, :live_view, :mount, :stop],
      "phoenix live view handle_event start" => [:phoenix, :live_view, :handle_event, :start],
      "phoenix live view handle_event stop" => [:phoenix, :live_view, :handle_event, :stop],
      "phoenix live comp handle_event start" => [:phoenix, :live_component, :handle_event, :start],
      "phoenix live comp handle_event stop" => [:phoenix, :live_component, :handle_event, :stop]
    }
    |> Enum.each(fn {name, event} ->
      :ok = :telemetry.attach(name, event, &handle_event/4, nil)
    end)
  end

  def handle_event([:phoenix, :router_dispatch, :start], measurements, meta, _config) do
    route_info =
      case meta do
        %{plug: Phoenix.LiveView.Plug, phoenix_live_view: {module, action}} ->
          "Elixir." <> view = to_string(module)
          %{module: view, action: action, view: view, root_view: view}

        %{plug: module, plug_opts: action} ->
          "Elixir." <> module = to_string(module)
          %{module: module, action: action}
      end

    :ocp.with_child_span("request.#{route_info.module}.#{route_info.action}")

    :ocp.put_attributes(
      Map.merge(route_info, %{
        http_method: meta.conn.method,
        route: meta.route
      })
    )
  end

  def handle_event([:phoenix, :endpoint, :stop], measurements, meta, _config) do
    :ocp.finish_span()
  end

  def handle_event([:phoenix, :live_view, :mount, :start], measurements, meta, _config) do
    "Elixir." <> view = to_string(meta.socket.view)
    "Elixir." <> root_view = to_string(meta.socket.root_view)
    :ocp.with_child_span("live_view.#{view}.mount")

    :ocp.put_attributes(%{
      module: view,
      view: view,
      root_view: root_view,
      action: "mount"
    })
  end

  def handle_event([:phoenix, :live_view, :mount, :stop], measurements, meta, _config) do
    :ocp.finish_span()
  end

  def handle_event([:phoenix, :live_view, :handle_event, :start], measurements, meta, _config) do
    "Elixir." <> view = to_string(meta.socket.view)
    "Elixir." <> root_view = to_string(meta.socket.root_view)
    :ocp.with_child_span("live_view.#{view}.handle_event.#{meta.event}")

    :ocp.put_attributes(%{
      module: view,
      view: view,
      root_view: root_view,
      action: "handle_event/#{meta.event}"
    })
  end

  def handle_event([:phoenix, :live_view, :handle_event, :stop], measurements, meta, _config) do
    :ocp.finish_span()
  end

  def handle_event([:phoenix, :live_component, :handle_event, :start], meas, meta, _config) do
    "Elixir." <> component = to_string(meta.component)
    "Elixir." <> view = to_string(meta.socket.view)
    "Elixir." <> root_view = to_string(meta.socket.root_view)
    :ocp.with_child_span("live_component.#{component}.handle_event.#{meta.event}")

    :ocp.put_attributes(%{
      component: component,
      module: component,
      view: view,
      root_view: root_view,
      action: "handle_event/#{meta.event}"
    })
  end

  def handle_event([:phoenix, :live_component, :handle_event, :stop], meas, meta, _config) do
    :ocp.finish_span()
  end
end
