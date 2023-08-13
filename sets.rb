require_relative 'solver'

def box2rc(box, i)
  r = box / 3 * 3 + i / 3
  c = box % 3 * 3 + i % 3
  [r, c]
end

def possible?(grid, r, c, m)
  return false if grid.rows[r][c] != 0
  return false if grid.rows[r].include?(m)
  return false if grid.cols[c].include?(m)
  return false if grid.boxes[rc2box(r, c)[0]].include?(m)
  true
end

def possible_sets(grid)
  rows = grid.rows.map.with_index { |row, r|
    ([*1..9] - row).map { |m|
      [m, row.map.with_index { |_, c|
        [r, c] if possible?(grid, r, c, m)
      }.compact]
    }
  }
  cols = grid.cols.map.with_index { |col, c|
    ([*1..9] - col).map { |m|
      [m, col.map.with_index { |_, r|
        [r, c] if possible?(grid, r, c, m)
      }.compact]
    }
  }
  boxes = grid.boxes.map.with_index { |box, b|
    ([*1..9] - box).map { |m|
      [m, box.map.with_index { |_, i|
        r, c = box2rc(b, i)
        [r, c] if possible?(grid, r, c, m)
      }.compact]
    }
  }
  rows + cols + boxes
end

def best_by_sets(grid)
  best_set = possible_sets(grid)
    .flatten(1)
    .sort_by { |_, positions| positions.length }
    .first
  best_set[1].map { |r, c|
    Move.new(r, c, best_set[0])
  }
end

