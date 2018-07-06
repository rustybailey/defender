pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
screen_width = 128
half_screen_width = screen_width / 2
screen_height = 128
screen_vertical_margin = screen_height / 2
max_y = screen_height + screen_vertical_margin
min_y = -screen_vertical_margin

start_x = flr(screen_width / 3)
start_y = 60
baseline_dy = 0.5
ship_max_dy = 5
start_dx = 0.5
ship_max_dx = 3
ship_ddy = 0.15
ship_ddx = 0.2
ship_decel = 0.5
ship_nose_offset = 3
ship_height = 7
ship_width = 8

objects = {}

sound_on = true
stop = false
_sfx = sfx
function sfx(id)
	if (sound_on) then
		_sfx(id)
	end
end

function draw_hit_box(o)
	rect(o.x, o.y, o.x + o.width, o.y + o.height, 11)
end

function white_pal()
	for i = 0, 15 do
		pal(i, 7)
	end
end

function test_collision(a, b)
	return (
		a.x < b.x + b.width and
		a.x + a.width > b.x and
		a.y < b.y + b.height and
		a.y + a.height > b.y
	)
end

function make_ship(x, y, dx)
	local ship = {
		x = x,
		y = y,
		width = ship_width,
		height = ship_height,
		tail_blast_counter = 0,
		shot_delay = 0,
		dx = dx,
		dy = 0,
		go_right = function(self)
				self.dx = min(self.dx + ship_ddx, ship_max_dx)
		end,
		go_left = function(self)
				self.dx = max(self.dx - ship_ddx, -ship_max_dx)
		end,
		go_up = function(self)
				self.dy = self.dy or -baseline_dy
				self.dy = max(self.dy - ship_ddy, -ship_max_dy)
		end,
		go_down = function(self)
				self.dy = self.dy or baseline_dy
				self.dy = min(self.dy + ship_ddy, ship_max_dy)
		end,
		fire = function(self)
			if (self.shot_delay == 0) then
				self.shot_delay = 8
				self.fired = true
			else
				self.shot_delay -= 1
			end
		end,
		check_hit = function(self, object)
			self.hit = test_collision(self, object)
			return self.hit
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
			if (self.fired) then
				make_shot(self.x + (self.dx >= 0 and ship_width or 0), self.y+ship_nose_offset, self.dx)
				self.fired = false
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
			if (self.hit) then
				if (self.is_player_ship) then
					sfx(2)
					cam:shake()
				else
					sfx(1)
				end
				white_pal()
				self.hit = false
			elseif (self.pal) then
				self:pal()
			end
			spr(ship_sprite, self.x, self.y + y_offset, 1, 1, flip_x, flip_y)
			pal()

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

ships = {}
player_ship = make_ship(start_x, start_y, start_dx)
player_ship.is_player_ship = true
player_ship.control = function(self)
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
end
add(ships, player_ship)
add(objects, player_ship)

bad_ship = make_ship(start_x+50, start_y, start_dx)
bad_ship.pal = function(self)
	pal(5,2)
	pal(7,8)
	pal(6,13)
end
bad_ship.control = function(self)
	local desired_y = (player_ship.y + player_ship.dy)
	local y_diff = (self.y + self.dy) - desired_y
	if(abs(y_diff) <= 5) then
		self:decel_y()
	elseif (y_diff > 0) then
		self:go_up()
	else 
		self:go_down()
	end

	local desired_x = (player_ship.x + player_ship.dx) - 20
	local x_diff = (self.x + self.dx) - desired_x
	if(x_diff > 10) then
		self:go_left()
	elseif (x_diff < -10) then
		self:go_right()
	end

	if (rnd(1) > 0.5) then
		self:fire()
	end
end
add(ships, bad_ship)
add(objects, bad_ship)

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
	local width = 5 + rnd(10)
	shot.x = dx < 0 and x - width or x
	shot.y = y
	shot.dx = dx < 0 and dx - 5 or dx + 5
	shot.width = width
	shot.height = 1
	add(shots,shot)
end

function draw_shots()
	for shot in all(shots) do
		line(shot.x, shot.y, shot.x+shot.width, shot.y, 10)
	end
end

function check_hits()
	for shot in all(shots) do
		for ship in all(ships) do
			if (ship:check_hit(shot)) then
				del(shots,shot)
			end
		end
	end
end

function update_shots()
	for shot in all(shots) do
		if ((shot.x > cam.x + screen_width + half_screen_width) or (shot.x < cam.x - half_screen_width)) then
			del(shots,shot)
		end
		shot.x += shot.dx
	end
end

cam = {
	x = player_ship.x - start_x,
	y = start_y,
	dx = 1,
	shake_counter = 0,
	shake = function(self)
		self.shake_counter = 10
	end,
	update = function(self)
		if (self.shake_counter > 0) then
			self.shake_counter -= 1
			self.shake_x  = rnd(3)
			self.shake_y  = rnd(3)
		else
			self.shake_x  = 0
			self.shake_y  = 0
		end

		local desired_x = player_ship.x - start_x
		if (player_ship.dx < 0) then
			desired_x = player_ship.x - screen_width + start_x + ship_width
		end

		local diff = self.x - desired_x

		if (abs(diff) <= abs(player_ship.dx)) then
			self.x = desired_x
		elseif (diff < 0) then
			self.x += self.dx
		else
			self.x -= self.dx
		end

		if (self.x != desired_x) then
			self.dx = min(self.dx + 1, abs(player_ship.dx) + 2)
		else
			self.dx = 1
		end

		desired_y = player_ship.y-start_y
		if (desired_y < min_y) then
			self.y = min_y
		elseif(desired_y > max_y - screen_height) then
			self.y = max_y - screen_height
		else
			self.y = desired_y
		end	
	end,
	set = function(self)
		local x_offset = flr(player_ship.dx * 2)
		camera(self.x - x_offset + self.shake_x, self.y + self.shake_y)
	end
}

function _update60()
	if (stop) then
		return
	end

	update_stars()
	check_hits()
	update_shots()
	for object in all(objects) do
		object:update()
	end
	cam:update()
end

function _draw()
	if (stop) then
		return
	end

	cls(1)
	cam:set()
	draw_stars()
	draw_shots()
	for object in all(objects) do
		object:draw()
	end
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
01100000330233e002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400001c44300203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203002030000300000
011400001c4731c445004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403
