# Chassis for Clojerl

Fast HTML5 templating in Clojerl.

Renders [Hiccup](https://github.com/weavejester/hiccup/) style HTML vectors to strings on the Erlang VM.

This port retains the portable Chassis rendering API and documentation. JVM compiler internals, Java writer APIs, and JVM benchmark claims are intentionally excluded.

* See [Runtime Compaction](#runtime-compaction).
* See [Project and REPL Setup](docs/projects.md).
* See the [Cowboy and Tailwind Example](examples/cowboy/).
* See the [original JVM project](https://github.com/onionpancakes/chassis).

# Status

[![Run tests](https://github.com/antlobach/chassis-clojerl/actions/workflows/run_tests.yml/badge.svg)](https://github.com/antlobach/chassis-clojerl/actions/workflows/run_tests.yml)

Tested with Clojerl `0.9.1` on Erlang/OTP 27 and 28.

# Deps

Until a package release is available, use sibling Clojerl and Chassis checkouts:

```sh
git clone --branch 0.9.1 --depth 1 https://github.com/antlobach/clojerl.git
git clone https://github.com/antlobach/chassis-clojerl.git
make -C clojerl compile
make -C chassis-clojerl test
```

For a Rebar3 project, add path dependencies adjusted for the checkout layout:

```erlang
{deps, [{clojerl, {path, "../clojerl"}},
        {chassis, {path, "../chassis-clojerl"}}]}.
{plugins, [{rebar3_clojerl, "0.8.8"}]}.
```

# Example

### Runtime HTML Serialization

```clojure
(require '[dev.onionpancakes.chassis.core :as c])

(defn my-post
  [post]
  [:div {:id (:id post)}
   [:h2.title (:title post)]
   [:p.content (:content post)]])

(defn my-blog
  [data]
  [c/doctype-html5 ; Raw string for <!DOCTYPE html>
   [:html
    [:head
     [:link {:href "/css/styles.css" :rel "stylesheet"}]
     [:title "My Blog"]]
    [:body
     [:h1 "My Blog"]
      (for [p (:posts data)]
        (my-post p))]]])

(let [data {:posts [{:id "1" :title "foo" :content "bar"}]}]
  (c/html (my-blog data)))

;; "<!DOCTYPE html><html><head><link href=\"/css/styles.css\" rel=\"stylesheet\"><title>My Blog</title></head><body><h1>My Blog</h1><div id=\"1\"><h2 class=\"title\">foo</h2><p class=\"content\">bar</p></div></body></html>"
```

### Compiled HTML Serialization

```clojure
(require '[dev.onionpancakes.chassis.core :as c])
(require '[dev.onionpancakes.chassis.compiler :as cc])

(defn my-post-compiled
  [post]
  (cc/compile
    [:div {:id (:id post)}
     [:h2.title (:title post)]
     [:p.content (:content post)]]))

(defn my-blog-compiled
  [data]
  (cc/compile
    [c/doctype-html5 ; Raw string for <!DOCTYPE html>
     [:html
      [:head
       [:link {:href "/css/styles.css" :rel "stylesheet"}]
       [:title "My Blog"]]
      [:body
       [:h1 "My Blog"]
        (for [p (:posts data)]
          (my-post-compiled p))]]]))

(let [data {:posts [{:id "1" :title "foo" :content "bar"}]}]
  (c/html (my-blog-compiled data)))

;; "<!DOCTYPE html><html><head><link href=\"/css/styles.css\" rel=\"stylesheet\"><title>My Blog</title></head><body><h1>My Blog</h1><div id=\"1\"><h2 class=\"title\">foo</h2><p class=\"content\">bar</p></div></body></html>"
```

# Usage

Require the namespace.

```clojure
(require '[dev.onionpancakes.chassis.core :as c])
```

## Elements

Use `c/html` function to generate HTML strings from vectors.

Vectors with **global keywords** in the head position are treated as normal HTML elements. The keyword's name is used as the element's tag name.

```clojure
(c/html [:div "foo"])

;; "<div>foo</div>"
```

Maps in the second position are treated as attributes. Use **global keywords** to name attribute keys.

```clojure
(c/html [:div {:id "my-id"} "foo"])

;; "<div id=\"my-id\">foo</div>"
```

```clojure
;; Strings also accepted, but discouraged.
;; Use when keywords cannot encode the desired attribute name.
(c/html [:div {"id" "my-id"} "foo"])

;; "<div id=\"my-id\">foo</div>"
```

The rest of the vector is treated as the element's content. They may be of any type including other elements. Sequences, eductions, and [non-element vectors](#non-element-vectors) are logically flattened with the rest of the content.

```clojure
(c/html [:div {:id "my-id"}
         "foo"
         (for [i (range 3)] i)
         "bar"])

;; "<div id=\"my-id\">foo012bar</div>"
```

## Id and Class Sugar

Like Hiccup, id and class attributes can be specified along with the tag name using css style `#` and `.` syntax.

```clojure
(c/html [:div#my-id.my-class "foo"])

;; "<div id=\"my-id\" class=\"my-class\">foo</div>"
```

```clojure
;; Multiple '.' classes concatenates
(c/html [:div.my-class-1.my-class-2 "foo"])

;; "<div class=\"my-class-1 my-class-2\">foo</div>"
```

```clojure
;; '.' classes concatenates with :class keyword
(c/html [:div.my-class-1 {:class "my-class-2"} "foo"])

;; "<div class=\"my-class-1 my-class-2\">foo</div>"
```


```clojure
;; First '#' determines the id.
;; Extra '#' are uninterpreted.
(c/html [:div## "foo"])

;; "<div id=\"#\">foo</div>"

(c/html [:div#my-id.my-class-1#not-id "foo"])

;; "<div id=\"my-id\" class=\"my-class-1#not-id\">foo</div>"
```

However there are differences from Hiccup.

```clojure
;; '#' id takes precedence over :id keyword
(c/html [:div#my-id {:id "not-my-id"} "foo"])

;; "<div id=\"my-id\">foo</div>"
```

```clojure
;; '#' id can be place anywhere
(c/html [:div.my-class-1#my-id "foo"])

;; "<div id=\"my-id\" class=\"my-class-1\">foo</div>"
```

```clojure
;; '#' id can be place in-between, but don't do this.
;; It will be slightly slower.
(c/html [:div.my-class-1#my-id.my-class-2 "foo"])

;; "<div id=\"my-id\" class=\"my-class-1 my-class-2\">foo</div>"
```

## Boolean Attributes

Use `true`/`false` to toggle boolean attributes.

```clojure
(c/html [:button {:disabled true} "Submit"])

;; "<button disabled>Submit</button>"

(c/html [:button {:disabled false} "Submit"])

;; "<button>Submit</button>"
```

## Composite Attribute Values

Collections of attribute values are concatenated as spaced strings.

```clojure
(c/html [:div {:class ["foo" "bar"]}])

;; "<div class=\"foo bar\"></div>"

(c/html [:div {:class #{:foo :bar}}])

;; "<div class=\"bar foo\"></div>"
```

Maps of attribute values are concatenated as style strings.

```clojure
(c/html [:div {:style {:color  :red
                       :border "1px solid black"}}])

;; "<div style=\"border: 1px solid black; color: red;\"></div>"
```

Attribute collections and maps arbitrarily nest.

```clojure
(c/html [:div {:style {:color  :red
                       :border [:1px :solid :black]}}])

;; "<div style=\"border: 1px solid black; color: red;\"></div>"
```

## Write to an Erlang Writer

Use `c/write-html` to write directly to an `erlang.io.IWriter`. `c/html` uses an `erlang.io.StringWriter` internally.

```clojure
(let [writer (new erlang.io.StringWriter)]
  (c/write-html writer [:div "foo"])
  (str writer))

;; "<div>foo</div>"
```

## Escapes

Text and attribute values are escaped by default.

```clojure
(c/html [:div "& < >"])

;; "<div>&amp; &lt; &gt;</div>"

(c/html [:div {:foo "& < > \" '"}])

;; "<div foo=\"&amp; &lt; &gt; &quot; &apos;\"></div>"
```

Escaping can be disabled locally by wrapping string values with `c/raw`.

```clojure
(c/html [:div (c/raw "<p>foo</p>")])

;; "<div><p>foo</p></div>"
```


### Escaping Other Values

Values without a specialized Chassis implementation are converted with `str` and then escaped. The port does not carry JVM type-specific escaping shortcuts.

### Tags and Attribute Keys Are Not Escaped!

Element tags and attribute keys are not escaped. Be careful when placing dangerous text in these positions.

```clojure
;; uhoh
(c/html [:<> "This is bad!"])

;; "<<>>This is bad!</<>>"

(c/html [:div {:<> "This is bad!"}])

;; "<div <>=\"This is bad!\"></div>"
```

## Non-Element Vectors

Only vectors beginning with keywords are interpreted as elements. Vectors can set their metadata `{::c/content true}` to avoid being interpreted as elements, even if they begin with keywords.

```clojure
;; Not elements
(c/html [0 1 2])                  ; => "012"
(c/html ["foo" "bar"])            ; => "foobar"
(c/html ^::c/content [:foo :bar]) ; => "foobar"

;; Use this to generate fragments of elements
(c/html [[:div "foo"]
         [:div "bar"]]) ; "<div>foo</div><div>bar</div>"
```

## Non-Attribute Keys

Only **global keywords** and **strings** are interpreted as attribute keys. Everything else is ignored.

```clojure
(c/html [:div {:foo/bar "not here!"}])

;; "<div></div>"
```

## Alias Elements

Alias elements are user defined elements. They resolve to other elements through the `c/resolve-alias` multimethod. They must begin with **namespaced keywords**.

Define alias elements by extending `c/resolve-alias` multimethod on a namespaced keyword. It accepts the following 3 arguments of types:

1. Tag keyword. Used for the dispatch.
2. Attributes map or nil if attrs is absent.
3. Content vector, possibly empty if no content.

When implementing aliases, consider the following points:

* Because namespaced keywords are ignored as attributes, they can be used as arguments for alias elements.

* The attributes map will contain `#id` and `.class` merged from the element tag. By placing the alias element's attribute map as the attribute map of a resolved element, the attributes transfers seamlessly between the two.
* The content vector has metadata `{::c/content true}` to avoid being interpreted as an element.

```clojure
;; Capitalized name optional, just to make it distinctive.
(defmethod c/resolve-alias ::Layout
  [_ {:layout/keys [title] :as attrs} content]
  [:div.layout attrs ; Merge attributes
   [:h1 title]
   [:main content]
   [:footer "Some footer message."]])

(c/html [::Layout#blog.dark {:layout/title "My title!"}
         [:p "My content!"]])

;; "<div id=\"blog\" class=\"layout dark\"><h1>My title!</h1><main><p>My content!</p></main><footer>Some footer message.</footer></div>"
```

## Stateful Values

Values implementing `clojerl.IDeref` and functions are automatically dereferenced during serialization. Functions are invoked at zero arity.

Whether this behavior is appropriate depends on the application.

```clojure
(defn current-year [] 2026)

(c/html [:footer "My Company Inc " current-year])

;; "<footer>My Company Inc 2026</footer>"
```

```clojure
(def delayed-thing
  (delay "delayed"))

(c/html [:div {:foo delayed-thing}])

;; "<div foo=\"delayed\"></div>"
```

They can even deference into other elements.

```clojure
(defn get-children []
  [:p "Child element"])

(c/html [:div.parent get-children])

;; "<div class=\"parent\"><p>Child element</p></div>"
```

## Token and HTML Serializers

Use `c/token-serializer` and `c/html-serializer` to access the depth-first token and fragment sequences.

```clojure
(->> (c/token-serializer [:div "foo"])
     (map c/fragment)
     (vec))

;; ["<div>" "foo" "</div>"]
```

```clojure
(->> (c/html-serializer [:div "foo"])
     (vec))

;; ["<div>" "foo" "</div>"]
```

## RawString Constants

### DOCTYPE

Use `c/doctype-html5`, a `RawString` wrapping `<!DOCTYPE html>`. Because it is a `RawString`, it is safe to wrap in a vector to concatenate with the rest of the HTML document.

```clojure
(c/html [c/doctype-html5 [:html "..."]])

;; "<!DOCTYPE html><html>...</html>"
```

### &amp;nbsp;

Use the `c/nbsp` constant.

```clojure
(c/html [:div "foo" c/nbsp "bar"])

;; "<div>foo&nbsp;bar</div>"
```

# Runtime Compaction

Require the compiler namespace:

```clojure
(require '[dev.onionpancakes.chassis.compiler :as cc])
```

Clojerl does not expose the JVM `Compiler$Expr` API used by the original Chassis compiling macros. This port therefore does not reproduce JVM compile-time tree analysis, attribute type hints, macro barriers, or compiler-specific performance claims.

`cc/compile` and `cc/compile*` keep the public macro names but evaluate and compact the complete node into one `RawString` token at runtime:

```clojure
(c/html (cc/compile [:div "ready"]))

;; "<div>ready</div>"
```

Runtime values are observed before compaction:

```clojure
(def message (atom "ready"))

(c/html (cc/compile [:p message]))

;; "<p>ready</p>"
```

Use `cc/compile-node` and `cc/compile-node*` when the node already exists as a runtime value:

```clojure
(let [node [:section [:h2 "Status"] [:p "ready"]]]
  (c/html (cc/compile-node node)))

;; "<section><h2>Status</h2><p>ready</p></section>"
```

# License

Copyright 2024 Gordon Lin.

Released under the MIT License. See `LICENSE`.

This port preserves the original copyright and MIT permission text. Clojerl, Cowboy, and Tailwind CSS remain external dependencies under their respective licenses.