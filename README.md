# Chassis for Clojerl

[![Run tests](https://github.com/antlobach/chassis-clojerl/actions/workflows/run_tests.yml/badge.svg)](https://github.com/antlobach/chassis-clojerl/actions/workflows/run_tests.yml)

Chassis renders Hiccup-style vectors to HTML on the Erlang VM. This port targets Clojerl `0.9.1` and Erlang/OTP 28.

## Setup

Keep the OTP 28-compatible Clojerl checkout next to this repository:

```sh
git clone --branch 0.9.1 --depth 1 https://github.com/antlobach/clojerl.git ../clojerl
make -C ../clojerl compile
make test
```

Override `CLOJERL_ROOT` if the checkout lives elsewhere:

```sh
make CLOJERL_ROOT=/path/to/clojerl test
```

The test command compiles the `.clje` namespaces, runs 469 assertions, and exits nonzero after any failure or error.

## Rendering

```clojure
(require '[dev.onionpancakes.chassis.core :as c])

(defn post-view [post]
  [:article.post {:data-id (:id post)}
   [:h2 (:title post)]
   [:p (:body post)]])

(c/html
  [c/doctype-html5
   [:main#app
    (post-view {:id 7
                :title "Clojerl"
                :body "Runs on OTP 28"})]])

;; <!DOCTYPE html><main id="app"><article class="post" data-id="7"><h2>Clojerl</h2><p>Runs on OTP 28</p></article></main>
```

Chassis escapes text and attribute values. Use `c/raw` only for trusted HTML:

```clojure
(c/html [:p "<unsafe>"])
;; <p>&lt;unsafe&gt;</p>

(c/html [:p (c/raw "<strong>trusted</strong>")])
;; <p><strong>trusted</strong></p>
```

Boolean attributes use their HTML form:

```clojure
(c/html [:button {:disabled true} "Save"])
;; <button disabled>Save</button>
```

Attribute collections join with spaces. Attribute maps render CSS-style declarations:

```clojure
(c/html [:div {:class ["panel" "wide"]
               :style {:color :red}}
         "Content"])
;; <div class="panel wide" style="color: red;">Content</div>
```

## Aliases

Namespaced tag keywords dispatch through `resolve-alias`:

```clojure
(defmethod c/resolve-alias ::panel
  [_ attrs content]
  [:section.panel attrs content])

(c/html [::panel#settings {:class "wide"} "Settings"])
;; <section id="settings" class="panel wide">Settings</section>
```

Chassis passes alias content as a vector marked with `::c/content` metadata. Alias results inherit metadata from the alias element.

## Runtime compaction

`dev.onionpancakes.chassis.compiler/compile` keeps the original API. Clojerl does not expose the JVM `Compiler$Expr` machinery used by upstream Chassis, so this port serializes the evaluated tree into one `RawString` token at runtime. Dynamic bindings, functions, derefs, aliases, and redefinitions observed before the call retain their rendering behavior.

```clojure
(require '[dev.onionpancakes.chassis.compiler :as cc])

(c/html (cc/compile [:div "ready"]))
;; <div>ready</div>
```

## Public entry points

- `c/html` returns a rendered string.
- `c/write-html` writes tokens to an `erlang.io.IWriter`.
- `c/token-serializer` returns the depth-first token sequence.
- `c/html-serializer` returns the corresponding HTML fragments.
- `c/raw`, `c/doctype-html5`, and `c/nbsp` create trusted raw tokens.
- `cc/compile` and `cc/compile*` compact evaluated nodes.

## License

Copyright © 2022–2026 onionpancakes and contributors.

Distributed under the Eclipse Public License 2.0. See `LICENSE`.
