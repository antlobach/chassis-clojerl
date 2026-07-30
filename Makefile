CLOJERL_ROOT ?= ../clojerl
CLJE := $(CLOJERL_ROOT)/bin/clojerl
EBIN := _build/default/lib/chassis/ebin
TEST_EBIN := _build/test/lib/chassis/test
SOURCES := src/dev/onionpancakes/chassis/core.clje \
           src/dev/onionpancakes/chassis/compiler.clje
TEST_SOURCES := test/dev/onionpancakes/chassis/tests/test_core.clje \
                test/dev/onionpancakes/chassis/tests/test_compiler.clje \
                test/dev/onionpancakes/chassis/tests/test_readme.clje

.PHONY: compile test repl clean

compile:
	mkdir -p $(EBIN)
	$(CLJE) -pa $(EBIN) -o $(EBIN) -c src/dev/onionpancakes/chassis/core.clje
	$(CLJE) -pa $(EBIN) -o $(EBIN) -c src/dev/onionpancakes/chassis/compiler.clje

test: compile
	mkdir -p $(TEST_EBIN)
	$(CLJE) -pa $(EBIN) -pa $(TEST_EBIN) -o $(TEST_EBIN) -c test/dev/onionpancakes/chassis/tests/test_core.clje
	$(CLJE) -pa $(EBIN) -pa $(TEST_EBIN) -o $(TEST_EBIN) -c test/dev/onionpancakes/chassis/tests/test_compiler.clje
	$(CLJE) -pa $(EBIN) -pa $(TEST_EBIN) -o $(TEST_EBIN) -c test/dev/onionpancakes/chassis/tests/test_readme.clje
	$(CLJE) -pa $(EBIN) -pa $(TEST_EBIN) -e '(require (quote dev.onionpancakes.chassis.tests.test-core) (quote dev.onionpancakes.chassis.tests.test-compiler) (quote dev.onionpancakes.chassis.tests.test-readme)) (let [result (clojure.test/run-tests (quote dev.onionpancakes.chassis.tests.test-core) (quote dev.onionpancakes.chassis.tests.test-compiler) (quote dev.onionpancakes.chassis.tests.test-readme))] (when (pos? (+ (:fail result) (:error result))) (erlang/halt 1)))'

repl: compile
	$(CLJE) -pa $(EBIN) -r

clean:
	rm -rf _build
