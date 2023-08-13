require_relative 'solver'

def nums(array)
  array.filter { _1 != 0 }
end

def possible_positions(grid)
  grid.rows.map.with_index { |row, r|
    row.map.with_index { |num, c|
      next unless num == 0
      in_row = nums(grid.rows[r])
      in_col = nums(grid.cols[c])
      in_box = nums(grid.boxes[rc2box(r, c).first])
      [*1..9] - in_row - in_col - in_box
    }
  }
end

def best_by_position(moves)
  min, min_r, min_c = 10, nil, nil
  moves.each.with_index { |row, r|
    row.each.with_index { |nums, c|
      next unless nums
      if nums.size < min
        min, min_r, min_c = nums.size, r, c
      end
    }
  }
  moves[min_r][min_c].map { |num|
    Move.new(min_r, min_c, num)
  }
end

