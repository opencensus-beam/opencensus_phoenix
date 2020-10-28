# OpencensusPhoenix

[![CircleCI](https://circleci.com/gh/opencensus-beam/opencensus_phoenix.svg?style=svg)](https://circleci.com/gh/opencensus-beam/opencensus_phoenix)
[![Hex version badge](https://img.shields.io/hexpm/v/opencensus_phoenix.svg)](https://hex.pm/packages/opencensus_phoenix)
## Phoenix 1.5
Phoenix has abandoned instrumenters in 1.5 in favour of the `:telemetry` library.

Simply ensure that the following code runs while your app is starting up (eg, in the `Application.start/2` callback):

```elixir
# lib/my_app_web/endpoint.ex check this file for the event_prefix
defmodule MyAppWeb.Endpoint do
  ...
  plug Plug.Telemetry, event_prefix: [:my_app, :endpoint]
  ...
end

# lib/my_app/application.ex, add this line using event_prefix from above:
def start(_type, _args) do
  ...
  OpencensusPhoenix.Telemetry.setup([:my_app, :endpoint])
  ...
end
```

## Phoenix 1.4
[Phoenix instrumenter](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#module-instrumentation) callback module to automatically create [OpenCensus](http://opencensus.io) spans for Phoenix Controller and View information.

Simply configure your Phoenix `Endpoint` to use this library as one of its `instrumenters`:

``` elixir
config :my_app, MyAppWeb.Endpoint,
  # ... existing config ...
  instrumenters: [OpencensusPhoenix.Instrumenter]
```

# Resource Names

Prior to Phoenix 1.4, the "route info" was not available to plugs. As such instead of using the http route as the resource name, we use the controller + action combination. For example:

* Pre 1.4: `MyApp.Posts.index`
* Version 1.4 or greater: `/posts`
