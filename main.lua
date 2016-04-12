-- Load some default values for our rectangle.
function love.load()
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px
    world = love.physics.newWorld(0, 9.81*64, true) --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81

    objects = {} -- table to hold all our physical objects

    --let's create the ground
    objects.ground = {}
    objects.ground.body = love.physics.newBody(world, 650/2, 650-50/2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    objects.ground.shape = love.physics.newRectangleShape(650, 50) --make a rectangle with a width of 650 and a height of 50
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape); --attach shape to body

    --let's create a couple blocks to play around with
    objects.block1 = {}
    objects.block1.body = love.physics.newBody(world, 200, 550, "dynamic")
    objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
    objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5) -- A higher density gives it more mass.

    objects.block2 = {}
    objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
    objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
    objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 2)

    -- Softbody
    particleNumber = 16;
    particleDistance = 50;

    objects.core = createSphere(650/2, 650/2, 20)
    objects.nodes = {};

    for i=1, particleNumber do
        local angle = (2 * math.pi) / particleNumber * i
        local posX = (650/2) + particleDistance * math.cos(angle)
        local posY = (650/2) + particleDistance * math.sin(angle)
        local b = createSphere(posX,posY,2)
        local j = love.physics.newDistanceJoint(objects.core.body, b.body, posX, posY, posX, posY, false);
		j:setDampingRatio(0.5);
		j:setFrequency(12*(30/particleDistance));

        table.insert(objects.nodes, b)
    end

    -- connect nodes to eachother
    for i=1, #objects.nodes do
        if i == #objects.nodes then
            local b1 = objects.nodes[i].body
            local b2 = objects.nodes[1].body
            local j2 = love.physics.newDistanceJoint( b1, b2,
                b1:getX(), b1:getY(),
                b2:getX(), b2:getY(), false )
        elseif i > 0 then
            local b1 = objects.nodes[i].body
            local b2 = objects.nodes[i+1].body
            local j2 = love.physics.newDistanceJoint( b1, b2,
                b1:getX(), b1:getY(),
                b2:getX(), b2:getY(), false )
        end
    end

    --initial graphics setup
    -- love.graphics.setBackgroundColor(104, 136, 248) --set the background color to a nice blue
    love.window.setMode(650, 650) --set the window dimensions to 650 by 650
end

-- Increase the size of the rectangle every frame.
function love.update(dt)
    world:update(dt) --this puts the world into motion

    --here we are going to create some keyboard events
    if love.keyboard.isDown("right") then --press the right arrow key to push the ball to the right
        objects.core.body:applyForce(200, 0)
        objects.core.body:applyTorque( 5000 )
    elseif love.keyboard.isDown("left") then --press the left arrow key to push the ball to the left
        objects.core.body:applyForce(-200, 0)
        objects.core.body:applyTorque( -5000 )
    end

    if love.keyboard.isDown("up") then
        objects.core.body:setPosition(650/2, 650/2)
        objects.core.body:setLinearVelocity(0, 0) --we must set the velocity to zero to prevent a potentially large velocity generated by the change in position

        for i,v in ipairs(objects.nodes) do
            local angle = (2 * math.pi) / #objects.nodes * i
            local posX = (650/2) + particleDistance * math.cos(angle)
            local posY = (650/2) + particleDistance * math.sin(angle)
            v.body:setX(posX)
            v.body:setY(posY)
            v.body:setLinearVelocity(0, 0)
        end
    end
end

-- Draw a coloured rectangle.
function love.draw()
    -- love.graphics.setWireframe( true )
    love.graphics.setColor(72, 160, 14) -- set the drawing color to green for the ground
    love.graphics.polygon("fill", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates

    -- love.graphics.setColor(193, 47, 14) --set the drawing color to red for the ball
    -- love.graphics.circle("fill", objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.shape:getRadius())

    love.graphics.setColor(193, 47, 14) --set the drawing color to red for the ball

    -- Softbody
    drawSoftbody()

    love.graphics.setColor(50, 50, 50) -- set the drawing color to grey for the blocks
    love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
    love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))
end

function createSphere(pX, pY,r)
    local sphere = {}
    sphere.body = love.physics.newBody(world, pX, pY, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
    sphere.shape = love.physics.newCircleShape(r) --the ball's shape has a radius of 20
    sphere.fixture = love.physics.newFixture(sphere.body, sphere.shape, 1) -- Attach fixture to body and give it a density of 1.
    return sphere
end

function drawSoftbody()
    -- Softbody
    love.graphics.circle("fill", objects.core.body:getX(), objects.core.body:getY(), objects.core.shape:getRadius())
    for i,b in ipairs(objects.nodes) do
      love.graphics.circle("fill", b.body:getX(), b.body:getY(), b.shape:getRadius())
    end

    -- get node locations

    local vertices = getSoftbodyVertices()

    -- passing the table to the function as a second argument
    love.graphics.setLineStyle("smooth");
	love.graphics.setLineWidth(2*2) -- radius of the nodes around the center body. This is double to cover the entire physical space
    -- love.graphics.polygon("fill", vertices)
    love.graphics.polygon("line", vertices)

    love.graphics.setLineWidth(1)
end

function getSoftbodyVertices()
    local vert = {}
    for i,v in ipairs(objects.nodes) do
        table.insert(vert, v.body:getX())
        table.insert(vert, v.body:getY())
    end
    return vert
end
