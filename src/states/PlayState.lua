PlayState = Class{__includes = BaseState}

function PlayState:enter(params)
  self.paddle = params.paddle
  self.bricks = params.bricks
  self.health = params.health
  self.score = params.score
  self.ball = params.ball
  self.level = params.level
  self.highScores = params.highScores

  self.ball.dx = math.random(-200, 200)
  self.ball.dy = math.random(-50, -60)
end

function PlayState:update(dt)
  if self.paused then
    if love.keyboard.wasPressed('space') then
      self.paused = false
      gSounds['pause']:play()
    else
      return
    end
  elseif love.keyboard.wasPressed('space') then
    self.paused = true
    gSounds['pause']:play()
    return
  end

  self.paddle:update(dt)
  self.ball:update(dt)

  if self.ball:collides(self.paddle) then
    -- get ball outside paddle hitbox
    self.ball.y = self.paddle.y - 8

    self.ball.dy = -self.ball.dy

    -- adjust angle at which ball bounces off paddle
    if self.ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
      self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))
    elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
      self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
    end

    gSounds['paddle-hit']:play()
  end

  for k, brick in pairs(self.bricks) do
    if brick.inPlay and self.ball:collides(brick) then
      self.score = self.score + (brick.tier * 200 + brick.color * 25)

      if (0 == self.score % 1000) then
        if self.paddle.size < 4 then
          self.paddle.size = self.paddle.size + 1
        end
      end

      brick:hit()

      if self:checkVictory() then
        gSounds['victory']:play()

        gStateMachine:change('victory', {
          level = self.level,
          paddle = self.paddle,
          health = self.health,
          score = self.score,
          ball = self.ball,
          highScores = self.highScores
        })
      end

      -- handle collisions from each of the four sides
      -- left edge
      if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
        self.ball.dx = -self.ball.dx
        self.ball.x = brick.x - 8
      -- right edge
      elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then
        self.ball.dx = -self.ball.dx
        self.ball.x = brick.x + 32
      -- top edge
      elseif self.ball.y < brick.y then
        self.ball.dy = -self.ball.dy
        self.ball.y = brick.y - 8
      -- bottom edge
      else
        self.ball.dy = -self.ball.dy
        self.ball.y = brick.y + 16
      end

      -- scale up y velocity
      if math.abs(self.ball.dy) < 150 then
        self.ball.dy = self.ball.dy * 1.02
      end

      -- only allow one hit per brick
      break
    end
  end

  -- handle losing health if ball goes below screen
  if self.ball.y >= VIRTUAL_HEIGHT then
    self.health = self.health - 1
    gSounds['hurt']:play()
    if self.paddle.size > 1 then
      self.paddle.size = self.paddle.size - 1
    end

    if self.health == 0 then
      gStateMachine:change('game-over', {
        score = self.score,
        highScores = self.highScores
      })
    else
      gStateMachine:change('serve', {
        paddle = self.paddle,
        bricks = self.bricks,
        health = self.health,
        score = self.score,
        level = self.level,
        highScores = self.highScores
      })
    end
  end

  for k, brick in pairs(self.bricks) do
    brick:update(dt)
  end

  if love.keyboard.wasPressed('escape') then
    love.event.quit()
  end
end

function PlayState:render()
  -- render bricks
  for k, brick in pairs(self.bricks) do
    brick:render()
  end

  -- render particles
  for k, brick in pairs(self.bricks) do
    brick:renderParticles()
  end

  self.paddle:render()
  self.ball:render()

  renderScore(self.score)
  renderHealth(self.health)

  if self.paused then
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('PAUSED', 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
  end
end

function PlayState:checkVictory()
  for k, brick in pairs(self.bricks) do
    if brick.inPlay then
      return false
    end
  end

  return true
end
