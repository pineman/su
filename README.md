# Sudoku
weekend sudoku solver in ruby

following this invaluable article https://dlbeer.co.nz/articles/sudoku.html

got it to a reasonable performance level

JIT comparison: https://docs.google.com/spreadsheets/d/1dMrGC_XRXFNgZ8VjhWWvtbuD_AwaPJpDolT2Es-6h48/edit?usp=sharing

~~note: YJIT seems to use much more memory and increases over time~~
friendship ended with mjit
now yjit is my best friend

# TODO
* svelte frontend

# IDEAS
* rewrite it in javascript/something faster w/ wasm (rust :eyes:)
* constraint solver? prolog??
* would much rather a scheme or sbcl rewrite tho
