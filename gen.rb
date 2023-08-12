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
    return [r, c] if s[r][c] != 0
  end
end

def gen
  rows = seed
  s = init_sudoku(rows)
  s = solve_first(s)
  while true
    r, c = random_cell(s)
    backup = s[r][c]
    s[r][c] = 0
    next unless solve_all(init_sudoku(s)).size >= 2
    s[r][c] = backup
    break s
  end
end

def missing_cells(s)
  c = 0
  s.each { |row| row.each { |cell| c += 1 if cell == 0 } }
  c
end

def test
  puzzles = []
  missing = []
  took = []
  while true
    g = gen
    puzzles << g
    missing << missing_cells(g)
    s = init_sudoku(g)
    t = Benchmark.measure {
      solve_first(s)
    }.total*1000
    took << t.round(1)
    break if puzzles.size == 1000
  end
  pp missing.tally.sort_by { _1 }
  pp took.tally.sort_by { _1 }
end


