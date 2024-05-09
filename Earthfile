VERSION 0.8
ARG elixir_version=1.16.1
ARG otp_version=26.2.1
ARG debian_version=bookworm-20231120-slim
FROM hexpm/elixir:$elixir_version-erlang-$otp_version-debian-$debian_version

ci:
  BUILD +lint
  BUILD +test

lint:
  FROM +lint-setup
  COPY --dir lib test ./
  COPY .formatter.exs ./
  RUN mix format --check-formatted
  RUN mix xref graph --format cycles --fail-above 76

test:
  FROM +test-setup
  COPY --dir lib test ./
  RUN git config --global init.defaultBranch "master"
  RUN git config --global user.email "ci@example.com"
  RUN git config --global user.name "CI"
  RUN MIX_ENV=test mix compile
  WITH DOCKER
    RUN mix test
  END

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
