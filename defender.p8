pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
screen_width = 128
half_screen_width = screen_width / 2
screen_height = 128
screen_vertical_margin = screen_height / 2
max_y = screen_height + screen_vertical_margin
min_y = -screen_vertical_margin

start_x = flr(screen_width / 5)
start_y = 60
baseline_dy = 0.5
start_dx = 0.5
ship_max_dx = 3
ship_ddy = 0.15
ship_ddx = 0.2
ship_decel = 0.5
ship_nose_offset = 3
ship_height = 7
ship_width = 8

sound_on = false
_sfx = sfx
function sfx(id)
	if (sound_on) then
		_sfx(id)
	end
end

function make_ship(x, y, dx)
	local ship = {
		x = x,
		y = y,
		tail_blast_counter = 0,
		shot_delay = 0,
		dx = dx,
		control = function(self)
			if(btn(⬆️)) then
				self:go_up()
			elseif(btn(⬇️)) then
				self:go_down()
			else
				self:decel_y()
			end
			
			if (btn(➡️)) then
				self:go_right()
			elseif (btn(⬅️)) then
				self:go_left()
			end

			if (btn(🅾️)) then
				self:fire()
			end
		end,
		go_right = function(self)
				self.dx = min(self.dx + ship_ddx, ship_max_dx)
		end,
		go_left = function(self)
				self.dx = max(self.dx - ship_ddx, -ship_max_dx)
		end,
		go_up = function(self)
				self.dy = self.dy or -baseline_dy
				self.dy -= ship_ddy
		end,
		go_down = function(self)
				self.dy = self.dy or baseline_dy
				self.dy += ship_ddy
		end,
		fire = function(self)
			if (self.shot_delay == 0) then
				self.shot_delay = 8
				make_shot(self.x, self.y+ship_nose_offset, self.dx)
			else
				self.shot_delay -= 1
			end
		end,
		decel_y = function(self)
			if (abs(self.dy) <= ship_decel) then
				self.dy = 0
			elseif (self.dy <= 0) then
				self.dy += ship_decel
			elseif (self.dy > 0) then
				self.dy -= ship_decel
			end
		end,
		update = function(self)
			self:control()
			self.y += self.dy
			self.x += self.dx
			
			if (self.y > max_y - ship_height) then
				self.dy = max(-3, self.dy * -1)
				self.y = max_y - ship_height
			elseif (self.y < min_y) then
				self.dy = min(3, self.dy * -1)
				self.y = min_y
			end
		end,
		draw = function(self)
			local ship_sprite, tail_sprite
			if (abs(self.dy) <= 1) then
				ship_sprite = 1
			elseif (abs(self.dy) <= 1.5) then
				ship_sprite = 2
			else
				ship_sprite = 3
			end
			
			if (abs(self.dx) > 0) then
				local sprite_start = 17
				local sprite_end = sprite_start + 8
				tail_sprite = min(sprite_end, sprite_start + (2 * flr(((abs(self.dx) - start_dx) / 0.4))))
				if (tail_sprite == sprite_end) then
					if (self.tail_blast_counter == 0 and flr(rnd(10)) == 1) then
						self.tail_blast_counter = 5
					elseif (self.tail_blast_counter > 0) then
						self.tail_blast_counter -= 1
						tail_sprite = sprite_end + 2
					end
				end
			end

			local flip_x = self.dx < 0
			local flip_y = self.dy > 0
			local y_offset = flip_y and -1 or 0
			spr(ship_sprite, self.x, self.y + y_offset, 1, 1, flip_x, flip_y)

			if (tail_sprite) then
				local tail_offset = -8
				if (self.dx < 0) then
					tail_offset = 8
				end
				spr(tail_sprite, self.x+tail_offset, self.y+y_offset, 1, 1, flip_x, flip_y)
			end		
		end
	}
	return ship
end

player_ship = make_ship(start_x, start_y, start_dx)

stars = {}
for i = 0, 50 + rnd(50) do
	local star = {
		x = -half_screen_width + rnd(screen_width * 2),
		y = -start_y + rnd(screen_width + (start_y * 2))
	}
	add(stars, star)
