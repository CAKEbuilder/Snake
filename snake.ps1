# customizable values
$debug =                      0
$boardWidth =                 20
$speed =                      40   # controls sleep by milliseconds. the larger the number, the slower the speed

# definitions
$playArea =                   $boardWidth - 2   # - 1 for each of the vertical sides of the board (always 2)
$borderTopBottom =            "#" * $boardWidth
$frameCounter =               1   # would be cool to calculate FPS too
$playerInputX =               1   # we init at 1 instead of 0 to start the game with the snake moving right
$playerInputY =               0
$headPosX =                   8
$headPosY =                   1
$applePosX =                  0
$applePosY =                  0
$applePointValue =            5
$tailMax =                    ($playArea * $playArea)   # set the array length to the max theoretical tails that can be drawn on the board
$global:score =               0
$global:appleIsSpawned =      0
$global:canMoveLeft =         $false   # since we init the game with the snake moving right
$global:canMoveRight =        $true
$global:canMoveUp =           $true
$global:canMoveDown =         $true
$global:tailExists =          @(0) * $tailMax   # keeps track of which tails exist
$global:tailExists[0] =       1   # init the first three tails
$global:tailExists[1] =       1
$global:tailExists[2] =       1
$global:tailPosX =            @(0) * $tailMax
$global:tailPosY =            @(0) * $tailMax
$global:tailPosX[0] =         $headPosX - 1   # init the first three tail positions
$global:tailPosY[0] =         $headPosY
$global:tailPosX[1] =         $global:tailPosX[0] - 1
$global:tailPosY[1] =         $global:tailPosY[0]
$global:tailPosX[2] =         $global:tailPosX[1] - 1
$global:tailPosY[2] =         $global:tailPosY[1]
$global:numOfTails =          $global:tailExists.IndexOf(0)


# 1 = on. set "$breakHere = 1" anywhere you'd like to break
if($debug -eq 1) {
    Set-PSBreakpoint -Variable breakHere
}
else {
    # remove breakpoints, if any exists
    if(Get-PSBreakpoint) {
        Get-PSBreakpoint | Remove-PSBreakpoint
    }
}

# write output to the screen. used to Write/Clear-Host. this prevents the board from "flashing"
function Write-Buffer ([string] $str, [int] $x = 0, [int] $y = 0) {
      if($x -ge 0 -and $y -ge 0 -and $x -le [Console]::WindowWidth -and $y -le [Console]::WindowHeight) {
            $saveY = [console]::CursorTop
            $offY = [console]::WindowTop       
            [console]::setcursorposition($x,$offY+$y)
            Write-Host -Object $str -NoNewline
            [console]::setcursorposition(0,$saveY)
      }
}

# for cleaning up the console better when game over
function gameOver {

    write-buffer "game over - you hit $whatDidIHit!" 0 ($playArea + 10)

    # send blank lines until we're below everything we've drawn with write-buffer. makes the end experience of the game nicer, no overlap with the returned console position an old things drawn to the console
    for($h=0;$h -le ($playArea + 12);$h++) {
        write-host ""
    }
    exit

}

# draws the board
function board {
    
    # receive the newest x/y positions of the head
    param([int]$x, [int]$y)

    # anything in this section should be used to define the $offset
    # ---------
    $offset = 0   # $offset manages where we begin drawing the board. we increase offset for every row used in the header of the game. we'll start drawing the board below this offset
    Write-Buffer $frameCounter 0 0
    $offset++
    $tempString = "score: " + $score
    Write-Buffer $tempString 0 1
    $offset++
    $tempString = "number of tails: " + $global:numOfTails
    Write-Buffer $tempString 0 2
    $offset++
    # ---------

    # evaluate each row of the board, one at a time
    for($i=0;$i -le $playArea;$i++) {

        # check if the player eats the apple
        if(($x -eq $applePosX) -and ($y -eq $applePosY)) {
           
            # increase the score
            $global:score = $global:score + $applePointValue

            # disable the apple
            $global:appleIsSpawned = 0
            $applePosX = 0
            $applePosY = 0
            
            # spawn the next available tail by flipping the first 0 we find to a 1
            $b = $global:tailExists.IndexOf(0)
            $global:tailExists[$b] = 1

        }

        # create an array to represent the row. contains all spaces, we'll overwrite spaces with objects in a moment
        $row = @(" ") * ($playArea + 2)   # +2 to accomodate the left and right border padding

        $objectsInRow = @(" ") * ($playArea + 2)   # +2 to accomodate the left and right border padding


        # pad the row with the game border
        $row[0] = "#"
        $row[$playArea+1] = "#"

        # if an object exists in the current row (Y), place it in the array (row) using the object's X position

        # add the head, if it exists
        if($y -eq $i) {
            $row[$x] = "X"
            $objectsInRow[$x] = "X"
        }

        # add the apple, if it exists
        if($applePosY -eq $i) {
            $row[$applePosX] = "@"
        }

        # add any tails that exist
        for($d=0;$d -lt $tailMax;$d++) {
            if($global:tailPosY[$d] -eq $i) {
                $row[$global:tailPosX[$d]] = "o"
            }
        }

        # save the formatted row as $output
        $output = -join $row   # "-join" prints the array on one line

        # if we're on the first row, output the top border
        if($i -eq 0) {
            $output = $borderTopBottom
        }

        # write the output
        Write-Buffer $output 0 ($i + $offset)
        
    }

    # draw board bottom now that we're done looping through the playArea
    Write-Buffer $borderTopBottom 0 ($playArea + $offset + 1)   # + 1 because of the top border

    # detect game over (player hits the tail or the game border)
    # hit the tail (this is only possible while tail[3] or higher is enabled)
    for($a=3;$a -le $tailMax;$a++) {
        if(($x -eq $global:tailPosX[$a]) -and ($y -eq $global:tailPosY[$a])) {
            $whatDidIHit = "your tail"
            gameOver
        }
    }

    # hit the border
    if(($x -eq 0) -or ($x -eq ($playArea + 1)) -or ($y -eq 0) -or ($y -eq ($playArea + 1))) {
        $whatDidIHit = "the game border"
        gameOver
    }

    # update the number of tails (only used for reporting purposes)
    $global:numOfTails = $global:tailExists.IndexOf(0)

}

