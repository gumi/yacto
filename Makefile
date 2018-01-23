.PHONY: all deps.get test

all: test

TESTS := $(dir $(wildcard test/apps/*/mix.exs))

SCRIPT = \
	$$COMMAND && \
	for dir in $(TESTS); do \
		( \
			cd $$dir && \
			echo "---- `basename $$dir` ----" && \
			$$COMMAND \
		); \
	done

deps.get:
	COMMAND="mix deps.get" && $(SCRIPT)

test:
	COMMAND="mix test" && $(SCRIPT)

format:
	mix format --check-equivalent
