# Assignment 7 – Mean, Median, and Mode in Three Paradigms

## Run C

Requires GCC (on Windows: `winget install BrechtSanders.WinLibs.POSIX.UCRT`). From `Assignment_7/C`:

```powershell
gcc -Wall -Wextra -o stats stats.c -lm
./stats
./stats 4 8 15 16 23 42 8
```

## Run OCaml

Requires OCaml 4.08 or newer (on Windows: `winget install OCaml.opam`, then `opam init`).
In a new shell, load the OCaml environment first, then from `Assignment_7/OCaml`:

```powershell
(& opam env) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }
ocamlopt stats.ml -o stats.exe
./stats.exe
./stats.exe 4 8 15 16 23 42 8
```

Or run without compiling: `ocaml stats.ml`.

## Run Python

Requires Python 3.8 or newer. From `Assignment_7/Python`:

```powershell
python stats.py
python stats.py 4 8 15 16 23 42 8
```
