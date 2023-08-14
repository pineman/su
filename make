#!/bin/sh
cat gen.rb pos.rb sets.rb solver.rb | sed '/require_relative/d' > sudoku.rb
