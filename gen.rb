require_relative 'solver'

def seed
  box0 = [*1..9].shuffle
  box1r1 = ([*1..9] - box0[..2]).shuffle[..2]

  while true
    box1r2 = ([*1..9] - box1r1 - box0[3..5]).shuffle[..2]
    box1r3 = ([*1..9] - box1r1 - box1r2 - box0[6..9]).shuffle[..2]
    break if box1r3.size == 3
  end

  def complete(a)
    a + ([*1..9] - a).shuffle
  end
  row1 = complete(box0[..2] + box1r1)
  row2 = complete(box0[3..5] + box1r2)
  row3 = complete(box0[6..] + box1r3)

  rows = [row1, row2, row3]
  col1 = complete([row1[0], row2[0], row3[0]])
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

def gen(try_goal=9999999)
  solution = solve_first(init_sudoku(seed))
  best = deep_copy_sudoku(solution)
  best.bf = 0
  best_score = score(best)
  catch :done do
    # Would use Timeout::timeout but no thread support in wasm yet
    100.times do
      new = deep_copy_sudoku(best)
      5.times do
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
        throw :done if best_score >= try_goal
      end
    end
  end
  {puzzle: best.grid.rows, solution: solution.grid.rows, score: best_score}
end

def test
  score = []
  500.times do
    p Benchmark.measure {
      r = gen(48)
      pp r
      score << r[:score]
    }.total
  end
  pp score.group_by { _1/100 }.transform_values { _1.size }.sort_by {_1}
end

