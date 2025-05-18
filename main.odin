package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strconv"
import "core:strings"
import r "vendor:raylib"

SCALE :: 2

CELL_SIZE :: 40 * SCALE
ROW_SIZE :: 10
COL_SIZE :: 10
PADDING :: 3
X_OFFSET :: 0
Y_OFFSET :: 100
BOMBS :: 10

WIDTH :: ROW_SIZE * SCALE * 40 + X_OFFSET
HEIGHT :: COL_SIZE * SCALE * 40 + Y_OFFSET

FONT_SIZE :: 40 * SCALE

Window :: struct {
	width:  i32,
	height: i32,
	fps:    i32,
}

Game :: struct {
	board:          [ROW_SIZE][COL_SIZE]i8,
	board_state:    [ROW_SIZE][COL_SIZE]Cell_state,
	cell_map:       map[Cell_type]string,
	mine_remaining: i8,
	game_state:     Game_state,
}

Cell_type :: enum {
	Bomb  = -1,
	Zero  = 0,
	One   = 1,
	Two   = 2,
	Three = 3,
	Four  = 4,
	Five  = 5,
	Six   = 6,
	Seven = 7,
	Eight = 8,
}

Cell_state :: enum u8 {
	Hidden = 0,
	Show   = 1,
	Flag   = 2,
}

Game_state :: enum {
	Start,
	Loose,
	Win,
}

create_cell_map :: proc(game: ^Game) {
	game.cell_map = make(map[Cell_type]string)
	game.cell_map[Cell_type.Bomb] = "*"
	game.cell_map[Cell_type.Zero] = "0"
	game.cell_map[Cell_type.One] = "1"
	game.cell_map[Cell_type.Two] = "2"
	game.cell_map[Cell_type.Three] = "3"
	game.cell_map[Cell_type.Four] = "4"
	game.cell_map[Cell_type.Five] = "5"
	game.cell_map[Cell_type.Six] = "6"
	game.cell_map[Cell_type.Seven] = "7"
	game.cell_map[Cell_type.Eight] = "8"
}

generate_map :: proc(game: ^Game) {
	game.mine_remaining = BOMBS
	game.game_state = Game_state.Start

	i := 0
	x, y: int
	for i < BOMBS {
		x = rand.int_max(ROW_SIZE)
		y = rand.int_max(COL_SIZE)

		if game.board[x][y] == -1 {
			continue
		}

		game.board[x][y] = -1

		i += 1
	}

	for x := 0; x < ROW_SIZE; x += 1 {
		for y := 0; y < COL_SIZE; y += 1 {
			if game.board[x][y] == i8(Cell_type.Bomb) {
				// NW
				if x - 1 >= 0 &&
				   x - 1 < ROW_SIZE &&
				   y - 1 >= 0 &&
				   y - 1 < COL_SIZE &&
				   game.board[x - 1][y - 1] != i8(Cell_type.Bomb) {
					game.board[x - 1][y - 1] += 1
				}
				// N
				if y - 1 >= 0 && y - 1 < COL_SIZE && game.board[x][y - 1] != i8(Cell_type.Bomb) {
					game.board[x][y - 1] += 1
				}
				// NE
				if x + 1 >= 0 &&
				   x + 1 < ROW_SIZE &&
				   y - 1 >= 0 &&
				   y - 1 < COL_SIZE &&
				   game.board[x + 1][y - 1] != i8(Cell_type.Bomb) {
					game.board[x + 1][y - 1] += 1
				}

				// W
				if x - 1 >= 0 && x - 1 < ROW_SIZE && game.board[x - 1][y] != i8(Cell_type.Bomb) {
					game.board[x - 1][y] += 1
				}
				// E
				if x + 1 >= 0 && x + 1 < ROW_SIZE && game.board[x + 1][y] != i8(Cell_type.Bomb) {
					game.board[x + 1][y] += 1
				}

				// SW
				if x - 1 >= 0 &&
				   x - 1 < ROW_SIZE &&
				   y + 1 >= 0 &&
				   y + 1 < COL_SIZE &&
				   game.board[x - 1][y + 1] != i8(Cell_type.Bomb) {
					game.board[x - 1][y + 1] += 1
				}
				// S
				if y + 1 >= 0 && y + 1 < COL_SIZE && game.board[x][y + 1] != i8(Cell_type.Bomb) {
					game.board[x][y + 1] += 1
				}
				// SE
				if x + 1 >= 0 &&
				   x + 1 < ROW_SIZE &&
				   y + 1 >= 0 &&
				   y + 1 < COL_SIZE &&
				   game.board[x + 1][y + 1] != i8(Cell_type.Bomb) {
					game.board[x + 1][y + 1] += 1
				}
			}
		}
	}
}

get_click_position :: proc() -> (int, int) {
	mouse_position := r.GetMousePosition()

	x := int((mouse_position.x - X_OFFSET) / CELL_SIZE)
	y := int((mouse_position.y - Y_OFFSET) / CELL_SIZE)

	return x, y
}

