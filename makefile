Makefile: template.Makefile
	cat $< \
		| vim -eE '+%s/\${\(\d\{1,\}\):\?\([^}]\+\)\?}/\2' \
		'+%print' '+q!' /dev/stdin \
		| tee $@

make.snippets: template.Makefile
	@echo 'snippet Template "Makefile Template"' | tee $@
	sed 's|^|\t|' $< | tee --append $@
