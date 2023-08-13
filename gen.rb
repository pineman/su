require_relative 'solver'

def seed
  box0 = (1..9).to_a.shuffle
  box1r1 = ((1..9).to_a - box0[..2]).shuffle[..2]

  while true
    box1r2 = ((1..9).to_a - box1r1 - box0[3..5]).shuffle[..2]
    box1r3 = ((1..9).to_a - box1r1 - box1r2 - box0[6..9]).shuffle[..2]
    break if box1r3.size == 3
  end

  def complete(a)
    a + ((1..9).to_a - a).shuffle
  end
  row1 = complete(box0[..2] + box1r1)
  row2 = complete(box0[3..5] + box1r2)
  row3 = complete(box0[6..] + box1r3)

  rows = [row1, row2, row3]
  col1 = complete([row1[0], row2[0], row3[0]])
  6.times { |i| rows << [col1[i+3]] + [0]*8 }

  rows
end

def random_cell(s)
  while true
    r, c = [rand(9), rand(9)]
    return [r, c] if s.grid.rows[r][c] != 0
  end
end

# TODO: not the same algo as the article
def gen
  s = init_sudoku(seed)
  s = solve_first(s)
  bf = 0
  while true
    r, c = random_cell(s)
    backup = s.grid.rows[r][c]
    s.grid.rows[r][c] = 0
    sols = solve_all(init_sudoku(s.grid.rows))
    if sols.size == 1
      bf = sols.first.bf
    else
      s.grid.rows[r][c] = backup
      s.bf = bf
      break s
    end
  end
end

def missing_cells(s)
  s.grid.rows.sum { |row| row.count { |cell| cell == 0 } }
end

def test
  score = []
  1000.times do
    s = gen
    score << s.bf*100 + missing_cells(s)
  end
  pp score.tally.sort_by { _1 }
end
test
