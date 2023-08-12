require 'benchmark'
require 'minitest/autorun'

Grid = Struct.new(:rows, :cols, :boxes)
Sudoku = Struct.new(:grid, :moves)
def init_sudoku(rows)
  grid = matrix_to_grid(rows)
  validate_puzzle(grid)
  Sudoku.new(grid, possible_steps(grid))
end

def rc2box(r, c)
  box = (r / 3).floor * 3 + (c / 3).floor;
  boxi = (r % 3) * 3 + (c % 3);
  [box, boxi]
end

def rc4box(box)
  # Calculate the row and column of the top-left corner of the box
  start_row = (box / 3) * 3
  start_col = (box % 3) * 3

  # Create an array of 9 [r, c] coordinates for the cells in the box
  coordinates = []

  3.times do |i|
    3.times do |j|
      coordinates << [start_row + i, start_col + j]
    end
  end

  coordinates
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
    next if new.moves[row][i].nil? || new.moves[row][i].empty?
    new.moves[row][i] -= [num]
  }
  new.moves.each.with_index { |_, i|
    next if new.moves[i][col].nil? || new.moves[i][col].empty?
    new.moves[i][col] -= [num]
  }
  rc4box(rc2box(row, col).first).each { |r, c|
    next if new.moves[r][c].nil? || new.moves[r][c].empty?
    new.moves[r][c] -= [num]
  }

  new
end

def best_moves(moves)
  min, min_r, min_c = 10, nil, nil
  moves.each.with_index { |row, r|
    row.each.with_index { |nums, c|
      next if nums.nil? || nums.empty?
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
def _solve(s)
  return s.grid.rows if done?(s)
  return false if no_moves?(s)
  row, col = best_moves(s.moves)
  s.moves[row][col].each do |num|
    new = move(s, row, col, num)
    solved = _solve(new)
    return solved if solved
  end
  false
end

def solve(s)
  r = nil
  b = Benchmark.measure {
    r = _solve(s)
  }
  puts "took #{(b.real*1000).round(2)}ms"
  r
end

class TestSudoku < Minitest::Test
  make_my_diffs_pretty!

  def _test_solver(data)
    data.each { |hash|
      s = init_sudoku(hash[:puzzle])
      actual = solve(s)
      expected = hash[:solution]
      assert_equal expected, actual
    }
  end

  def test_solver_trivial
    _test_solver(@direct)
  end

  def test_solver_backtracking
    _test_solver(@backtracking)
  end

  def setup
    @direct = [
      {
        puzzle: [
          [0, 0, 0, 2, 6, 0, 7, 0, 1],
          [6, 8, 0, 0, 7, 0, 0, 9, 0],
          [1, 9, 0, 0, 0, 4, 5, 0, 0],
          [8, 2, 0, 1, 0, 0, 0, 4, 0],
          [0, 0, 4, 6, 0, 2, 9, 0, 0],
          [0, 5, 0, 0, 0, 3, 0, 2, 8],
          [0, 0, 9, 3, 0, 0, 0, 7, 4],
          [0, 4, 0, 0, 5, 0, 0, 3, 6],
          [7, 0, 3, 0, 1, 8, 0, 0, 0],
        ],
        solution: [
          [4, 3, 5, 2, 6, 9, 7, 8, 1],
          [6, 8, 2, 5, 7, 1, 4, 9, 3],
          [1, 9, 7, 8, 3, 4, 5, 6, 2],
          [8, 2, 6, 1, 9, 5, 3, 4, 7],
          [3, 7, 4, 6, 8, 2, 9, 1, 5],
          [9, 5, 1, 7, 4, 3, 6, 2, 8],
          [5, 1, 9, 3, 2, 6, 8, 7, 4],
          [2, 4, 8, 9, 5, 7, 1, 3, 6],
          [7, 6, 3, 4, 1, 8, 2, 5, 9],
        ]
      },
      {
        puzzle: [
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ],
        solution: [
          [5, 3, 4, 6, 7, 8, 9, 1, 2],
          [6, 7, 2, 1, 9, 5, 3, 4, 8],
          [1, 9, 8, 3, 4, 2, 5, 6, 7],
          [8, 5, 9, 7, 6, 1, 4, 2, 3],
          [4, 2, 6, 8, 5, 3, 7, 9, 1],
          [7, 1, 3, 9, 2, 4, 8, 5, 6],
          [9, 6, 1, 5, 3, 7, 2, 8, 4],
          [2, 8, 7, 4, 1, 9, 6, 3, 5],
          [3, 4, 5, 2, 8, 6, 1, 7, 9],
        ]
      }
    ]
    @backtracking = [
      {
        puzzle: [
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 3, 0, 8, 5],
          [0, 0, 1, 0, 2, 0, 0, 0, 0],
          [0, 0, 0, 5, 0, 7, 0, 0, 0],
          [0, 0, 4, 0, 0, 0, 1, 0, 0],
          [0, 9, 0, 0, 0, 0, 0, 0, 0],
          [5, 0, 0, 0, 0, 0, 0, 7, 3],
          [0, 0, 2, 0, 1, 0, 0, 0, 0],
          [0, 0, 0, 0, 4, 0, 0, 0, 9],
        ],
        solution: [
          [9, 8, 7, 6, 5, 4, 3, 2, 1],
          [2, 4, 6, 1, 7, 3, 9, 8, 5],
          [3, 5, 1, 9, 2, 8, 7, 4, 6],
          [1, 2, 8, 5, 3, 7, 6, 9, 4],
          [6, 3, 4, 8, 9, 2, 1, 5, 7],
          [7, 9, 5, 4, 6, 1, 8, 3, 2],
          [5, 1, 9, 2, 8, 6, 4, 7, 3],
          [4, 7, 2, 3, 1, 9, 5, 6, 8],
          [8, 6, 3, 7, 4, 5, 2, 1, 9],
        ]
      },
      {
        puzzle: [
          [0, 0, 5, 3, 0, 0, 0, 0, 0],
          [8, 0, 0, 0, 0, 0, 0, 2, 0],
          [0, 7, 0, 0, 1, 0, 5, 0, 0],
          [4, 0, 0, 0, 0, 5, 3, 0, 0],
          [0, 1, 0, 0, 7, 0, 0, 0, 6],
          [0, 0, 3, 2, 0, 0, 0, 8, 0],
          [0, 6, 0, 5, 0, 0, 0, 0, 9],
          [0, 0, 4, 0, 0, 0, 0, 3, 0],
          [0, 0, 0, 0, 0, 9, 7, 0, 0],
        ],
        solution: [
          [1, 4, 5, 3, 2, 7, 6, 9, 8],
          [8, 3, 9, 6, 5, 4, 1, 2, 7],
          [6, 7, 2, 9, 1, 8, 5, 4, 3],
          [4, 9, 6, 1, 8, 5, 3, 7, 2],
          [2, 1, 8, 4, 7, 3, 9, 5, 6],
          [7, 5, 3, 2, 9, 6, 4, 8, 1],
          [3, 6, 7, 5, 4, 2, 8, 1, 9],
          [9, 8, 4, 7, 6, 1, 2, 3, 5],
          [5, 2, 1, 8, 3, 9, 7, 6, 4],
        ]
      }
    ]
  end
end
