# Prerequires
POSIX shell and POSIX utilities.

# How to build and install
```sh
cd path/to/Parsrs
./CONFIGURE.sh # generates Makefile from Makefile.template
make # builds
make PREFIX=... install # where ... is your desired pseudo root such as /usr/local or "$HOME/.local/"
```
