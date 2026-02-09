FROM elixir:1.17-alpine

WORKDIR /app

RUN apk add --no-cache git build-base postgresql-client

COPY mix.exs mix.lock ./
COPY config config

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

COPY lib lib
COPY priv priv
COPY test test

RUN mix compile && mix escript.build

CMD ["sh", "-c", "tail -f /dev/null"]
