require 'benchmark'

require_relative 'solver'

def seed
  box1 = [*1..9].shuffle!
  box2r1 = ([*1..9] - box1[..2]).sample(3)

  while true
    box2r2 = ([*1..9] - box2r1 - box1[3..5]).sample(3)
    box2r3 = ([*1..9] - box2r1 - box2r2 - box1[6..9]).sample(3)
    break if box2r3.size == 3
  end

  complete = ->(a) {
    a + ([*1..9] - a).shuffle!
  }
  row1 = complete.(box1[..2] + box2r1)
  row2 = complete.(box1[3..5] + box2r2)
  row3 = complete.(box1[6..] + box2r3)

  rows = [row1, row2, row3]
  col1 = complete.([row1[0], row2[0], row3[0]])
  6.times { |i| rows << [col1[i+3]] + [0]*8 }

  rows
end

def random_filled_cell(s)
  while true
    r, c = [rand(9), rand(9)]
    return [r, c] if s.grid.rows[r][c] != 0
  end
end

def random_empty_cell(s)
  while true
    r, c = [rand(9), rand(9)]
    return [r, c] if s.grid.rows[r][c] == 0
  end
end

def score(s)
  s.bf*100 + s.grid.rows.sum { |row| row.count { |cell| cell == 0 } }
end

def _gen(try_goal=9999999)
  solution = solve_first(init_sudoku(seed))
  best = deep_copy_sudoku(solution)
  best.bf = 0
  best_score = score(best)
  catch :done do
    200.times do
      new = deep_copy_sudoku(best)
      5.times do
        throw :done if best_score >= try_goal
        if rand(2) == 1 || done?(new)
          r, c = random_filled_cell(new)
          new.grid.rows[r][c] = 0
        else
          r, c = random_empty_cell(new)
          new.grid.rows[r][c] = solution.grid.rows[r][c]
        end

        one_sol = one_solution?(init_sudoku(new.grid.rows))
        next if !one_sol

        new.bf = one_sol.bf
        next if score(new) <= best_score

        best = deep_copy_sudoku(new)
        best_score = score(best)
      end
    end
  end
  {puzzle: best.grid.rows, solution: solution.grid.rows, score: best_score}
end

def gen(diff)
  r = nil
  t = Benchmark.measure { r = _gen(diff) }
  r.merge!(took: t.real.round(3))
end

def test
  score = []
  500.times do
    p Benchmark.measure {
      r = gen(200)
      score << r[:score]
    }.total
  end
  pp score.group_by { _1/100 }.transform_values { _1.size }.sort
end
