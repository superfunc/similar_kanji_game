local all_kanji_loaded = require('joyo_kanji')
local wk_kanji_loaded = require('wk_kanji')
local similar_kanji_loaded = require('similar_kanji')
local settings_loaded = require('base_settings')
local scores_loaded = require('base_scores')

-- XXX: Wishlist (if I find the tim)
-- - add streaks
-- - --ignoreSettings mode

function get_kanji_scale_base()
  return 60
end

function get_kanji_font_scale()
  return (get_kanji_scale_base()/settings_state.itemdepth)
end

function update_kanji_fonts()
  local c_f = settings_state.kanjifont
  kanji_font = love.graphics.newFont("fonts/" .. c_f, get_kanji_scale_base())
  answer_font = love.graphics.newFont("fonts/" .. c_f, get_kanji_font_scale())
end

function get_score()
  return math.floor(score_data * bonus_data)
end

function generate_kanji_data()
  -- If the WK level is changed, or loaded for the first time
  -- we need to filter the kanji lists appropriately
  local data_stream = {}

  -- generate random tables for indexing
  -- output in the order of:
  -- seq N: (real_index, wrong_index)
  --
  index_data = {}
  for i=1, #similar_kanji_data do
    local max_index = #similar_kanji_data[i]
    local sequence = {}
    local output = {}
    local shuffled = {}
    local stream = {}

    -- filter out groups containing kanji above wk level
    local contains_above_kanji = false
    local player_wk_level = 60
    if settings_state.wklevel ~= nil then
      player_wk_level = tonumber(settings_state.wklevel)
    end
    for c=1, max_index do
      local wk_level = find_wk_level(similar_kanji_data[i][c])
      if wk_level > player_wk_level then
        contains_above_kanji = true
      end
    end

    if contains_above_kanji == false then
      -- generate the linear index set {1...max}
      for j=1, max_index do
        table.insert(sequence, j)
      end
  
      -- shuffle the indices {2, 4, 9 ...}
      for k=1, max_index do
        local index = love.math.random(1, max_index) 
        table.insert(sequence, sequence[index])
        table.remove(sequence, index)
      end
  
      while #sequence > 0 do
        local real = sequence[1]
        local fake = -1
  
        if #sequence == 1 then
          fake = output[love.math.random(1, #output)]
        else
          fake = sequence[love.math.random(2, #sequence)]
        end
  
        table.remove(sequence, 1)
        table.insert(output, real)
        table.insert(shuffled, { real, fake })
      end
  
      local hmmm = "" 
      local text = ""
      local input_data = ""
      local debug = ""
      for x=1,#shuffled do
        debug = debug .. shuffled[x][2]
        debug = debug .. shuffled[x][1]
        local value = { real=similar_kanji_data[i][shuffled[x][1]], 
                        fake=similar_kanji_data[i][shuffled[x][2]]}
        table.insert(stream, value)
      end 
  
      table.insert(data_stream, stream)
    end
  end

  return data_stream
end

function find_wk_level(c)
  for i=1, #wk_kanji_data do
    local found = false
    for j=1, #wk_kanji_data[i] do
      if c == wk_kanji_data[i][j] then
        found = true
      end
    end

    if found == true then
      return i
    end
  end
  
  return -1
end

function play_sound(sound)
  if settings_state.sound == "on" then
    sound.index = sound.index + 1
    if sound.index > sound.max then sound.index = 1 end
    love.audio.play(sound.data[sound.index])
  end

  return sound
end

function make_sound(file)
  -- we keep an array of each sounds, so if they need to be
  -- played back to back (e.g. quick scrolling the menu, they can
  local result = {index=1, max=5, data={}}
  for i=1,result.max do
    table.insert(result.data, {love.audio.newSource(file, "stream")})
  end
  return result
end

function get_animation_frame(obj)
  return math.floor(obj.time / obj.duration * obj.num_frames) + 1
end

function draw_animation(obj, frame, x_pos, y_pos)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.draw(obj.images[frame], x_pos, y_pos)
end

function update_animation(obj, update_fn)
  local dt = love.timer.getDelta()

  obj.time = obj.time + dt
  if obj.time >= obj.duration then
    obj.time = obj.time - obj.duration
    update_fn()
  end
end

function make_animation(path, num_images, duration, id)
  local anim = {}
  anim.images = {}
  anim.id = id

  for i=0, num_images-1 do
    fp = path .. "_" .. i .. ".png"
    local new_image = love.graphics.newImage(fp)
    table.insert(anim.images, new_image)
  end

  anim.num_frames = num_images
  anim.duration = duration
  anim.time = 0
  return anim
end

function settings_to_string(data)
  local output_data = ""
  for k,v in pairs(data) do
    output_data = output_data .. k .. "=" .. v .. "\n"
    if k == "revision" then
      revision = v + 1
      has_revision = true
    end
  end

  if has_revision == false then
    output_data = output_data .. "revision = " .. revision .. "\n"
  end

  return output_data
end

function scores_to_string(data)
  local output_data = ""
  for i=1,#data do
    for j=1,#data[i] do
      output_data = output_data .. data[i][j]
      if j ~= #data[i] then output_data = output_data .. "=" end
    end
    output_data = output_data .. "\n"
  end

  return output_data
end

function troubled_kanji_dedup(data)

end

function troubled_kanji_to_string(data)
  -- Note: probably not the place to do deduplication
  -- but here we are :)
  table.sort(data)

  local output_data = ""
  local dedup = {}
  for i=1,#data do
    if dedup[#dedup] ~= data[i] then
      table.insert(dedup, data[i])
      output_data = output_data .. data[i] .. "\n"
    end
  end

  return output_data
end

function load_troubled_kanji()
  local troubled_kanji_file = troubled_kanji_file_path
  local troubled_kanji_data = {}

  local info = love.filesystem.getInfo(troubled_kanji_file, "file") 
  if info == nil then
    local output_data = troubled_kanji_to_string(troubled_kanji_data)
    local file, msg = love.filesystem.newFile(troubled_kanji_file, "w")
    if not file then
      print("Failed to capture troubled kanji file, error: " .. msg) 
    else
      file:write(output_data)
      file:close()
    end
  else
    local contents, msg_or_size = love.filesystem.read(troubled_kanji_file) 
    for item in string.gmatch(contents, "[^\r\n]+") do
      local s_item = string.gsub(item, "%s+", "")
      table.insert(troubled_kanji_data, s_item)
    end
  end

  return troubled_kanji_data 
end

function save_troubled_kanji()
  local output_data = troubled_kanji_to_string(troubled_kanji_state)

  succ, msg = love.filesystem.write(troubled_kanji_file_path, output_data)
  if msg ~= nil then
    print("Failed to write troubled kanji file: " .. msg)
  end
end

function load_scores()
  local scores_file = scores_file_path
  local scores_data = base_scores_data 

  local info = love.filesystem.getInfo(scores_file, "file") 
  if info == nil then
    local output_data = scores_to_string(scores_data)
    local file, msg = love.filesystem.newFile(scores_file, "w")
    if not file then
      print("Failed to capture scores file, error: " .. msg) 
    else
      file:write(output_data)
      file:close()
    end
  else
    local contents, msg_or_size = love.filesystem.read(scores_file) 
    for a, b, c in string.gmatch(contents, "(%w+)=(%w+)=(%w+)") do
      local s_a = string.gsub(a, "%s+", "")
      local s_b = string.gsub(b, "%s+", "")
      local s_c = string.gsub(c, "%s+", "")
      table.insert(scores_data, {s_a, s_b, s_c})
    end
  end

  return scores_data 
end

function log_current_score()
  local curr_score = get_score()

  -- After logging the score, we need to reset the index into the
  -- data stream
  current_group_index = 1 
  current_item_index = 0
    
  -- Dont add a score if the game wasn't played
  -- Also don't save negative scores (e.g. played one q, got it wrong and quit)
  if curr_score > 0 then
    table.insert(scores_state, {tostring(settings_state.wklevel), curr_score, current_mode })
  end

  score_data = initial_score
  bonus_data = initial_bonus
  loss_animation_complete = false
  loss_animation_begin = false
  lives = initial_lives
end

function save_scores()
  log_current_score()
  local output_data = scores_to_string(scores_state)
  succ, msg = love.filesystem.write(scores_file_path, output_data)
  if msg ~= nil then
    print("Failed to write scores file: " .. msg)
  end
end

function save_settings()
  local revision = 1
  local has_revision = false
  local output_data = settings_to_string(settings_state)
  
  succ, msg = love.filesystem.write(settings_file_path, output_data)
  if msg ~= nil then
    print("Failed to write settings file: " .. msg)
  end
end

function load_settings()
  local settings_file = settings_file_path
  local settings_data = base_settings_data
  local info = love.filesystem.getInfo(settings_file, "file") 
  if info == nil then
    local output_data = settings_to_string(settings_data)
    local file, msg = love.filesystem.newFile(settings_file, "w")
    if not file then
      print("Failed to capture settings file, error: " .. msg) 
    else
      file:write(output_data)
      file:close() 
    end
  else
    local contents, msg_or_size = love.filesystem.read(settings_file) 
    for k, v in string.gmatch(contents, "(%w+)=(%w+)") do
      local s_k = string.gsub(k, "%s+", "")
      local s_v = string.gsub(v, "%s+", "")
      if s_k == "kanjifont" then s_v = s_v .. ".ttf" end
      settings_data[s_k] = s_v
    end
  end

  return settings_data 
end

function draw_scorescreen()
  local screen_dim_w, screen_dim_h = love.graphics.getDimensions()
  local offset = 60
  local buff = 200
  local s_height = 10
  local f_height = zen_ui_font:getHeight()
  local buff_inc = f_height+20
 
  love.graphics.setColor(1,1,1)
  score_screen_video:play()
  love.graphics.draw(score_screen_video, 0, 0)
 
  score_text = "Score: " .. get_score()
  love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
  love.graphics.print(score_text, frisco_ui_font, offset, buff)
  buff = buff + buff_inc

  local data = current_game_mistakes 
  table.sort(data)
  local output_data = ""
  local dedup = {}
  local col_count = 0
  local col_max = 4 
  local line_count = 0
  local line_max = 4
  for i=1,#data do
    if dedup[#dedup] ~= data[i] and line_count < line_max then
      table.insert(dedup, data[i])
      col_count = col_count + 1
      output_data = output_data .. data[i] 
      if col_count > col_max then
        output_data = output_data .. ",\n"
        col_count = 0
        line_count = line_count + 1
      else
        output_data = output_data .. ", "
      end
    end
  end

  output_data = string.sub(output_data, 1, #output_data-2)
  if line_count >= line_max then
    output_data = output_data .. "..."
  end
 
  love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
  if #data == 0 then
    love.graphics.print("Mistakes: None!", frisco_ui_font, offset, buff)
  else 
    love.graphics.print("Mistakes: ", frisco_ui_font, offset, buff)
    buff = buff + buff_inc
    love.graphics.print(output_data, zen_ui_font, offset, buff)
  end

  local confirm_x = 900
  local confirm_y = 640
  local confirm_theta = 0.18 -- in radians
  love.graphics.setColor(unpack(selected_font_color))
  love.graphics.print("confirm", ui_font, confirm_x, confirm_y, 
                      confirm_theta)
  love.graphics.circle("fill", confirm_x-30, confirm_y+40, s_height)
end

function draw_ingamepause()
  local screen_dim_w, screen_dim_h = love.graphics.getDimensions()
  love.graphics.setColor(unpack(menu_bg_color))
  love.graphics.rectangle("fill", 0, 0, screen_dim_w, screen_dim_h) 
  local buff = 100
  local s_height = 10
  local f_height = ui_font:getHeight()
  local buff_inc = f_height+20
  local offset = 300

  love.graphics.draw(speed_line_video, 0, 0)

  for i=1,#ingamemenu_state.options do
    if ingamemenu_state.highlighted == ingamemenu_state.options[i] then
      love.graphics.setColor(unpack(selected_font_color))
      love.graphics.circle("fill", offset-50, 
                           buff+(f_height-s_height)/2, s_height)
    else
      love.graphics.setColor(unpack(font_color))
    end

    love.graphics.print(ingamemenu_state.options[i], ui_font, offset, buff)
    buff = buff + buff_inc
  end 
end

function draw_mainmenu()
  local screen_dim_w, screen_dim_h = love.graphics.getDimensions()
  love.graphics.setColor(unpack(menu_bg_color))
  love.graphics.rectangle("fill", 0, 0, screen_dim_w, screen_dim_h) 
  local buff = 100
  local s_height = 10
  local f_height = ui_font:getHeight()
  local buff_inc = f_height+20
  local offset = 200

  love.graphics.draw(speed_line_video, 0, 0)

  function draw_menu_options(menu)
    for i=1,#menu.options do
      if menu.options[i] == "back" then
        buff = buff + buff_inc
      end

      if menu.highlighted == menu.options[i] then
        love.graphics.setColor(unpack(selected_font_color)) 
        love.graphics.circle("fill", offset-50, buff+(f_height-s_height)/2, s_height)
      else
        love.graphics.setColor(unpack(font_color))
      end

      love.graphics.print(menu.options[i], ui_font, offset, buff)
  
      buff = buff + buff_inc
    end
  end

  if menu_state.level == "top" then
    draw_menu_options(menu_state) 
  elseif menu_state.level == "settings" then
    for k,v in pairs(settings_state) do
      love.graphics.setColor(unpack(font_color))
     
      local s_v = v
      local s_k = k

      -- provide a clearer display name
      if k == "itemdepth" then s_k = "# defs displayed" end
      if k == "kanjifont" then s_k = "kanji font" end
      if k == "wklevel" then s_k = "wanikani level" end

      if k ~= "back" then
        if settings_menu_state.highlighted == k then
          love.graphics.setColor(unpack(selected_font_color))
          love.graphics.circle("fill", offset-50, buff+(f_height-s_height)/2, s_height)

        love.graphics.print("" .. s_k .. ":  <\t" .. s_v  .. "\t>", ui_font, offset, buff)
        else
          love.graphics.setColor(unpack(font_color))
          love.graphics.print("" .. s_k .. ": " .. s_v, ui_font, offset, buff)
        end

        buff = buff + buff_inc 
      end
    end

    buff = buff + buff_inc
    if settings_menu_state.highlighted == "back" then
      love.graphics.setColor(unpack(selected_font_color))
      love.graphics.circle("fill", offset-50, buff, 10)
      love.graphics.print("back", ui_font, offset, buff)
    else
      love.graphics.setColor(unpack(font_color))
      love.graphics.print("back", ui_font, offset, buff)
    end

  elseif menu_state.level == "modeselect" then
    draw_menu_options(modeselect_menu_state)

  elseif menu_state.level == "credits" then
    local offset_l = offset-100
    local credits = { { "code: ", "twitter/superfunc" }, 
                      { "art: ", "twitter/samfilstrup" },
                      { "engine: ", "twitter/obey_love" },
                      { "data: ", "twitter/{wanikani, jisho}"},
                      { "sounds: ", "twitter/kennynl"},
                      { "fonts: ", "gfonts/{sniglet, zen kurenaido, s.e. francisco}"}}

    local column_a = offset_l
    local column_b = offset_l*3
    
    for i=1,#credits do
      local a = credits[i][1]
      local b = credits[i][2]
      love.graphics.setColor(unpack(font_color))
      love.graphics.print(a, small_ui_font, column_a, buff)
      love.graphics.print(b, small_ui_font, column_b, buff)

      buff = buff + buff_inc
    end

    buff = buff + buff_inc/2
    love.graphics.setColor(unpack(selected_font_color))
    love.graphics.print("back", ui_font, offset_l, buff)
    love.graphics.circle("fill", offset_l-50, buff, 10)

  elseif menu_state.level == "high scores" then
    local ordered_scores = {}
    local output_items = {}
    for i=1,#scores_state do 
      table.insert(ordered_scores, tonumber(scores_state[i][2]))
    end

    table.sort(ordered_scores)
    while #output_items < 5 and #ordered_scores > 0 do
      local added = false
      for j=1,#scores_state do
        if added == false then
          local level = scores_state[j][1]
          if tonumber(level) < 10 and level[1] ~= '0' then
            level = "0" .. level
          end
          local score_rhs = tonumber(scores_state[j][2])
          local mode = scores_state[j][3]
          local score_lhs = ordered_scores[#ordered_scores]
          if score_rhs == score_lhs and #output_items < 10 then
            table.insert(output_items, {level, score_rhs, mode})
            table.remove(ordered_scores, #ordered_scores)
            added = true
          end
        end
      end
    end

    local column_a = offset
    local column_b = offset*2.5
    local column_c = offset*4.0

    love.graphics.setColor(unpack(font_color))
    love.graphics.print("Level", ui_font, column_a, buff)
    love.graphics.print("Score", ui_font, column_b, buff)
    love.graphics.print("Mode", ui_font,  column_c, buff)

    buff = buff + buff_inc

    for i=1,#output_items do
      local a = output_items[i][1]
      local b = output_items[i][2]
      local c = output_items[i][3]
      love.graphics.setColor(unpack(font_color))

      love.graphics.print(a, small_ui_font, column_a, buff)
      love.graphics.print(b, small_ui_font, column_b, buff)
      love.graphics.print(c, small_ui_font,  column_c, buff)

      buff = buff + buff_inc
    end

    buff = buff + buff_inc/2
    love.graphics.setColor(unpack(selected_font_color))
    love.graphics.print("back", ui_font, offset, buff)
    love.graphics.circle("fill", offset-50, buff, 10)
  end

  love.graphics.setColor(unpack(font_color))
end

function draw_ingame(kanji_data, time_data, score_data)
    -- button layout
    local screen_dim_w, screen_dim_h = love.graphics.getDimensions()


    local width_factor = 3.0
    local height_factor = 4.0
    local round_factor = 10.0
    local padding_factor = 3.0

    -- background art
    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.draw(bg_top)

    -- bg_bot scrolls
    -- draw in halves    
    love.graphics.draw(bg_bot, bg_scroll_pos-screen_dim_w) -- -10
    love.graphics.draw(bg_bot, bg_scroll_pos)

    love.graphics.draw(scoreboard, 30, 42)

    score_text = "Score: " .. math.floor(score_data * bonus_data)
    love.graphics.setColor(unpack(chalk_font_color))
    love.graphics.print(score_text, mini_frisco_ui_font, 48, 50)

    love.graphics.setColor(unpack(chalk_font_color))
    local lives_str = "Lives: "
    for i=1,initial_lives do
      if lives >= i then
        lives_str = lives_str .. " |"
      else
        lives_str = lives_str .. " " 
      end
    end 
    love.graphics.print(lives_str, mini_frisco_ui_font, 48, 80)

    local button_x = 0.0
    local button_w = (screen_dim_w / width_factor)
    local button_h = (screen_dim_h / (height_factor*1.0))
    local button_y = (height_factor-1) * (screen_dim_h / height_factor)

    -- the bounding button_* are used in calculation, but to give nice padding
    -- visually we use a different authored_*
    local authored_x = button_x + padding_factor
    local authored_y = button_y - padding_factor
    local authored_w = button_w - padding_factor*2.0
    local authored_h = button_h - padding_factor*2.0

    if lhs_highlighted then
        love.graphics.setColor(unpack(user_choice_color))
    else
        love.graphics.setColor(unpack(user_unchoice_color))
    end
        love.graphics.rectangle("fill", authored_x, authored_y, authored_w, authored_h, round_factor, round_factor)

    if rhs_highlighted then
        love.graphics.setColor(unpack(user_choice_color))
    else
        love.graphics.setColor(unpack(user_unchoice_color))
    end
    love.graphics.rectangle("fill", (button_x+button_w*2.0)+padding_factor, authored_y, authored_w, authored_h, round_factor, round_factor)

    -- populate lhs, rhs answer data
    local current_lhs_w = answer_font:getWidth(current_lhs_text)
    local current_lhs_h = answer_font:getHeight(current_lhs_text)

    local center_lhs_x = button_x
    local center_lhs_y = button_y
    local offset_lhs_x = (button_w - current_lhs_w)/2.0
    local offset_lhs_y = (button_h - current_lhs_h)/2.0

    local current_rhs_w = answer_font:getWidth(current_rhs_text)
    local current_rhs_h = answer_font:getHeight(current_rhs_text)

    local center_rhs_x = button_x+button_w*2.0
    local center_rhs_y = button_y
    local offset_rhs_x = (button_w - current_rhs_w)/2.0
    local offset_rhs_y = (button_h - current_rhs_h)/2.0

    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.print(current_lhs_text, answer_font, center_lhs_x+offset_lhs_x, center_lhs_y+offset_lhs_y)
    love.graphics.print(current_rhs_text, answer_font, center_rhs_x+offset_rhs_x, center_rhs_y+offset_rhs_y)

    love.graphics.setColor(0.7, 0.7, 0.7)

    local current_w = kanji_font:getWidth(current_text)
    local current_h = kanji_font:getHeight(current_text)

    local center_x = button_x+button_w
    local center_y = button_y
    local offset_x = (button_w - current_w)/2.0
    local offset_y = (button_h - current_h)/2.0

    love.graphics.rectangle("fill", button_x+button_w+padding_factor, 
                            authored_y, authored_w, authored_h, round_factor, round_factor)

    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.print(current_text, kanji_font, center_x+offset_x, center_y+offset_y)

    -- draw timer bars (one full grey layered (empty) with one partially full (white))
    local timer_bar_h = 15.0
    local timer_bar_x = authored_x
    local timer_bar_w = screen_dim_w - padding_factor*2.0
    local timer_bar_y = button_y - timer_bar_h - padding_factor*2.0
    local timer_bar_round_factor = round_factor/2.0

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", timer_bar_x, timer_bar_y,
                            timer_bar_w, timer_bar_h, timer_bar_round_factor, timer_bar_round_factor)


    timer_bar_w = time_data*timer_bar_w
    if time_limit_hit == true then timer_bar_w = 0 end
    love.graphics.setColor(unpack(font_color))
    love.graphics.rectangle("fill", timer_bar_x, timer_bar_y, 
                            timer_bar_w, timer_bar_h, timer_bar_round_factor, timer_bar_round_factor)


    -- draw character
    local frame = get_animation_frame(curr_anim)
    local sprite_h = curr_anim.images[frame]:getHeight()
    local sprite_fudge = 140 
    draw_animation(curr_anim, frame, 0, (button_y-sprite_h-sprite_fudge))
end

function update_scorescreen(dt)
  if scorescreen_exit == true then
    log_current_score()
    scorescreen_exit = false
    meta_mode = "mainmenu"
    menu_enter_pushed = false
    menu_state.level = "top"
    menu_state.highlighted = "play"
    menu_state.index = 1
    current_game_mistakes = {}
    score_screen_video:pause()
  end
end

function update_ingame(dt)

    -- End game
    if (lives == 0 and loss_animation_complete == true) or end_state_achieved then
      meta_mode = "scorescreen"
      return
    end

    -- In game pause mode
    if escape_hit then
      meta_mode = "ingamepause"
      escape_hit = false
      return
    end

    item_answered = (lhs_highlighted or rhs_highlighted)

    if first_pass or item_answered then
      -- check answer
      if item_answered then
        num_attempts = num_attempts + 1

        if lhs_highlighted and lhs_correct then
          if time_limit_hit == false then
            score_data = score_data + 1
            bonus_data = bonus_data + 100*time_data
          end
        elseif rhs_highlighted and rhs_correct then
          if time_limit_hit == false then
            score_data = score_data + 1
            bonus_data = bonus_data + 100*time_data
          end
        else
          score_data = score_data - 1
          lives = lives - 1
          if lives == 0 then loss_animation_begin = true end
          anim_state_transitioning = true 
          ingame_mistake_sound = play_sound(ingame_mistake_sound)
          table.insert(troubled_kanji_state, data_stream[current_group_index][current_item_index].real)
          table.insert(troubled_kanji_state, data_stream[current_group_index][current_item_index].fake)

          table.insert(current_game_mistakes, data_stream[current_group_index][current_item_index].real)
          table.insert(current_game_mistakes, data_stream[current_group_index][current_item_index].fake)
          
        end
      end

      cooldown = true
      lhs_highlighted = false
      rhs_highlighted = false
      first_pass = false
      item_answered = false

      -- update the timer
      raw_time = base_time 
      time_data = 0.0
      time_limit_hit = false

      -- choose new char
      current_item_index = current_item_index + 1
      if current_item_index > #data_stream[current_group_index] then
        current_item_index = 1
        current_group_index = current_group_index + 1
      end
      if current_group_index > #data_stream then
        end_state_achieved = true
        return
      end

      current_text = data_stream[current_group_index][current_item_index].real

      if love.math.random(100) >= 50.0 then
        lhs_correct = true
        local lhs_key = data_stream[current_group_index][current_item_index].real
        current_lhs_text = joyo_kanji_data[lhs_key][current_mode]

        rhs_correct = false
        local rhs_key = data_stream[current_group_index][current_item_index].fake
        current_rhs_text = joyo_kanji_data[rhs_key][current_mode]
      else
        lhs_correct = false 
        local lhs_key = data_stream[current_group_index][current_item_index].fake
        current_lhs_text = joyo_kanji_data[lhs_key][current_mode]

        rhs_correct = true 
        local rhs_key = data_stream[current_group_index][current_item_index].real
        current_rhs_text = joyo_kanji_data[rhs_key][current_mode]
      end

      -- check if answer is the same on both sides if so, show more context
      local curr_item_depth = tonumber(settings_state.itemdepth)
      local sep_char = ", "
      local check_lhs = current_lhs_text .. ";"
      local lhs_depth = 1
      current_lhs_text = ""
      for cl in check_lhs:gmatch("(.-);") do
        current_lhs_text = current_lhs_text .. cl
        lhs_depth = lhs_depth + 1
        current_lhs_text = current_lhs_text .. sep_char
        if lhs_depth > curr_item_depth then break end
      end
      current_lhs_text = string.sub(current_lhs_text, 1, #current_lhs_text-2)

      local check_rhs = current_rhs_text .. ";"
      local rhs_depth = 1
      current_rhs_text = ""
      for cr in check_rhs:gmatch("(.-);") do
        current_rhs_text = current_rhs_text .. cr
        rhs_depth = rhs_depth + 1
        current_rhs_text = current_rhs_text .. sep_char
        if rhs_depth > curr_item_depth then break end
      end
      current_rhs_text = string.sub(current_rhs_text, 1, #current_rhs_text-2)

    end

    if cooldown then
      cooldown = false
      return
    end

    raw_time = (raw_time - love.timer.getDelta())
    if raw_time <= 0.0 then 
      raw_time = base_time 
      time_data = 0.0
      time_limit_hit = true
    else 
      time_data = raw_time / base_time 
    end

    if curr_anim.id == "trip" then
        local dt = love.timer.getDelta()
        local timecheck = curr_anim.time + dt
        local dur = curr_anim.duration
        if timecheck > dur then
          bg_scroll_speed = 0
        else
          bg_scroll_speed = bg_scroll_speed - (dt*(bg_scroll_speed/3))
        end
        bg_scroll_pos = bg_scroll_pos - dt*bg_scroll_speed
    else
        bg_scroll_speed = initial_bg_scroll_speed
        bg_scroll_pos = bg_scroll_pos - dt*bg_scroll_speed
    end

    if bg_scroll_pos <= 0 then
        bg_scroll_pos = initial_bg_scroll_pos
    end

    update_animation(curr_anim, 
      function ()
        if anim_state_transitioning == true then
          anim_state_transitioning = false
          if curr_anim.id == "spin" then
            curr_anim = trip_anim
            anim_state_transitioning = true
          elseif curr_anim.id == "trip" then
            curr_anim = spin_anim
            if loss_animation_begin == true then
              loss_animation_complete = true
            end
          end
        end
    end)
end

function update_mainmenu(dt)
  speed_line_video:play()
  update_animation(menu_anim, function () end)

  if menu_state.highlighted == "play" and menu_enter_pushed then
    menu_enter_pushed = false
    menu_state.level = "modeselect"
  elseif menu_state.highlighted == "settings" and menu_enter_pushed then
    menu_enter_pushed = false
    menu_state.level = "settings"
    menu_state.highlighted = "back"
  elseif menu_state.highlighted == "back" and menu_enter_pushed then
    menu_enter_pushed = false
    menu_state.level = "top"
    menu_state.highlighted = "play"
    menu_state.index = 1
  elseif menu_state.highlighted == "credits" and menu_enter_pushed then
    menu_enter_pushed = false
    menu_state.level = "credits"
    menu_state.highlighted = "back"
  elseif menu_state.highlighted == "high scores" and menu_enter_pushed then
    menu_enter_pushed = false
    menu_state.level = "high scores"
    menu_state.highlighted = "back"
  elseif menu_state.highlighted == "quit" and menu_enter_pushed then
    love.event.quit() 
  end
end

function love.update(dt)
    if meta_mode == "ingame" then
      update_ingame(dt)
    elseif meta_mode == "mainmenu" then
      update_mainmenu(dt)
    elseif meta_mode == "ingamepause" then
      -- This code just needs to be rearranged
      -- such that it can be called in here, but im tired
    elseif meta_mode == "scorescreen" then
      update_scorescreen(dt)
    end
end

function love.load()
    initial_bg_scroll_pos = 1400
    bg_scroll_pos = initial_bg_scroll_pos
    initial_bg_scroll_speed = 800
    bg_scroll_speed = initial_bg_scroll_speed
    initial_lives = 5
    lives = initial_lives
    loss_animation_complete = false
    loss_animation_begin = false
    escape_hit = false
    game_version = 0.1
    meanings_base_time = 3.0
    on_base_time = 6.0
    kun_base_time = 6.0
    base_time = 0.0 
    time_data = 0.0
    meta_mode = "mainmenu" -- ingame / ingamepause / mainmenu
    raw_time = 0.0
    initial_score = 0.0
    score_data = initial_score
    initial_bonus = 1.0
    bonus_data = initial_bonus
    num_attempts = 0.0
    current_group_index = 1 
    current_item_index = 0
    current_mode = "meanings"
    first_pass = true
    item_answered = false
    lhs_correct = false
    rhs_correct = false
    lhs_highlighted = false
    rhs_highlighted = false
    cooldown = false
    end_state_achieved = false
    anim_state_transitioning = false
    current_text = similar_kanji_data[current_group_index][current_item_index]
    current_lhs_text = ""
    current_rhs_text = ""
    settings_changed = false
    settings_file_path = "settings.txt"
    scores_file_path = "scores.txt"
    troubled_kanji_file_path = "troubled_kanji.txt"
    chalk_font_color = {0.8,0.8,0.8,0.8}
    font_color = {1.0,0.0,0.6}
    selected_font_color = {1.0, 0.99, 0.82}
    menu_bg_color = {0.2,0.2,0.2}
    user_choice_color = {0.8, 0.8, 0.8}
    user_unchoice_color = {0.6, 0.6, 0.6}

    itemdepth_values = {1, 2, 3}

    wklevel_values = {}
    for i=1,60 do table.insert(wklevel_values, i) end
   
    font_values = { }
    for i, file in ipairs(love.filesystem.getDirectoryItems("fonts/")) do
      table.insert(font_values, file)
    end

    troubled_kanji_state = load_troubled_kanji()
    current_game_mistakes = {}
    settings_state = load_settings()
    scores_state = load_scores()

    menu_state = { options = { "play", "settings", "high scores", "credits", "how to play", "quit" }, 
                   highlighted = "play", index = 1, level = "top" }
    menu_enter_pushed = false
    scorescreen_exit = false
    
    modeselect_menu_state = { options = { "meanings", "on", "kun", "back"},
                              highlighted = "meanings", index=1 }

    settings_menu_state = { options = {}, highlighted = "", index=0 }
    for k,v in pairs(settings_state) do
      table.insert(settings_menu_state.options, k)
    end
    table.insert(settings_menu_state.options, "back")
    settings_menu_state.index = #settings_menu_state.options
    settings_menu_state.highlighted = settings_menu_state.options[settings_menu_state.index]
    
    ingamemenu_state = { options = { "resume", "exit to main menu" },
                         highlighted = "resume", index = 1 }

    num_groups = x_kanji_groups
    kanji_font = love.graphics.newFont("fonts/" .. settings_state.kanjifont, get_kanji_scale_base())
    answer_font = love.graphics.newFont("fonts/" .. settings_state.kanjifont, get_kanji_font_scale())

    mini_frisco_ui_font = love.graphics.newFont("data/frisco.ttf", 24)
    frisco_ui_font = love.graphics.newFont("data/frisco.ttf", 48)
    mini_zen_ui_font = love.graphics.newFont("data/zen.ttf", 24)
    zen_ui_font = love.graphics.newFont("data/zen.ttf", 48)
    ui_font = love.graphics.newFont("data/seb.ttf", 64)
    small_ui_font = love.graphics.newFont("data/seb.ttf", 40)
    ingame_ui_font = love.graphics.newFont("data/seb.ttf", 30)

    bg_top = love.graphics.newImage("data/bg_1_1400w.png")
    bg_bot = love.graphics.newImage("data/bg_2_1400w.png")
    scoreboard = love.graphics.newImage("data/scoreboard.png")

    score_screen_video = love.graphics.newVideo("data/score_screen.ogv")
    speed_line_video = love.graphics.newVideo("data/speed_lines.ogv")

    idle_anim = make_animation("data/start/start", 8, 0.38, "idle")
    spin_anim = make_animation("data/spin/spin", 8, 0.33, "spin")
    trip_anim = make_animation("data/trip/trip", 14, 0.66, "trip")
    spin2_anim = make_animation("data/spin2/spin", 16, 0.33, "spin2")

    ingame_mistake_sound = make_sound("data/drop_001.ogg")
    ui_change_sound = make_sound("data/drop_002.ogg")
    ui_sound_scroll = make_sound("data/drop_003.ogg")

    curr_anim = spin_anim
    menu_anim = idle_anim

    data_stream = generate_kanji_data()
end

function keycheck_ingame(key)
  if key == "left" then
    lhs_highlighted = true
  else
    lhs_highlighted = false
  end

  if key == "right" then
    rhs_highlighted = true
  else
    rhs_highlighted = false
  end

  if lhs_highlighted and rhs_highlighted then
    lhs_highlighted = false
    rhs_highlighted = false
  end

  if key == "escape" then
    escape_hit = true 
  end
end

function scroll_highlight(menu, dir)
  if dir == "down" then  else v = -1 end

  local inc = 0 
  local reset = 0 
  local max = nil
   
  if dir == "down" then 
    reset = 1 
    inc = 1
    max = function (v) return v > #menu.options end
  else 
    reset = #menu.options 
    inc = -1
    max = function (v) return v < 1 end
  end

  ui_sound_scroll = play_sound(ui_sound_scroll)
  menu.index = menu.index + inc
  if max(menu.index) then
    menu.index = reset
  end
  
  menu.highlighted = menu.options[menu.index]
end

function keycheck_mainmenu(key)
  if key == "return" then
    menu_enter_pushed = true
  else 
    menu_enter_pushed = false
  end

  if (key == "down" or key == "up") then
    if menu_state.level == "top" then
      scroll_highlight(menu_state, key)
    elseif menu_state.level == "modeselect" then
      scroll_highlight(modeselect_menu_state, key)
    elseif menu_state.level == "settings" then
      scroll_highlight(settings_menu_state, key)
    end
  end

  if (key == "right" or key == "left") and menu_state.level == "settings" then
    local values = {}  
    local curr = settings_menu_state.highlighted 
    if curr == "itemdepth" then
      ui_change_sound = play_sound(ui_change_sound)
      values = itemdepth_values

      local f_i = 1
      local v = tonumber(settings_state[curr])
      for i=1,#itemdepth_values do 
        if v == tonumber(itemdepth_values[i]) then
          f_i = i 
        end
      end

      if key == "right" then
        f_i = f_i + 1 
        if f_i > #itemdepth_values then f_i = 1 end
      elseif key == "left" then
        f_i = f_i - 1 
        if f_i < 1 then f_i = #itemdepth_values end
      end
    
      settings_state[curr] = tonumber(itemdepth_values[f_i])
      update_kanji_fonts()

    elseif curr == "wklevel" then
      ui_change_sound = play_sound(ui_change_sound)
      values = wklevel_values
      local v = tonumber(settings_state[curr])
      local f_i = 1
      for i=1,#wklevel_values do 
        if v == wklevel_values[i] then 
          f_i = i 
        end
      end

      if key == "right" then
        f_i = f_i + 1 
        if f_i > #wklevel_values then f_i = 1 end
      end

      if key == "left" then
        f_i = f_i - 1 
        if f_i < 1 then f_i = #wklevel_values end
      end
    
      settings_state[curr] = wklevel_values[f_i]
      data_stream = generate_kanji_data()

    elseif curr == "sound" then
      ui_change_sound = play_sound(ui_change_sound)
      values = sound_values
      if settings_state[curr] == "on" then
        settings_state[curr] = "off" 
      else
        settings_state[curr] = "on"
      end

    elseif curr == "kanjifont" then
      ui_change_sound = play_sound(ui_change_sound)
      values = font_values 
      local v = settings_state[curr]
      local f_i = 1
      for i=1,#font_values do 
        if v == font_values[i] then 
          f_i = i 
        end
      end

      if key == "right" then
        f_i = f_i + 1 
        if f_i > #font_values then f_i = 1 end
      end

      if key == "left" then
        f_i = f_i - 1 
        if f_i < 1 then f_i = #font_values end
      end

      settings_state[curr] = font_values[f_i]
      update_kanji_fonts()
    end
    
  end
  
  if key == "return" and menu_state.level == "modeselect" then
    current_mode = modeselect_menu_state.highlighted

    if current_mode == "back" then
      menu_enter_pushed = false
      menu_state.level = "top"
      menu_state.highlighted = "play"
      menu_state.index = 1
    else
      if current_mode == "on" then
        base_time = on_base_time
      elseif current_mode == "kun" then
        base_time = kun_base_time
      else 
        base_time = meanings_base_time
      end

      menu_state.index = 1
      menu_state.level = "top"
      menu_state.highlighted = "play"
      menu_enter_pushed = false
      meta_mode = "ingame"
      first_pass = true
    end
  end
end

function keycheck_scorescreen(key)
  if key == "return" then
    scorescreen_exit = true
  end
end

function keycheck_ingamepause(key)
  if key == "down" or key == "up" then
    scroll_highlight(ingamemenu_state, key)
  end

  if key == "return" and ingamemenu_state.highlighted == "resume" then
    ingamemenu_state.index = 1
    ingamemenu_state.highlighted = ingamemenu_state.options[1]
    meta_mode = "ingame"
  end

  if key == "return" and ingamemenu_state.highlighted == "exit to main menu" then
    ingamemenu_state.index = 1
    ingamemenu_state.highlighted = ingamemenu_state.options[1]
    meta_mode = "scorescreen" 
  end
end

function love.keyreleased(key)
  if meta_mode == "ingame" then
    keycheck_ingame(key)
  elseif meta_mode == "mainmenu" then
    keycheck_mainmenu(key)
  elseif meta_mode == "ingamepause" then
    keycheck_ingamepause(key)
  elseif meta_mode == "scorescreen" then
    keycheck_scorescreen(key)
  end
end

function love.draw()
  local header_info = ""

  if meta_mode == "ingame" then
    draw_ingame({}, time_data, score_data)
  elseif meta_mode == "mainmenu" then
    header_info = header_info .. "v" .. game_version 
    draw_mainmenu()
  elseif meta_mode == "ingamepause" then
    draw_ingamepause()
  elseif meta_mode == "scorescreen" then
    draw_scorescreen()
  end
end

function love.quit()
  save_settings()
  save_scores()
  save_troubled_kanji()
end
