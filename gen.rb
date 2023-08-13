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

def try_gen(goal)
  solution = solve_first(init_sudoku(seed))
  best = deep_copy_sudoku(solution)
  best.bf = 0
  best_score = score(best)
  300.times do
    new = deep_copy_sudoku(best)
    if rand(2) == 1 || done?(new)
      r, c = random_filled_cell(new)
      new.grid.rows[r][c] = 0
    else
      r, c = random_empty_cell(new)
      new.grid.rows[r][c] = solution.grid.rows[r][c]
    end
    sol = one_solution?(init_sudoku(new.grid.rows))
    next if !sol
    exit(1) if solve_all(init_sudoku(new.grid.rows)).size > 1
    new.bf = sol.bf
    next if score(new) <= best_score
    best = deep_copy_sudoku(new)
    best_score = score(best)
    break if best_score >= goal
  end
  {puzzle: best.grid.rows, solution: solution.grid.rows, score: best_score}
end

