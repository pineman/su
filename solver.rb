require 'benchmark'

Grid = Struct.new(:rows, :cols, :boxes)
Sudoku = Struct.new(:grid, :moves, :bf)

def init_sudoku(rows)
  grid = matrix_to_grid(rows)
  validate_puzzle(grid)
  Sudoku.new(grid, possible_steps(grid), 0)
end

def rc2box(r, c)
  box = r / 3 * 3 + c / 3
  boxi = r % 3 * 3 + c % 3;
  [box, boxi]
end

def rc4box(box)
  start_row = (box / 3) * 3
  start_col = (box % 3) * 3
  (start_row...start_row+3).to_a.product((start_col...start_col+3).to_a)
end

def matrix_to_grid(m)
  cols = (0...9).map { |c| m.map { |row| row[c] } }
  boxes = Array.new(9) { Array.new(9) }
  m.each.with_index { |row, r|
    row.each.with_index { |content, c|
      box, i = rc2box(r, c)
      boxes[box][i] = content;
    }
  }
  Grid.new(m, cols, boxes)
end

def validate_puzzle(grid)
  if (d = grid.rows.find_index { |r| r = r.filter { _1 != 0 }; r.uniq.size != r.size })
    raise "duplicate in row #{d+1}"
  end
  if (d = grid.cols.find_index { |c| c = c.filter { _1 != 0 }; c.uniq.size != c.size })
    raise "duplicate in column #{d+1}"
  end
  if (d = grid.boxes.find_index { |b| b = b.filter { _1 != 0 }; b.uniq.size != b.size })
    raise "duplicate in box #{d+1}"
  end
end

def possible_steps(grid)
  def nums(array)
    array.filter { _1 != 0 }
  end
  grid.rows.map.with_index { |row, r|
    row.map.with_index { |num, c|
      next unless num == 0
      in_row = nums(grid.rows[r])
      in_col = nums(grid.cols[c])
      in_box = nums(grid.boxes[rc2box(r, c).first])
      (1..9).to_a - in_row - in_col - in_box
    }
  }
end

def move(sudoku, row, col, num)
  new = Marshal.load(Marshal.dump(sudoku))
  box, i = rc2box(row, col)

  new.grid.rows[row][col] = num
  new.grid.cols[col][row] = num
  new.grid.boxes[box][i] = num

  new.moves[row][col] = nil
  new.moves[row].each.with_index { |_, i|
    next unless new.moves[row][i]
    new.moves[row][i] -= [num]
  }
  new.moves.each.with_index { |_, i|
    next unless new.moves[i][col]
    new.moves[i][col] -= [num]
  }
  rc4box(rc2box(row, col).first).each { |r, c|
    next unless new.moves[r][c]
    new.moves[r][c] -= [num]
  }

  new
end

def best_moves(moves)
  min, min_r, min_c = 10, nil, nil
  moves.each.with_index { |row, r|
    row.each.with_index { |nums, c|
      next unless nums
      if nums.size < min
        min, min_r, min_c = nums.size, r, c
      end
    }
  }
  [min_r, min_c]
end

def done?(s)
  s.grid.rows.all? { |row| row.all? { |num| num != 0 } }
end

def no_moves?(s)
  s.moves.flatten.compact.empty?
end

# Return rows matrix if solved, false otherwise
def solve_first(s)
  return s if done?(s)
  return false if no_moves?(s)
  row, col = best_moves(s.moves)
  s.bf += (s.moves[row][col].size - 1)**2
  s.moves[row][col].each do |num|
    new = move(s, row, col, num)
    solved = solve_first(new)
    return solved if solved
  end
  false
end

def solve_all(s)
  return [s] if done?(s)
  return [] if no_moves?(s)
  sols = []
  row, col = best_moves(s.moves)
  s.bf += (s.moves[row][col].size - 1)**2
  s.moves[row][col].each do |num|
    new = move(s, row, col, num)
    sols += solve_all(new)
  end
  sols
end

