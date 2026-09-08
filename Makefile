.PHONY: help env deps clean lint test coverage security ui-test validate agent-setup agent-resetdb agent-smoke agent-test

VENV_PYTHON=env/bin/python
AGENT_TEST_FILES=$(shell git ls-files 'tests/*.py')
RUFF=env/bin/ruff
BANDIT=env/bin/bandit
PYTEST=$(VENV_PYTHON) -m pytest

help:
	@echo "  env       create development environment"
	@echo "  deps      install dependencies"
	@echo "  clean     remove temporary files"
	@echo "  lint      run Ruff checks"
	@echo "  test      run backend tests"
	@echo "  coverage  run tests with JUnit and coverage reports"
	@echo "  security  run Bandit security scan"
	@echo "  ui-test   run Playwright UI tests"
	@echo "  validate  run all local QA checks"

env:
	python3 -m venv env && \
	. env/bin/activate && \
	make deps

deps:
	$(VENV_PYTHON) -m pip install -r requirements.txt

clean:
	find . | grep -E "(__pycache__|\.pyc|\.DS_Store|\.db|\.pyo$$)" | xargs -r rm -rf

lint:
	$(RUFF) check appname tests

test:
	APPNAME_ENV=test $(PYTEST) -q

coverage:
	mkdir -p reports
	APPNAME_ENV=test $(PYTEST) \
		--junitxml=reports/junit.xml \
		--cov=appname \
		--cov-report=term-missing \
		--cov-report=xml:reports/coverage.xml \
		--cov-report=html:reports/coverage-html \
		-q

security:
	mkdir -p reports
	$(BANDIT) -r appname -f json -o reports/bandit.json
	$(VENV_PYTHON) -c "import json; d=json.load(open('reports/bandit.json')); print('High:', d['metrics']['_totals']['SEVERITY.HIGH']); print('Medium:', d['metrics']['_totals']['SEVERITY.MEDIUM']); print('Low:', d['metrics']['_totals']['SEVERITY.LOW']); print('Issues:', len(d['results']))"

ui-test:
	APPNAME_ENV=dev $(PYTEST) -q tests/ui/

validate: lint coverage security
	@echo "QA validation completed."


agent-setup:
	python3 -m venv env
	$(VENV_PYTHON) -m pip install --upgrade pip
	$(VENV_PYTHON) -m pip install -r requirements.txt

agent-resetdb:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=dev $(VENV_PYTHON) manage.py resetdb

agent-smoke:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=test $(VENV_PYTHON) -m pytest -q tests/test_urls.py tests/test_login.py

agent-test:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=test $(VENV_PYTHON) -m pytest --cov-report=term-missing --cov=appname $(AGENT_TEST_FILES)
