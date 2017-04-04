
# definitions

$debug                   = 0
$boardWidth              = 32
$playArea                = $boardWidth - 2   # - 1 for each of the vertical sides of the board (always 2)
$borderTopBottom	     = "#" * $boardWidth
$frameCounter 		     = 1   # would be cool to calculate FPS too
$playerInputX 		     = 1   # we init at 1 instead of 0 to start the game with the snake moving right
$playerInputY 		     = 0
$headPosX 		         = 8
$headPosY 		         = 1
$applePosX 			     = 0
$applePosY 			     = 0
$applePointValue 	     = 5
$tailMax 			     = ($playArea * $playArea)   # set the array length to the max theoretical tails that can be drawn on the board
$global:score 		     = 0
$global:numOfTails 	     = 3
$global:appleIsSpawned   = 0
$global:canMoveLeft 	 = $false   # since we init the game with the snake moving right
$global:canMoveRight 	 = $true
$global:canMoveUp 		 = $true
$global:canMoveDown 	 = $true
$global:tailExists       = @(0) * $tailMax   # keeps track of which tails exist
$global:tailExists[0]    = 1   # init the first three tails
$global:tailExists[1]    = 1
$global:tailExists[2]    = 1
$global:tailPosX         = @(0) * $tailMax
$global:tailPosY         = @(0) * $tailMax
$global:tailPosX[0] 	 = $headPosX - 1   # init the first three tail positions
$global:tailPosY[0]      = $headPosY
$global:tailPosX[1]      = $global:tailPosX[0] - 1
$global:tailPosY[1]      = $global:tailPosY[0]
$global:tailPosX[2] 	 = $global:tailPosX[1] - 1
$global:tailPosY[2] 	 = $global:tailPosY[1]


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

# for debugging. we can call this function to manually set a desired number of tails. eg: "setTails -tails 6", would set the tail count to 6
function setTails {
    param([int]$tails)
    "adding " + $tails + " tails to the snake."
    for($c=0;$c -le $tailMax;$c++) {
        if($c -le $tails) {
            $global:tailExists[$c] = 1
        }
        else {
            $global:tailExists[$c] = 0
        }
    }
}

# check how many tails are enabled. use this for reporting and other things like determining which tail is the last one currently enabled
function numOfTails {
    
    # $global:tailExists.IndexOf(0) will return the position of the first 0, which happens to be equal to the total number of tails that are enabled
    $global:numOfTails = $global:tailExists.IndexOf(0)

}

# draws the board
function board {
    
    # receive the newest x/y positions of the head
    param([int]$x, [int]$y)

    # for debugging
    # anything in this section should be used to define the $offset
    # ---------
    Write-Buffer $frameCounter 0 0
    $tempString = "score: " + $score
    Write-Buffer $tempString 0 1
    $tempString = "number of tails: " + $global:numOfTails
    Write-Buffer $tempString 0 2
    $tempString = "headPosX: " + $headPosX
    Write-Buffer $tempString 0 3
    $tempString = "headPosY: " + $headPosY
    Write-Buffer $tempString 0 4
    # ---------

    # offset where we begin drawing the board. since above we are setting three header elements, set $offset = 3. we'll start drawing the board below this offset
    $offset = 5

    # draw the board loop (checks for point score, determines object postions, ect)
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


        # this is a new method for determining which objects exist in a row and drawing them. the old way was difficult to understand and redundant. this takes much less effort to accomplish the same goal

        # create a temp array for all objects in the row
        $objectsInRow = @(" ") * ($playArea + 2)   # instead of $null, use " ". we'll just overwrite spaces with any objects we find as we find them

        # pad the row with the game border
        $objectsInRow[0] = "#"
        $objectsInRow[31] = "#"

        # if an object exists in this row (Y), place it in the array using the object's X position (overwritting spaces as needed)

        # add the head, if it exists
        if($y -eq $i) {
            $objectsInRow[$x] = "X"
        }
        # add the apple, if it exists
        if($applePosY -eq $i) {
            $objectsInRow[$applePosX] = "@"
        }

        # add any tails that exist
        for($d=0;$d -lt $playArea;$d++) {
            if($global:tailPosY[$d] -eq $i) {
                $objectsInRow[$global:tailPosX[$d]] = "o"
            }
        }

        # save the formatted row as $output
        $output = -join $objectsInRow   # "-join" prints the array on one line (horizontally)


        # if we're on the first row, set the output to the top border
        if($i -eq 0) {
            $output = $borderTopBottom
        }

        # write the output
        Write-Buffer $output 0 ($i + $offset)
        
    }

    # draw board bottom now that we're done looping through the playArea
    Write-Buffer $borderTopBottom 0 ($playArea + $offset + 1)   # + 1 because of the top border

    # update the numOfTails
    numOfTails

    # detect game over (hit tail or border)
    # hit the tail (this is only possible while tail[3] or higher is enabled)
    for($a=3;$a -le $tailMax;$a++) {
        if(($x -eq $global:tailPosX[$a]) -and ($y -eq $global:tailPosY[$a])) {
            write-buffer "game over - you hit your tail!" 0 ($playArea + 10)   # I chose this value at random. I just happen to know that it is below the board. should use one of the defined board size variables to set this instead...
            exit
        }
    }

    # hit the border
    if(($x -eq 0) -or ($x -eq ($playArea + 1)) -or ($y -eq 0) -or ($y -eq ($playArea + 1))) {
        write-buffer "game over - you hit the game border!" 0 ($playArea + 10)
        exit
    }
}

# clean the screen once before we begin playing
clear

# play! get user input, update the position of objects, call the board drawing function using new player coords
while(1 -eq 1) {

    # apple
    # spawn the apple in a random, unused location
    if($global:appleIsSpawned -eq 0) {
        $applePosX = (Get-Random -min 1 -max 30)
        $applePosY = (Get-Random -min 1 -max 30)
        # you need to put the verification of the apple being in the player/tail pos' in a loop. eg, if the apple spawns in the head and you move it, verify that you didn't move it into a tail pos. also check if the apple spawns in a tail and you move it, that its not in the head pos.
        # { ---------
        # don't let the apple spawn in the player's pos. if it tries to, move it
        if($applePosX -eq $x) {
            if($applePosX -eq $playArea) {
                $applePosX = $applePosX - 1
            }
            if($applePosX -eq 1) {
                $applePosX = $applePosX + 1
            }
        }
        if($applePosY -eq $y) {
            if($applePosY -eq $playArea) {
                $applePosY = $applePosY - 1
            }
            if($applePosY -eq 1) {
                $applePosY = $applePosY + 1
            }
        }
        # don't let the apple spawn in any of the tail positions. if it tries to, move it
        for($e=0;$e -le $tailMax;$e++) {
            if($applePosX -eq $global:tailPosX[$e]) {
                if($applePosX -eq $playArea) {
                    $applePosX = $applePosX - 1
                }
                if($applePosX -eq 1) {
                    $applePosX = $applePosX + 1
                }
            }
            if($applePosY -eq $global:tailPosY[$e]) {
                if($applePosY -eq $playArea) {
                    $applePosY = $applePosY - 1
                }
                if($applePosX -eq 1) {
                    $applePosY = $applePosY + 1
                }
            }
        }
        # } ---------

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
    
    # I don't really get this
    $global:tailPosY[0] = $headPosY
    $headPosY = $headPosY + $playerInputY
  
    board -x $headPosX -y $headPosY

    # the new version plays way too fast
    sleep -Milliseconds 50
    $frameCounter++


}