# clean the screen once before we begin playing
clear

# play! get user input, update the position of objects, call the board drawing function using new player coords
while(1 -eq 1) {

    # spawn the apple in a random, unused location
    if($global:appleIsSpawned -eq 0) {

        # loop until we've found an empty location
        # this might get very bogged down towards the end of a long game. another solution would be to keep track of all empty spaces and choose from the available ones at random
        $locationIsEmpty = $false
        while($locationIsEmpty -eq $false) {

            $applePosX = (Get-Random -min 1 -max $playArea)
            $applePosY = (Get-Random -min 1 -max $playArea)

            <# multidimensional array description
               eg, we try spawning $applePosX=6 and $applePosY=9, but $global:tailPosX contains a 6 in the same index that $global:tailPosY contains a 9.
               we write tail symbols "o" to $multi for each x and y coord of the tailPosX/Y combined.
               eg $multi[6,9] = "o", meaning this location on the board is not empty and we cannot spawn a new object here.
            #>

            # determine how big the multi array should be (exclude all the 0 positions, no need for them
            $multiSize = ($playArea * $playArea)

            # create the multi
            $multi = New-Object 'object[,]' $multiSize,$multiSize

            # populate the multi
            for($rrr=0;$rrr -le $multiSize;$rrr++) {
                $multi[$global:tailPosX[$rrr],$global:tailPosY[$rrr]] = "o"
            }

            # if we try spawning the apple in the head            
            if(($applePosX -eq $headPosX) -and ($applePosY -eq $headPosY)) {
                $locationIsEmpty = $false
            }
            # if we try spawning the apple in any of the enabled tail positions
            elseif($multi[$applePosX,$applePosY] -eq "o") {
                $locationIsEmpty = $false
            }
            # otherwise, this location is empty
            else {
                $locationisEmpty = $true
            }
        }
        
    # if we're here, then we've spawned the apple. make it edible
    $global:appleIsSpawned = 1

    }

    # get the player's input
    if ([console]::KeyAvailable) {
        $playerInput = [System.Console]::ReadKey() 
        switch ($playerInput.key) {
            UpArrow {
                # only allow the player to move up if the tail is not above the head (we are moving down)
                if($global:canMoveUp) {
                    $playerInputY=(-1)
                    # prevent diagonal movement and allow the continuous movement in the last known direction
                    $playerInputX=0
                    # free movement in all directions, besides the opposite
                    $global:canMoveUp    = $true
                    $global:canMoveLeft  = $true
                    $global:canMoveRight = $true
                    # restrict movement in the opposite direction
                    $global:canMoveDown  = $false
                }
            }
            LeftArrow {
                if($global:canMoveLeft) {
                    $playerInputX        = (-1)
                    $playerInputY        = 0
                    $global:canMoveLeft  = $true
                    $global:canMoveUp    = $true
                    $global:canMoveDown  = $true
                    $global:canMoveRight = $false
                }
            }
            RightArrow {
                if($global:canMoveRight) {
                    $playerInputX        = 1
                    $playerInputY        = 0
                    $global:canMoveRight = $true
                    $global:canMoveUp    = $true
                    $global:canMoveDown  = $true
                    $global:canMoveLeft  = $false
                }
            }
            DownArrow {
                if($global:canMoveDown) {
                    $playerInputY        = 1
                    $playerInputX        = 0
                    $global:canMoveRight = $true
                    $global:canMoveLeft  = $true
                    $global:canMoveDown  = $true
                    $global:canMoveUp    = $false
                }
            }
            Spacebar {
                $tempString = "game has been paused! press any key to resume"
                write-buffer $tempString 0 ($playArea + 5)
                [void][System.Console]::ReadKey()
                # clean the pause line
                $tempString = " " * $tempString.Length
                write-buffer $tempString 0 ($playArea + 5)
            }
        }
    } 

    # move the player
    # we do some stuff differently on the very first frame
    if($frameCounter -ne 1) {
        # update the position of each tail in reverse order, if the tail exists, except for on frame one
        for($f=$tailMax;$f -ge 3;$f--) {
            if($global:tailExists[$f]) {
                $global:tailPosX[$f] = $global:tailPosX[($f - 1)]
                $global:tailPosY[$f] = $global:tailPosY[($f - 1)]
            }
        }
            
        # tails 0-2 always exist
        for($g=2;$g -ge 0;$g--) {
            if($g -ne 0) {
                $global:tailPosX[$g] = $global:tailPosX[($g-1)]
                $global:tailPosY[$g] = $global:tailPosY[($g-1)]
            }
            else {
                $global:tailPosX[0] = $headPosX
                $global:tailPosY[0] = $headPosY
            }
        }

        # move the player. we skip this on the first frame since we handle this elsewhere
        $headPosX = $headPosX + $playerInputX
    }
    
    # update Y
    $global:tailPosY[0] = $headPosY
    $headPosY = $headPosY + $playerInputY
  
    board -x $headPosX -y $headPosY

    sleep -Milliseconds $speed
    $frameCounter++

}
