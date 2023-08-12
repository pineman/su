require 'benchmark'

Sudoku = Struct.new(:rows, :cols, :boxes)
def init_sudoku(rows)
  cols = (0...9).map { |c| rows.map { _1[c] } }
  boxes = Array.new(9) { Array.new(9) }
  rows.each.with_index { |row, r|
    row.each.with_index { |num, c|
      box, boxi = rc2box(r, c)
      boxes[box][boxi] = num;
    }
  }
  s = Sudoku.new(rows, cols, boxes)
  validate_puzzle(s)
  s
end

def validate_puzzle(s)
  if (d = s.rows.find_index { |r| r = r.filter { _1 != 0 }; r.uniq.size != r.size })
    raise "duplicate in row #{d+1}"
  end
  if (d = s.cols.find_index { |c| c = c.filter { _1 != 0 }; c.uniq.size != c.size })
    raise "duplicate in column #{d+1}"
  end
  if (d = s.boxes.find_index { |b| b = b.filter! { _1 != 0 }; b.uniq.size != b.size })
    raise "duplicate in box #{d+1}"
  end
end

def rc2box(r, c)
  box = (r / 3).floor * 3 + (c / 3).floor;
  boxi = (r % 3) * 3 + (c % 3);
  [box, boxi]
end

def nums(array)
  array.filter { _1 != 0 }
end

def new_state(s, step)
  new = s.dup
  new.rows[step.row][step.col] = step.num
  new.cols[step.col][step.row] = step.num
  box, boxi = rc2box(step.row, step.col)
  new.boxes[box][boxi] = step.num
  new
end

def done?(s)
  s.rows.all? { |row| row.all? { _1 != 0 } }
end

Step = Struct.new(:row, :col, :num)
# Return an array of Steps (can be empty)
def possible_steps(s)
  s.rows.map.with_index do |row, r|
    row.map.with_index do |num, c|
      next unless num == 0
      in_row = nums(s.rows[r])
      in_col = nums(s.cols[c])
      in_box = nums(s.boxes[rc2box(r, c)[0]])
      nums = (1..9).to_a - in_row - in_col - in_box
      nums.map { Step.new(r, c, _1) }
    end
  end.flatten.compact
end

def steps_for_best_cell(ps)
  ps.group_by { [_1.row, _1.col] }
    .sort_by { |rc, steps| steps.size }
    .first => [[r, c], steps]
  steps
end

def _solve(s)
  while !done?(s)
    ps = possible_steps(s)
    steps = steps_for_best_cell(ps)
    if steps.size == 1
      s = new_state(s, steps.first)
    elsif steps.size == 0
      # backtrack!
      raise NotImplementedError
    else
      # bifurcation. save state
      raise NotImplementedError
    end
  end
  s.rows
end

def solve(s)
  r = nil
  b = Benchmark.measure {
    r = _solve(s)
  }
  puts "took #{(b.real*1000).round(2)}ms"
  r
end

require 'minitest/autorun'

class TestSudoku < Minitest::Test
  def test_solver
    @test_data.each { |hash|
      s = init_sudoku(hash[:puzzle])
      assert_equal hash[:solution], solve(s)
    }
  end

  def setup
    @test_data = [
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
      },
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
          [4, 6, 2, 3, 1, 9, 5, 6, 8],
          [8, 6, 3, 7, 4, 5, 2, 1, 9],
        ]
      }
    ]
  end
end