update_game :: proc(game: ^Game) {
	sum := 0
	for x := 0; x < ROW_SIZE; x += 1 {
		for y := 0; y < COL_SIZE; y += 1 {
			if game.board_state[x][y] != Cell_state.Hidden {
				sum += 1
			}
		}
	}

	if sum == ROW_SIZE * COL_SIZE {
		game.game_state = Game_state.Win
		return
	}

	x, y := get_click_position()

	if (r.IsMouseButtonReleased(r.MouseButton.LEFT) ||
		   r.IsMouseButtonReleased(r.MouseButton.RIGHT)) &&
	   game.game_state == Game_state.Loose {
		return
	}

	if r.IsMouseButtonReleased(r.MouseButton.LEFT) {
		if game.board[x][y] == i8(Cell_type.Bomb) {
			game.game_state = Game_state.Loose
		}

		if (game.board_state[x][y] != Cell_state.Flag) {
			game.board_state[x][y] = Cell_state.Show
		}
	}

	if r.IsMouseButtonReleased(r.MouseButton.RIGHT) && game.board_state[x][y] != Cell_state.Show {
		if (game.board_state[x][y] != Cell_state.Flag && game.mine_remaining > 0) {
			game.board_state[x][y] = Cell_state.Flag
			game.mine_remaining -= 1
		} else if (game.board_state[x][y] == Cell_state.Flag) {
			game.board_state[x][y] = Cell_state.Hidden
			game.mine_remaining += 1
		}
	}
}

draw_game :: proc(game: ^Game) {
	r.BeginDrawing()

	r.ClearBackground(r.BLACK)

	x, y: i32
	for x = 0; x < ROW_SIZE; x += 1 {
		for y = 0; y < COL_SIZE; y += 1 {
			r.DrawRectangle(
				X_OFFSET + CELL_SIZE * x,
				Y_OFFSET + CELL_SIZE * y,
				CELL_SIZE - PADDING,
				CELL_SIZE - PADDING,
				r.GRAY,
			)

			if game.board_state[x][y] != Cell_state.Hidden {
				r.DrawRectangle(
					X_OFFSET + CELL_SIZE * x,
					Y_OFFSET + CELL_SIZE * y,
					CELL_SIZE - PADDING,
					CELL_SIZE - PADDING,
					r.DARKGRAY,
				)
			}

			if game.board_state[x][y] == Cell_state.Show {
				#partial switch Cell_type(game.board[x][y]) {
				case Cell_type.Bomb:
					r.DrawText(
						"*",
						X_OFFSET + CELL_SIZE * x,
						Y_OFFSET + CELL_SIZE * y,
						FONT_SIZE,
						r.BLACK,
					)
				case Cell_type.Zero:
					r.DrawRectangle(
						X_OFFSET + CELL_SIZE * x,
						Y_OFFSET + CELL_SIZE * y,
						CELL_SIZE - PADDING,
						CELL_SIZE - PADDING,
						r.GREEN,
					)
				case Cell_type.One:
					r.DrawText(
						r.TextFormat("%s", game.cell_map[Cell_type(game.board[x][y])]),
						X_OFFSET + CELL_SIZE * x,
						Y_OFFSET + CELL_SIZE * y,
						FONT_SIZE,
						r.WHITE,
					)
				case Cell_type.Two:
					r.DrawText(
						r.TextFormat("%s", game.cell_map[Cell_type(game.board[x][y])]),
						X_OFFSET + CELL_SIZE * x,
						Y_OFFSET + CELL_SIZE * y,
						FONT_SIZE,
						r.MAGENTA,
					)
				case Cell_type.Three:
					r.DrawText(
						r.TextFormat("%s", game.cell_map[Cell_type(game.board[x][y])]),
						X_OFFSET + CELL_SIZE * x,
						Y_OFFSET + CELL_SIZE * y,
						FONT_SIZE,
						r.PINK,
					)
				case:
					r.DrawText(
						r.TextFormat("%s", game.cell_map[Cell_type(game.board[x][y])]),
						X_OFFSET + CELL_SIZE * x,
						Y_OFFSET + CELL_SIZE * y,
						FONT_SIZE,
						r.YELLOW,
					)
				}
			}

			if game.board_state[x][y] == Cell_state.Flag {
				r.DrawText(
					"F",
					X_OFFSET + CELL_SIZE * x,
					Y_OFFSET + CELL_SIZE * y,
					FONT_SIZE,
					r.GREEN,
				)
			}
		}
	}

	r.DrawText(r.TextFormat("%i", game.mine_remaining), 10, 10, FONT_SIZE, r.WHITE)

	if game.game_state == Game_state.Loose {
		r.DrawText("Game Over", WIDTH / 4, 10, FONT_SIZE, r.WHITE)
	}

	if game.game_state == Game_state.Win {
		r.DrawText("You Won!", WIDTH / 4, 10, FONT_SIZE, r.WHITE)
	}

	r.EndDrawing()
}

main :: proc() {
	window := Window{WIDTH, HEIGHT, 30}
	game := Game{}

	r.InitWindow(window.width, window.height, "Minefinder")
	defer r.CloseWindow()

	r.SetTargetFPS(window.fps)

	create_cell_map(&game)
	generate_map(&game)

	for !r.WindowShouldClose() {
		update_game(&game)
		draw_game(&game)
	}
}
