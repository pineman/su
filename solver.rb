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
  i = r % 3 * 3 + c % 3;
  [box, i]
end

def box2rc(box, i)
  r = box / 3 * 3 + i / 3
  c = box % 3 * 3 + i % 3
  [r, c]
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

def nums(array)
  array.filter { _1 != 0 }
end

def possible_steps(grid)
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

def possible?(s, r, c, m)
  return false if s.grid.rows[r][c] != 0
  return false if s.grid.rows[r].include?(m)
  return false if s.grid.cols[c].include?(m)
  return false if s.grid.boxes[rc2box(r, c)[0]].include?(m)
  true
end

def get_sets(s)
  # TODO: compute once and update on each step, like moves?
  rows = s.grid.rows.map.with_index { |row, r|
    ((1..9).to_a - row).map { |m|
      pos = row.map.with_index { |_, c|
        [r, c] if possible?(s, r, c, m)
      }
      [m, pos.compact]
    }
  }
  cols = s.grid.cols.map.with_index { |col, c|
    ((1..9).to_a - col).map { |m|
      pos = col.map.with_index { |_, r|
        [r, c] if possible?(s, r, c, m)
      }
      [m, pos.compact]
    }
  }
  boxes = s.grid.boxes.map.with_index { |box, b|
    ((1..9).to_a - box).map { |m|
      pos = box.map.with_index { |_, i|
        r, c = box2rc(b, i)
        [r, c] if possible?(s, r, c, m)
      }
      [m, pos.compact]
    }
  }
  {rows:, cols:, boxes:}
end

def best_set_and_value(s)
  sets = get_sets(s)
  (sets[:rows] + sets[:cols] + sets[:boxes])
    .flatten(1)
    .sort_by { |_, positions| positions.length }
    .first
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
  best_set = best_set_and_value(s)

  if best_set[1].size < s.moves[row][col].size
    s.bf += (best_set[1].size - 1)**2
    best_set[1].each do |row, col|
      new = move(s, row, col, best_set[0])
      solved = solve_first(new)
      return solved if solved
    end
  else
    s.bf += (s.moves[row][col].size - 1)**2
    s.moves[row][col].each do |num|
      new = move(s, row, col, num)
      solved = solve_first(new)
      return solved if solved
    end
  end
  false
end

def solve_all(s)
  return [s] if done?(s)
  return [] if no_moves?(s)

  sols = []
  row, col = best_moves(s.moves)
  best_set = best_set_and_value(s)

  if best_set[1].size < s.moves[row][col].size
    s.bf += (best_set[1].size - 1)**2
    best_set[1].each do |row, col|
      new = move(s, row, col, best_set[0])
      sols += solve_all(new)
    end
  else
    s.bf += (s.moves[row][col].size - 1)**2
    s.moves[row][col].each do |num|
      new = move(s, row, col, num)
      sols += solve_all(new)
    end
  end
  sols
end

