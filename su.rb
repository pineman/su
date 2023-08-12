require 'benchmark'

class Sudoku
  def initialize(rows)
    @rows = rows
    @cols = (0...9).map { |c| rows.map { _1[c] } }
    @boxes = Array.new(9) { Array.new(9) }
    rows.each.with_index { |row, r|
      row.each.with_index { |num, c|
        box, boxi = rc2box(r, c)
        @boxes[box][boxi] = num;
      }
    }
    validate_puzzle
  end

  private def validate_puzzle
    if (d = @rows.find_index { |r| r = r.filter { _1 != 0 }; r.uniq.size != r.size })
      p "duplicate in row #{d+1}"
    end
    if (d = @cols.find_index { |c| c = c.filter { _1 != 0 }; c.uniq.size != c.size })
      p "duplicate in column #{d+1}"
    end
    if (d = @boxes.find_index { |b| b = b.filter! { _1 != 0 }; b.uniq.size != b.size })
      p "duplicate in box #{d+1}"
    end
  end

  private def rc2box(r, c)
    box = (r / 3).floor * 3 + (c / 3).floor;
    boxi = (r % 3) * 3 + (c % 3);
    [box, boxi]
  end

  private def nums(array)
    array.filter { _1 != 0 }
  end

  Step = Struct.new(:row, :col, :num)
  # Return either
  # * a Step if there exists a cell with only one possible number
  # * a matrix of possible numbers for each cell
  private def possible_steps
    @rows.map.with_index do |row, r|
      row.map.with_index do |num, c|
        next unless num == 0
        in_row = nums(@rows[r])
        in_col = nums(@cols[c])
        in_box = nums(@boxes[rc2box(r, c)[0]])
        nums = (1..9).to_a - in_row - in_col - in_box
        return Step.new(r, c, nums.first) if nums.size == 1
        nums
      end
    end
  end

  private def update_grid(s)
    @rows[s.row][s.col] = s.num
    @cols[s.col][s.row] = s.num
    box, boxi = rc2box(s.row, s.col)
    @boxes[box][boxi] = s.num
  end

  private def not_done?
    @rows.any? { |row| row.any? { _1 == 0 } }
  end

  private def _solve
    while not_done?
      ps = possible_steps
      exit(1) if ps.is_a?(Array)
      update_grid(ps)
    end
  end

  def solve
    b = Benchmark.measure {
      _solve
    }
    puts "took #{(b.real*1000).round(2)}ms"
    @rows
  end
end

require 'minitest/autorun'

class TestSudoku < Minitest::Test
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
      #{
      #  puzzle: [
      #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
      #    [0, 0, 0, 0, 0, 3, 0, 8, 5],
      #    [0, 0, 1, 0, 2, 0, 0, 0, 0],
      #    [0, 0, 0, 5, 0, 7, 0, 0, 0],
      #    [0, 0, 4, 0, 0, 0, 1, 0, 0],
      #    [0, 9, 0, 0, 0, 0, 0, 0, 0],
      #    [5, 0, 0, 0, 0, 0, 0, 7, 3],
      #    [0, 0, 2, 0, 1, 0, 0, 0, 0],
      #    [0, 0, 0, 0, 4, 0, 0, 0, 9],
      #  ],
      #  solution: [
      #    [9, 8, 7, 6, 5, 4, 3, 2, 1],
      #    [2, 4, 6, 1, 7, 3, 9, 8, 5],
      #    [3, 5, 1, 9, 2, 8, 7, 4, 6],
      #    [1, 2, 8, 5, 3, 7, 6, 9, 4],
      #    [6, 3, 4, 8, 9, 2, 1, 5, 7],
      #    [7, 9, 5, 4, 6, 1, 8, 3, 2],
      #    [5, 1, 9, 2, 8, 6, 4, 7, 3],
      #    [4, 6, 2, 3, 1, 9, 5, 6, 8],
      #    [8, 6, 3, 7, 4, 5, 2, 1, 9],
      #  ]
      #}
    ]
  end

  def test_solver
    @test_data.each {
      assert_equal Sudoku.new(_1[:puzzle]).solve, _1[:solution]
    }
  end
end

