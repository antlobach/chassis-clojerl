# Chassis Cowboy example

Runnable Clojerl 0.9.1 application that renders a Tailwind-styled page with Chassis and serves it through Cowboy 2.13.

## Run

The repository expects the OTP 28-compatible Clojerl checkout at `../clojerl` relative to the Chassis repository:

```sh
git clone --branch 0.9.1 --depth 1 \
  https://github.com/antlobach/clojerl.git ../clojerl
make -C ../clojerl compile
```

Compile and open the REPL:

```sh
cd examples/cowboy
rebar3 clojerl compile
rebar3 clojerl repl
```

Start the application:

```clojure
(application/ensure_all_started :chassis_cowboy)
```

Visit [http://localhost:8080](http://localhost:8080). Stop it with:

```clojure
(application/stop :chassis_cowboy)
```

## Files

- `src/chassis_cowboy/app.clje` starts Cowboy and defines the route.
- `src/chassis_cowboy/handler.clje` renders the page with Chassis.
- `src/chassis_cowboy/sup.clje` provides the OTP supervisor.

The page loads Tailwind's Play CDN to keep the example self-contained. Use a compiled Tailwind stylesheet in production.
