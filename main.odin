package main

import "core:fmt"
import "core:math/rand"
import "core:strconv"
import "core:strings"
import r "vendor:raylib"

Window :: struct {
	width:  i32,
	height: i32,
}

scale :: 2

cell_size :: 40 * scale
row_size :: 10
col_size :: 10
padding :: 2
x_offset :: 0
y_offset :: 0
bombs :: 20

width :: row_size * scale * 40
height :: col_size * scale * 40

font_size :: 40 * scale

Game :: struct {
	board:          [row_size][col_size]i64,
	show_positions: [row_size][col_size]bool,
}

generate_map :: proc(game: ^Game) {
	i := 0
	for i < bombs {
		x := rand.int_max(row_size)
		y := rand.int_max(col_size)

		if game.board[x][y] == -1 {
			continue
		}

		game.board[x][y] = -1

		i += 1
	}
}

input :: proc(game: ^Game) {
	mouse_position := r.GetMousePosition()

	if r.IsMouseButtonPressed(r.MouseButton.LEFT) {
		x := int((mouse_position.x - x_offset) / cell_size)
		y := int((mouse_position.y - y_offset) / cell_size)
		game.show_positions[x][y] = true
	}
}

draw_board :: proc(game: ^Game) {
	r.BeginDrawing()

	r.ClearBackground(r.BLACK)

	for i: i32 = 0; i < row_size; i += 1 {
		for j: i32 = 0; j < col_size; j += 1 {
			r.DrawRectangle(
				x_offset + cell_size * i,
				y_offset + cell_size * j,
				cell_size - padding,
				cell_size - padding,
				r.GRAY,
			)

			if game.show_positions[i][j] {
				r.DrawText(
					r.TextFormat("%i", game.board[i][j]),
					x_offset + cell_size * i,
					y_offset + cell_size * j,
					font_size,
					r.WHITE,
				)
			}
		}
	}

	r.EndDrawing()
}

main :: proc() {
	window := Window{width, height}
	game := Game{}

	r.InitWindow(window.width, window.height, "Minefinder")
	defer r.CloseWindow()

	r.SetTargetFPS(60)

	generate_map(&game)

	for !r.WindowShouldClose() {
		input(&game)
		draw_board(&game)
	}
}
