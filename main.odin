package main

import "core:fmt"
import "core:math/rand"
import SDL "vendor:sdl2"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN | SDL.WINDOW_RESIZABLE

WINDOW_WIDTH: i32 : 1024
WINDOW_HEIGHT: i32 : 1024

GRID_SIZE :: 16

Pos :: struct {
	x: i32,
	y: i32,
}

Game :: struct {
	renderer: ^SDL.Renderer,
}

game := Game{}

main :: proc() {

	// Load map
	labyrinth: [16][16]int

	labyrinth[0] =  {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
	labyrinth[1] =  {1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1}
	labyrinth[2] =  {1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1}
	labyrinth[3] =  {1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1}
	labyrinth[4] =  {1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1}
	labyrinth[5] =  {1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1}
	labyrinth[6] =  {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1}
	labyrinth[7] =  {1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1}
	labyrinth[8] =  {1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1}
	labyrinth[9] =  {1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1}
	labyrinth[10] = {1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1}
	labyrinth[11] = {1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1}
	labyrinth[12] = {1, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1}
	labyrinth[13] = {1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1}
	labyrinth[14] = {1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1}
	labyrinth[15] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}

	// initialize SDL
	sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
	assert(sdl_init_error == 0, SDL.GetErrorString())
	defer SDL.Quit()

	// Window
	window := SDL.CreateWindow(
		"The Labrynth",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		WINDOW_FLAGS,
	)
	assert(window != nil, SDL.GetErrorString())
	defer SDL.DestroyWindow(window)

	// Renderer
	// This is used throughout the program to render everything.
	// You only require ONE renderer for the entire program.
	game.renderer = SDL.CreateRenderer(window, -1, RENDER_FLAGS)
	assert(game.renderer != nil, SDL.GetErrorString())
	defer SDL.DestroyRenderer(game.renderer)

	// We'll have to poll for queued events each game loop
	event: SDL.Event

	hero_pos := Pos{1, 1}

	minotaur_pos := Pos{14, 14}
	minotaur_dir := Pos{0, 1}
	minotaur_last_move: int

	game_over: bool = false

	game_loop: for {
		if SDL.PollEvent(&event) {
			fmt.println("Handling event: ", event.type, event.key)

			// Quit event is clicking on the X on the window
			if event.type == SDL.EventType.QUIT {

				break game_loop
			}

			if event.type == SDL.EventType.KEYDOWN {
				new_pos := hero_pos

				#partial switch event.key.keysym.scancode {
				case .ESCAPE:
					break game_loop
				case .LEFT:
					new_pos.x -= 1
				case .RIGHT:
					new_pos.x += 1
				case .UP:
					new_pos.y -= 1
				case .DOWN:
					new_pos.y += 1
				}
				if (labyrinth[new_pos.x][new_pos.y] != 1) {
					hero_pos = new_pos
				}
			}
		}

		draw_sand()

		draw_walls(labyrinth)

		draw_hero(hero_pos)

		move_minotaur(labyrinth, &minotaur_pos, &minotaur_dir)
		draw_minotaur(minotaur_pos)

		game_over = hero_pos == minotaur_pos

		if (game_over) {
			SDL.SetRenderDrawColor(game.renderer, 255, 0, 0, 0)
			SDL.RenderClear(game.renderer)
		}

		SDL.RenderPresent(game.renderer)


	}
}

draw_walls :: proc(l: [16][16]int) {
	for i in 0 ..< 16 {
		for k in 0 ..< 16 {
			color: Color = BLACK
			if (l[k][i] == 0) {
				color = SAND
			} else {
				color = GRAY
			}
			draw_rect(color, Pos{cast(i32)k, cast(i32)i})
		}
	}
}

draw_sand :: proc() {
	SDL.SetRenderDrawColor(game.renderer, SAND.r, SAND.g, SAND.b, 0)
	SDL.RenderClear(game.renderer)
}

draw_hero :: proc(pos: Pos) {
	draw_rect(BLUE, pos)
}

move_minotaur :: proc(labyrinth: [16][16]int, pos: ^Pos, dir: ^Pos) {
	for {
		if (labyrinth[pos.x + dir.x][pos.y + dir.y] == 1) {
			x_or_y: [2]int = {0, 1}
			pos_or_neg: [2]i32 = {-1, 1}
			value: i32 = rand.choice(pos_or_neg[:])
			if (cast(bool)rand.choice(x_or_y[:])) {
				dir.x = value
				dir.y = 0
			} else {
				dir.y = value
				dir.x = 0
			}
		} else {
			// left_or_right: [2]int = {-1, 1}
			// move : i32 = cast(i32)rand.choice(left_or_right[:])
			// if (dir.x == 0)
			// {
			//     if (labyrinth[pos.x + move][pos.y] == 1)
			//     {
			//         pos.x += move
			//         dir.y = 0
			//         dir.x = move
			//         break
			//     }
			// }
			// if (dir.y == 0)
			// {
			//     if (labyrinth[pos.x + move][pos.y] == 1)
			//     {
			//         pos.x += move
			//         dir.x = move
			//         dir.y = 0
			//         break
			//     }
			// }
			pos.x += dir.x
			pos.y += dir.y
			break
		}
	}
}

draw_minotaur :: proc(pos: Pos) {
	draw_rect(BROWN, pos)
}

draw_rect :: proc(c: Color, pos: Pos) {
	SDL.SetRenderDrawColor(game.renderer, c.r, c.g, c.b, 100)

	side_size: i32 = WINDOW_HEIGHT / GRID_SIZE

	rect := SDL.Rect{pos.x * side_size, pos.y * side_size, side_size, side_size}

	SDL.RenderFillRect(game.renderer, &rect)
}
