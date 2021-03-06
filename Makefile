test:
	tox -e py36

VIM:=$(shell command -v nvim || echo vim)

test_integration:
	tox -e integration

# Fixture generation.
fixtures: tests/fixtures/test_plugin.vim.profile
fixtures: tests/fixtures/test_plugin.nvim.profile
fixtures: tests/fixtures/dict_function.profile
fixtures: tests/fixtures/dict_function_with_same_source.profile
fixtures: tests/fixtures/dict_function_with_continued_lines.profile
fixtures: tests/fixtures/dict_function_used_twice.profile
fixtures: tests/fixtures/continued_lines.profile
fixtures: tests/fixtures/conditional_function.profile

# TODO: cleanup.  Should be handled by the generic rule at the bottom.
tests/fixtures/dict_function.profile: tests/test_plugin/dict_function.vim
	$(VIM) --noplugin -Nu tests/t.vim --cmd 'let g:prof_fname = "$@"' -c 'source $<' -c q
	sed -i 's:^SCRIPT  .*/test_plugin:SCRIPT  /test_plugin:' $@

tests/fixtures/dict_function_with_same_source.profile: test_plugin/dict_function_with_same_source.vim
	$(VIM) --noplugin -Nu tests/t.vim --cmd 'let g:prof_fname = "$@"' -c 'source $<' -c q
	sed -i 's:^SCRIPT  .*/test_plugin:SCRIPT  /test_plugin:' $@

tests/fixtures/test_plugin.vim.profile: test_plugin/autoload/test_plugin.vim
	vim --noplugin -Nu tests/t.vim --cmd 'let g:prof_fname = "$@"' -c q

tests/fixtures/test_plugin.nvim.profile: test_plugin/autoload/test_plugin.vim
	nvim --noplugin -Nu tests/t.vim --cmd 'let g:prof_fname = "$@"' -c q

PROFILES_TO_MERGE:=tests/fixtures/merge-1.profile tests/fixtures/merge-2.profile
$(PROFILES_TO_MERGE): test_plugin/merged_profiles.vim test_plugin/merged_profiles-init.vim Makefile
	$(VIM) -Nu test_plugin/merged_profiles-init.vim -c q
	sed -i 's:^SCRIPT  .*/test_plugin:SCRIPT  /test_plugin:' $(PROFILES_TO_MERGE)

tests/fixtures/%.profile: tests/test_plugin/%.vim
	$(VIM) --noplugin -Nu tests/t.vim --cmd 'let g:prof_fname = "$@"' -c 'source $<' -c q
	sed -i 's:^SCRIPT  .*/test_plugin:SCRIPT  /test_plugin:' $@


# Helpers to generate (combined) coverage and show a diff {{{
#
# Use `make coverage-diff` to diff coverage diff to the old state
# (recorded via `make coverage-save`).

MAIN_COVERAGE:=build/coverage

coverage: $(MAIN_COVERAGE)
	COVERAGE_FILE=$< coverage report -m

coverage-save: | build
	cp -a $(MAIN_COVERAGE) build/coverage.old

coverage-diff: build/covreport.old
coverage-diff: build/covreport.new
coverage-diff:
	@diff --color=always -u $^ | /usr/share/git/diff-highlight/diff-highlight | sed 1,3d
	@#git --no-pager diff --no-index --color-words build/covreport.old build/covreport.new | sed 1,5d
	@# git --no-pager diff --color --no-index build/covreport.old build/covreport.new | sed 1,5d | diff-so-fancy

.PHONY: coverage coverage-save coverage-diff

build/coverage.pytest: $(shell find covimerage tests -name '*.py') | build
	COVERAGE_FILE=$@ tox -e coverage.pytest

$(MAIN_COVERAGE): build/coverage.pytest

build/coverage.old:
	$(MAKE) coverage-save

build/covreport.old: build/coverage.old | build
	COVERAGE_FILE=$< coverage report -m > $@ || { ret=$$?; cat $@; exit $$ret; }

build/covreport.new: $(MAIN_COVERAGE) | build
	COVERAGE_FILE=$< coverage report -m > $@ || { ret=$$?; cat $@; exit $$ret; }
# }}}

build:
	mkdir -p $@