end

function update_stars()
	local x_start = cam.x
	local x_end = x_start + screen_width
	for star in all(stars) do
		if (star.x < x_start - half_screen_width) then
			star.x = x_end + rnd(half_screen_width)
			star.y = -start_y + rnd(screen_width + (start_y * 2))
		elseif (star.x > x_end + half_screen_width) then
			star.x = x_start - rnd(half_screen_width)
			star.y = -start_y + rnd(screen_width + (start_y * 2))
		end
	end
end

function draw_stars()
	for star in all(stars) do
		line(star.x, star.y, star.x + min(2, player_ship.dx), star.y, 7)
	end
end

shots = {}
function make_shot(x,y,dx)
	sfx(0)
	local shot = {}
	shot.x = x
	shot.y = y
	shot.dx = max(abs(dx) + 5, 3)
	if (dx < 0) then
		shot.dx *= -1
	end
	shot.length = 5 + rnd(10)
	add(shots,shot)
end

function draw_shots()
	for shot in all(shots) do
		line(shot.x, shot.y, shot.x+shot.length, shot.y, 10)
	end
end

function update_shots()
	for shot in all(shots) do
		if ((shot.x > cam.x + screen_width) or (shot.x < cam.x)) then
			del(shots,shot)
		end
		shot.x += shot.dx
	end
end

cam = {}
cam.x = player_ship.x - start_x
cam.y = start_y
cam.dx = 1
function update_cam()
	local desired_x = player_ship.x - start_x
	if (player_ship.dx < 0) then
		desired_x = player_ship.x - screen_width + start_x + ship_width
	end

	local diff = cam.x - desired_x

	if (abs(diff) <= abs(player_ship.dx)) then
		cam.x = desired_x
	elseif (diff < 0) then
		cam.x += cam.dx
	else
		cam.x -= cam.dx
	end

	if (cam.x != desired_x) then
		cam.dx = min(cam.dx + 1, abs(player_ship.dx) + 2)
	else
		cam.dx = 1
	end

	desired_y = player_ship.y-start_y
	if (desired_y < min_y) then
		cam.y = min_y
	elseif(desired_y > max_y - screen_height) then
		cam.y = max_y - screen_height
	else
		cam.y = desired_y
	end
end

function set_cam()
	local x_offset = flr(player_ship.dx * 2)
	camera(cam.x - x_offset, cam.y)
end

function _update60()
	player_ship:update()
	update_stars()
	update_shots()
	update_cam()
end

function _draw()
	cls(1)
	set_cam()
	draw_stars()
	draw_shots()
	player_ship:draw()
end
__gfx__
00000000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066660000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555556607775566077755000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777555555555555556666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555556600666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700066660000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000666000000000000066600000000000006660000000000000666000000000000066600000000000006660000000000000000000000000000
00000000000000000666600000000000066660000000000006666000000000000666600000000000066660000000000006666000000000000000000000000000
00000000000000005555566000000009555556600000009a555556600000009a555556600000009a55555660000009a755555660000000000000000000000000
0000000000000009775555550000009777555555000009a777555555000099a777555555000009a77755555500099a7777555555000000000000000000000000
00000000000000005555566000000009555556600000009a555556600000009a555556600000009a55555660000009a755555660000000000000000000000000
00000000000000000666600000000000066660000000000006666000000000000666600000000000066660000000000006666000000000000000000000000000
00000000000000000666000000000000066600000000000006660000000000000666000000000000066600000000000006660000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd000000550000001100000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd00005555000011110000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd88ddd055aa55501122111011cc111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd88d00055aa50001122100011cc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd88d00055aa50001122100011cc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd88ddd055aa55501122111011cc111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd00005555000011110000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd000000550000001100000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ddd00000aaa0000022200000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dddd0000aaaa000022220000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd222220aa55555022111110cc11111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222888555558881111188811111888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd222220aa55555022111110cc11111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dddd0000aaaa000022220000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ddd00000aaa0000022200000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77755555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01100000322233e002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
