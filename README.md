# OpencensusPhoenix

[![CircleCI](https://circleci.com/gh/opencensus-beam/opencensus_phoenix.svg?style=svg)](https://circleci.com/gh/opencensus-beam/opencensus_phoenix)
[![CodeCov](https://codecov.io/gh/opencensus-beam/opencensus_phoenix/branch/master/graph/badge.svg)](https://codecov.io/gh/opencensus-beam/opencensus_phoenix)
[![Inline docs](http://inch-ci.org/github/opencensus-beam/opencensus_phoenix.svg)](http://inch-ci.org/github/opencensus-beam/opencensus_phoenix)

[Phoenix instrumenter](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#module-instrumentation) callback module to automatically create [OpenCensus](http://opencensus.io) spans for Phoenix Controller and View information.

Simply configure your Phoenix `Endpoint` to use this library as one of its `instrumenters`:

``` elixir
config :my_app, MyAppWeb.Endpoint,
  # ... existing config ...
  instrumenters: [OpencensusPhoenix.Instrumenter]
```
