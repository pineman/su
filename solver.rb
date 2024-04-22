require_relative 'pos'
require_relative 'sets'

Grid = Data.define(:rows, :cols, :boxes)
Sudoku = Struct.new(:grid, :bf, :pos)
Move = Data.define(:row, :col, :num)

def init_sudoku(rows)
  cols = (0...9).map { |c| rows.map { |row| row[c] } }
  boxes = Array.new(9) { Array.new(9) }
  rows.each.with_index { |row, r|
    row.each.with_index { |content, c|
      box, i = rc2box(r, c)
      boxes[box][i] = content
    }
  }
  grid = Grid.new(rows, cols, boxes)

  if (d = find_dup(grid.rows))
    raise "duplicate in row #{d+1}"
  end
  if (d = find_dup(grid.cols))
    raise "duplicate in column #{d+1}"
  end
  if (d = find_dup(grid.boxes))
    raise "duplicate in box #{d+1}"
  end

  Sudoku.new(grid, 0, possible_positions(grid))
end

def find_dup(nums_arr)
  nums_arr.find_index { |n|
    n = n.filter { _1 != 0 }
    n.uniq.size != n.size
  }
end

def rc2box(r, c)
  box = r / 3 * 3 + c / 3
  i = r % 3 * 3 + c % 3
  [box, i]
end

def deep_copy_sudoku(s)
  new_grid = Grid.new(
    s.grid.rows.map { |row| row.map(&:clone) },
    s.grid.cols.map { |col| col.map(&:clone) },
    s.grid.boxes.map { |box| box.map(&:clone) }
  )
  new_pos = s.pos.map { |row| row.map { |nums| nums&.map(&:clone) } }
  Sudoku.new(new_grid, s.bf, new_pos)
end

def rc4box(box)
  start_row = (box / 3) * 3
  start_col = (box % 3) * 3
  (start_row...start_row+3).to_a.product((start_col...start_col+3).to_a)
end

def move(s, m)
  new = deep_copy_sudoku(s)
  box, i = rc2box(m.row, m.col)

  new.grid.rows[m.row][m.col] = m.num
  new.grid.cols[m.col][m.row] = m.num
  new.grid.boxes[box][i] = m.num

  new.pos[m.row][m.col] = nil
  new.pos[m.row].each.with_index { |_, i|
    next unless new.pos[m.row][i]
    new.pos[m.row][i] -= [m.num]
  }
  new.pos.each.with_index { |_, i|
    next unless new.pos[i][m.col]
    new.pos[i][m.col] -= [m.num]
  }
  rc4box(box).each { |r, c|
    next unless new.pos[r][c]
    new.pos[r][c] -= [m.num]
  }

  new
end

def done?(s)
  s.grid.rows.all? { |row| row.all? { |num| num != 0 } }
end

def no_moves?(s)
  s.pos.flatten.compact.empty?
end

def best_moves(s)
  by_pos = best_by_position(s.pos)
  return by_pos if by_pos.size == 1
  [by_pos, best_by_sets(s.grid)].min_by { _1.size }
end

# Return rows matrix if solved, false otherwise
def solve_first(s)
  return s if done?(s)
  return nil if no_moves?(s)

  moves = best_moves(s)
  s.bf += (moves.size - 1)**2
  moves.each do |move|
    new = move(s, move)
    solved = solve_first(new)
    return solved if solved
    # if the move is undone here, probably won't need to copy the whole sudoku
  end
  nil
end

def solve_all(s)
  return [s] if done?(s)
  return [] if no_moves?(s)

  moves = best_moves(s)
  s.bf += (moves.size - 1)**2
  sols = []
  moves.each do |move|
    new = move(s, move)
    sols += solve_all(new)
  end
  sols
end

def one_solution?(s)
  search = ->(s, sols) do
    return if sols.size > 1
    return sols << s if done?(s)
    return if no_moves?(s)

    moves = best_moves(s)
    s.bf += (moves.size - 1)**2
    moves.each do |move|
      new = move(s, move)
      search.(new, sols)
      break if sols.size > 1
    end
  end

  sols = []
  search.(s, sols)
  return nil if sols.size != 1
  sols.first
end
