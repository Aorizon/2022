.PHONY: clean dataset lint requirements sync_data_to_s3 sync_data_from_s3

#################################################################################
# GLOBALS                                                                       #
#################################################################################

# Please note.  SHELL here actually has been set for clarity - not as a directive.
# It seems like on windows, the SHELL assignment is ignored.  Also $(SHELL) doesn't
# return the shell being used in the makefile.
# If you assign SHELL = sh.exe but run the makefile from cmd
# then the makefile will use cmd.exe and not sh.exe which is baffling.
# If you do not assign the shell, (and you have sh.exe on your computer - e.g. git)
# then which_shell returns sh.exe but still uses cmd.exe
# https://www.avrfreaks.net/forum/makefiles-windows-pathnames-cmdexe-vs-shexe
# https://stackoverflow.com/a/51699562
SHELL = cmd.exe

# expansion of PROJECT_DIR $(shell) function is not working.
#PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUCKET = s3://url.here
PROFILE = aws_profile_here
PROJECT_NAME = maintai
PYTHON_INTERPRETER = python

#################################################################################
# COMMANDS                                                                      #
#################################################################################

# Use to quickly get the value of a variable
# https://blog.jgc.org/2015/04/the-one-line-you-should-add-to-every.html
# For example, to get the value of a variable called SOURCE_FILES. You'd just type:
# make print-SOURCE_FILES
print-%: ; @echo $*=$($*)

# Windows + makefile = a bad time.
# if you are having trouble with shell commands try reading: 
# http://gnuwin32.sourceforge.net/install.html
which_shell:
	@echo SHELL=$(SHELL)

## Set up the dev environment
## note that .venv has to exist in the folder for pipenv to install the 
## virtualenv in the project folder and not into the user's AppData

create_dev_env:
	@echo ">>> make the .venv folder if it doesn't exist"
	if not exist ".venv" mkdir .venv
	@echo ">>> Installing pipenv if not already installed"
	$(PYTHON_INTERPRETER) -m pip install pipenv
	@echo ">>> Installing pipenv packages"
	pipenv install --dev
	@echo ">>> New virtualenv created in the following location:"
	pipenv --venv

## Test python environment is setup correctly
test_environment:
	$(PYTHON_INTERPRETER) test_environment.py

## Make Dataset
dataset:
	$(PYTHON_INTERPRETER) src/data/make_dataset.py data/raw data/processed

## Delete all compiled Python files

# note - the original line for this is: cd src && for /d /r %i in (*__pycache__*) do @echo rmdir /s "%i"
# however because the makefile has reserved characters we need to escape the %
# Special characters: 
# https://docs.microsoft.com/en-us/cpp/build/reference/special-characters-in-a-makefile?view=msvc-160

clean:
	cd src && for /d /r %%i in (*__pycache__*) do rmdir /s "%%i" /q
	cd tests && for /d /r %%i in (*__pycache__*) do rmdir /s "%%i" /q

# unix command for clean
# clean:
# 	find . -type f -name "*.py[co]" -delete
# 	find . -type d -name "__pycache__" -delete

## Lint using flake8
lint:
	pipenv run flake8 src

## Lint using pydocstyle
doclint:
	pipenv run pydocstyle src

# ## Upload Data to S3
# sync_data_to_s3:
# ifeq (default,$(PROFILE))
# 	aws s3 sync data/ s3://$(BUCKET)/data/
# else
# 	aws s3 sync data/ s3://$(BUCKET)/data/ --profile $(PROFILE)
# endif

# ## Download Data from S3
# sync_data_from_s3:
# ifeq (default,$(PROFILE))
# 	aws s3 sync s3://$(BUCKET)/data/ data/
# else
# 	aws s3 sync s3://$(BUCKET)/data/ data/ --profile $(PROFILE)
# endif

# #################################################################################
# # PROJECT RULES                                                                 #
# #################################################################################

# To generate documentation from src folder run the following command from the **base directory**
# For more options check out: https://www.sphinx-doc.org/en/master/man/sphinx-apidoc.html

# pipenv run sphinx-apidoc --implicit-namespaces -o docs/source src
sphinx_generate:
	pipenv run apidoc

# To build the HTML, enter the `docs` directory in the terminal and run `make html`.
# https://www.gnu.org/software/make/manual/html_node/Recursion.html
sphinx_build: sphinx_generate
	pipenv run html

sphinx_up: sphinx_build
	@echo "visit http://localhost:8000"
	pipenv run startdocs

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

# .DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
# .PHONY: help
# help:
# 	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
# 	@echo
# 	@sed -n -e "/^## / { \
# 		h; \
# 		s/.*//; \
# 		:doc" \
# 		-e "H; \
# 		n; \
# 		s/^## //; \
# 		t doc" \
# 		-e "s/:.*//; \
# 		G; \
# 		s/\\n## /---/; \
# 		s/\\n/ /g; \
# 		p; \
# 	}" ${MAKEFILE_LIST} \
# 	| LC_ALL='C' sort --ignore-case \
# 	| awk -F '---' \
# 		-v ncol=$$(tput cols) \
# 		-v indent=19 \
# 		-v col_on="$$(tput setaf 6)" \
# 		-v col_off="$$(tput sgr0)" \
# 	'{ \
# 		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
# 		n = split($$2, words, " "); \
# 		line_length = ncol - indent; \
# 		for (i = 1; i <= n; i++) { \
# 			line_length -= length(words[i]) + 1; \
# 			if (line_length <= 0) { \
# 				line_length = ncol - indent - length(words[i]) - 1; \
# 				printf "\n%*s ", -indent, " "; \
# 			} \
# 			printf "%s ", words[i]; \
# 		} \
# 		printf "\n"; \
# 	}' \
# 	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
