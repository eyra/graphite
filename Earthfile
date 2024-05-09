VERSION 0.7
ARG elixir_version=1.16.1
ARG otp_version=26.2.1
ARG debian_version=bookworm-20231120-slim
FROM hexpm/elixir:$elixir_version-erlang-$otp_version-debian-$debian_version

ci:
  BUILD +lint
  BUILD +test

lint:
  FROM +lint-setup
  COPY --dir config lib priv test ./
  COPY .formatter.exs ./
  RUN mix format --check-formatted
  RUN mix sobelow
  RUN mix xref graph --format cycles --fail-above 76
  COPY .credo.exs ./
  RUN mix credo
  RUN mix dialyzer

test:
  FROM +test-setup
  COPY --dir config lib priv test ./
  RUN MIX_ENV=test mix compile
  RUN mix test

setup-base:
   RUN apt-get update && apt install -y build-essential git && apt-get clean
   ENV ELIXIR_ASSERT_TIMEOUT=10000
   WORKDIR /code
   RUN mix local.rebar --force
   RUN mix local.hex --force
   COPY mix.exs .
   COPY mix.lock .
   RUN mix deps.get

test-setup:
   FROM +setup-base
   ENV MIX_ENV=test
   RUN mix deps.compile

lint-setup:
  FROM +setup-base
  RUN mix deps.compile
  RUN mix dialyzer --plt
