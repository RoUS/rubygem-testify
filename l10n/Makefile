all :
	for lang in * ; do \
	    if test -d "$$lang" -a "$$(echo $$lang/*.l10n)" != "$$lang/*.l10n" ; then \
		./mkl10n.pl $(MKL10N_FLAGS) -o $$lang.ldb $$lang/*.l10n ; \
	    fi ; \
	done

clean:
	rm -f *.ldb{,.pag,.dir}

