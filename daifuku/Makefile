help:
	@cat Makefile | grep '^\w'
mitamae:
	curl -L https://github.com/itamae-kitchen/mitamae/releases/download/v1.11.7/mitamae-armhf-linux.tar.gz \
		| tar xvz
	mv mitamae* mitamae

dryrun: mitamae
	./mitamae local -n *.rb

apply: mitamae
	./mitamae local *.rb
	
