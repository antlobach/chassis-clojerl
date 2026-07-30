# Clojerl projects

This guide creates a Clojerl 0.9.1 project, opens its REPL, and runs the Chassis Cowboy example on Erlang/OTP 28.

## Requirements

Install Erlang/OTP 28 and Rebar3 3.27 or newer. Clojerl 0.9.1 lives in the OTP 28-compatible fork:

```sh
git clone --branch 0.9.1 --depth 1 \
  https://github.com/antlobach/clojerl.git ../clojerl
make -C ../clojerl compile
```

Confirm the runtime:

```sh
../clojerl/bin/clojerl -v
```

Expected version lines:

```text
Erlang/OTP 28
Clojerl 0.9.1
```

## Create a project

Create the source directories:

```sh
mkdir -p hello-clojerl/src/hello
cd hello-clojerl
```

Add `rebar.config`:

```erlang
{deps,
 [{clojerl,
   {git, "https://github.com/antlobach/clojerl.git", {tag, "0.9.1"}}}]}.

{plugins, [{rebar3_clojerl, "0.8.8"}]}.
```

Add `src/hello_clojerl.app.src`:

```erlang
{application, hello_clojerl,
 [{vsn, "0.1.0"},
  {description, "Small Clojerl project"},
  {modules, []},
  {applications, [kernel, stdlib, clojerl]}]}.
```

Add `src/hello/core.clje`:

```clojure
(ns hello.core)

(defn greeting [name]
  (str "Hello, " name " from the BEAM"))
```

Compile it:

```sh
rebar3 clojerl compile
```

## Start the REPL

Run the project-aware REPL from the project root:

```sh
rebar3 clojerl repl
```

Load the namespace and call it:

```clojure
clje.user=> (require '[hello.core :as hello])
nil
clje.user=> (hello/greeting "Clojerl")
"Hello, Clojerl from the BEAM"
```

Definitions can be replaced without restarting the VM:

```clojure
clje.user=> (in-ns 'hello.core)
#object[clojerl.Namespace hello.core]
hello.core=> (defn greeting [name] (str "Welcome, " name))
#'hello.core/greeting
hello.core=> (greeting "BEAM")
"Welcome, BEAM"
```

## Run Chassis with Cowboy

The runnable project in [`examples/cowboy`](../examples/cowboy/) uses:

- Clojerl 0.9.1 on OTP 28
- Chassis for server-rendered HTML
- Cowboy 2.13 for HTTP
- Tailwind CSS Play CDN for the example page

Compile the example from the Chassis repository:

```sh
cd examples/cowboy
rebar3 clojerl compile
```

Start its REPL:

```sh
rebar3 clojerl repl
```

Start the OTP application:

```clojure
clje.user=> (application/ensure_all_started :chassis_cowboy)
#erl[:ok #erl(:ranch :cowlib :cowboy :clojerl :chassis :chassis_cowboy)]
```

Open [http://localhost:8080](http://localhost:8080), or request it from another terminal:

```sh
curl -i http://localhost:8080/
```

Stop the application before leaving the REPL:

```clojure
clje.user=> (application/stop :chassis_cowboy)
:ok
```

The handler at `examples/cowboy/src/chassis_cowboy/handler.clje` builds the full page as Chassis vectors. Cowboy sends the string returned by `chassis/html` with a `text/html; charset=utf-8` response header.

The Tailwind Play CDN removes the asset-build step from this example. Tailwind documents it as a development tool; production applications should compile a static stylesheet with the Tailwind CLI, PostCSS, or a framework integration.
