require 'minitest/autorun'

require_relative 'gen'

class TestGen < Minitest::Test
  make_my_diffs_pretty!

  def test_gen
    50.times do
      s = try_gen(300)
      sols = solve_all(init_sudoku(s[:puzzle]))
      assert_equal 1, sols.size
      assert_equal s[:solution], sols[0].grid.rows
    end
  end
end
