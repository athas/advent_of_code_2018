-- Cellular automata!
--
-- Each cell value is the index of the closest point.
--
-- We use -1 to represent 'undetermined' and -2 to represent 'multiple equally distant'.

type pos = {x:i32, y:i32}

let parse: [][2]i32 -> []pos = map (\r -> {x=r[0], y=r[1]})

let evolve [w][h] (grid: [w][h]i32): [w][h]i32 =
  let f x y =
    (let c = grid[x,y]
     let n = if x > 0 then unsafe grid[x-1,y] else -1
     let e = if y < h-1 then unsafe grid[x,y+1] else -1
     let s = if x < w-1 then unsafe grid[x+1,y] else -1
     let w = if y > 0 then unsafe grid[x,y-1] else -1
     let matches (v1: i32) (v2: i32) = v1 == v2 || v2 == -1
     in if c != -1 then c
        else if n >= 0 then (if matches n e && matches n s && matches n w then n else -2)
        else if e >= 0 then (if matches e n && matches e s && matches e w then e else -2)
        else if s >= 0 then (if matches s n && matches s e && matches s w then s else -2)
        else if w >= 0 then (if matches w n && matches w e && matches w s then w else-2)
        else c)
  in tabulate_2d w h f

let evolve_fixed_point [h][w] (orig_grid: [h][w]i32): [h][w]i32 =
  (loop (grid, continue) = (orig_grid, true) while continue do
   let grid' = evolve grid
   in (grid', grid' != grid)) |> (.1)

let index_of [n] 't (p: t -> bool) (ts: [n]t): i32 =
  let f (x, i) (y, j) =
    if x == y then (if i < j then (x, i) else (y, j))
    else if x then (x, i)
    else (y, j)
  in reduce_comm f (false, -1) (zip (map p ts) (iota n)) |> (.2)

-- (index, value)
let argmax (xs: []i32): (i32, i32) =
  let f (i, x) (j, y) =
    if x > y then (i, x)
    else if y < x then (j, y)
    else if i > j then (i, x)
    else (j, y)
  in reduce_comm f (-1, 0) (zip (iota (length xs)) xs)

entry part1 [num_points] (input: [num_points][2]i32) =
  let points = parse input
  let max_x = points |> map (.x) |> i32.maximum |> (+1)
  let max_y = points |> map (.y) |> i32.maximum |> (+1)
  let grid = tabulate_2d max_x max_y (\x y -> index_of (=={x,y}) points)
             |> evolve_fixed_point
  let edge = grid[0] ++ grid[max_x-1] ++ grid[:,0] ++ grid[:,max_y-1]
  let not_on_edge i = !(any (==i) edge)
  let area_per_point = reduce_by_index (replicate num_points 0) (+) 0
                       (flatten grid) (replicate (max_x*max_y) 1)
  in map2 (*) area_per_point (map (not_on_edge >-> i32.bool) (iota num_points)) |> i32.maximum

let distance (p1: pos) (p2: pos): i32 =
  i32.abs(p1.x-p2.x) + i32.abs(p1.y-p2.y)

entry part2 [num_points] (input: [num_points][2]i32) =
  let points = parse input
  let max_x = points |> map (.x) |> i32.maximum |> (+1)
  let max_y = points |> map (.y) |> i32.maximum |> (+1)
  let limit = 10000
  let f x y = map (distance {x,y}) points |> i32.sum |> (<limit)
  let grid = tabulate_2d max_x max_y f
  in flatten grid |> map i32.bool |> i32.sum
