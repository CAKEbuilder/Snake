
# definitions

$debug = 0
# if debug = 1 (on), pressing the spacebar will enter debug and allow us to poke around.
if($debug -eq 1) {
    Set-PSBreakpoint -Variable breakHere
}
else {
    # remove the breakpoint, if it exists
    if(Get-PSBreakpoint) {
        # need to clean this up
        Remove-PSBreakpoint -Id 0
        Remove-PSBreakpoint -Id 1
        Remove-PSBreakpoint -Id 2
    }
}
$boardWidth = 32
$playArea = $boardWidth - 2   # - 1 for each of the vertical sides of the board (always 2)
$borderTopBottom = "#" * $boardWidth
$frameCounter = 1   # would be cool to calculate FPS too
$playerInputX = 1   # we init at 1 instead of 0 to start the game with the snake moving right
$playerInputY = 0
$playerPosX = 8
$playerPosY = 1
$applePosX = 0
$applePosY = 0
$applePointValue = 5
$global:score = 0
$global:numOfTails = 3
$global:appleIsSpawned = 0
$global:canMoveLeft = $false   # since we init the game with the snake moving right
$global:canMoveRight = $true
$global:canMoveUp = $true
$global:canMoveDown = $true
# define the max count of tails that can possibly be spawned. this is used to dynamically determine pretty much everything now; distance, objects, array lengths, ect. the greater this value is, the more things need to loop, slowing down the speed of the game. this is the biggest problem that exists currently. we ultimately need to support the max number of tails that can theoretically fit in the play space, and have it not impact performance.
$tailMax = 20
$global:tailExists = @()
$global:tailPosX = @()
$global:tailPosY = @()
# define the length of these arrays
for($aa=0;$aa -le $tailMax;$aa++) {
    $global:tailPosX += $null
    $global:tailPosY += $null
}
# [0] is the first tail position
$global:tailPosX[0] = $playerPosX - 1
$global:tailPosY[0] = $playerPosY
$global:tailPosX[1] = $global:tailPosX[0] - 1
$global:tailPosY[1] = $global:tailPosY[0]
$global:tailPosX[2] = $global:tailPosX[1] - 1
$global:tailPosY[2] = $global:tailPosY[1]
# $global:tailExists keeps track of which tail positions exist
#   tails 0-2 always exist. every other tail needs to be disabled at start, and enabled with each apple eaten.
#   the first three positions are always 1, then we dynamically add 0 as we expand $tailMax
for($bb=0;$bb -le $tailMax;$bb++) {
    if($bb -le 2) {
        $global:tailExists += 1
    }
    else {
        $global:tailExists += 0
        $global:tailPosX[$bb] = 0
        $global:tailPosY[$bb] = 0
    }
}


# for debugging. we can call this function to manually set a desired number of tails.
#   usage: "setTails -tails 6", would set the tail count to 6
function setTails {
    param([int]$tails)
    "adding " + $tails + " tails to the snake."
    for($mm=0;$mm -le $tailMax;$mm++) {
        if($mm -le $tails) {
            $global:tailExists[$mm] = 1
        }
        else {
            $global:tailExists[$mm] = 0
        }
    }
}

# get the number of tails that are enabled so we can inform the player how well they're doing
# we also use this (-1) to determine if we're on the last tail. currently only to set the last tail's symbol to something other than "o"
function numOfTails {
    for($ll=0;$ll -le ($global:tailExists.Length);$ll++) {
        if($global:tailExists[$ll] -eq 0) {
            $global:numOfTails = $ll
            break
        }
    }
}


# function to draw the board
function board {
    
    # receive the newest x/y positions of the head
    param([int]$x, [int]$y)

    # for debugging
    $frameCounter

    # score and tail count
    write-host "score:" $score
    write-host "number of tails:" $global:numOfTails


    # draw board top
    $borderTopBottom

    # draw the board, inserting the head/tail/apple as needed
    for($i=1;$i -le $playArea;$i++) {

        # score if player gets the apple
        if(($x -eq $applePosX) -and ($y -eq $applePosY)) {
            # increase the score
            $global:score = $global:score + $applePointValue

            # handle the apple
            $global:appleIsSpawned = 0
            $applePosX = 0
            $applePosY = 0

            # spawn the next tail, if it doesn't already exist
            for($u=3;$u -le $tailMax;$u++) {
                if($global:tailExists[$u] -eq 0) {
                    $global:tailExists[$u] = 1
                    # break once we set the first available 0 to 1. otherwise, we'd enable all the tails on one score of the apple
                    break
                }
            }
        }

        # reset the objs and tmps
        # initialize/reset $obj
        $obj = @()
        for($dd=0;$dd -le $tailMax;$dd++) {   # double d's. heh
            $obj += $null
        }
        
        $tmp = @()
        $tmpSymbol = @()
        $tmpPosX = @()



        # set tmp values for every object that exists in the current row. afterwards, we'll sort this array and determine the order of appearance of each object
        for($m=0;$m -le $playArea;$m++) {
            # set the head if needed
            # we parse the entire array for the object. eg, if the array doesn't already contain the object we're attempting to set, then set the object.
            if(($i -eq $y) -and ($tmp -notcontains "head")) {
                $tmpSymbol += "X"
                $tmpPosX += $x
                $tmp += "head"
            }
            # set the apple if needed
            elseif(($i -eq $applePosY) -and ($tmp -notcontains "apple")) {
                $tmpSymbol += "@"
                $tmpPosX += $applePosX
                $tmp += "apple"
            }
            # set the tail if needed. this is in its own if deatched from the head/apple check in case the head and tail0 are in the same row. before, when doing if/elseif/elseif, if the head was in the row, we used $m=0 to assign the head, then $m++. we couldn't set $tail[0] when $m=0 if the head was in this row as well. this solves that issue.
            if(($i -eq $global:tailPosY[$m]) -and ($tmp -notcontains "tail$m")) {
                # use "o" as the tail symbol, except for the very last tail (purley for asthetic purposes)
                if($m -eq ($global:numOfTails - 1)) {
                    $tmpSymbol += "t"
                }
                else {
                    $tmpSymbol += "o"
                }
                $tmpPosX += $global:tailPosX[$m]
                $tmp += "tail$m"
            }
            # if we haven't set anything here, $null. this used to be the else in the if/elseif/elseif. now we check this at the end of it all, since we broke up the steps into multiple ifs.
            if(!$tmp[$m]) {
                $tmpSymbol += $null
                $tmpPosX += 0
                $tmp += $null
            }
        }


        # need to order the tmps now so we can assign them.
        # init/reset the array, populate it, then sort it
        $a = @()
        for($ee=0;$ee -le $tailMax;$ee++) {
            $a += $tmpPosX[$ee]
        }
        
        $a = $a | Sort-Object

        # define the official objs, in order, now that we're done with the tmps
        $objPosX = @()
        for($n=0;$n -le $tailMax;$n++) {
            $objPosX += $a[$n]
        }

        # init/reset the array, then populate it
        $objSymbol = @()
        for($ff=0;$ff -le $tailMax;$ff++) {
            $objSymbol += $null
        }
        

        # set up each obj and objSymbol, now that we have the order
        for($r=0;$r -le $tailMax;$r++) {
            for($s=0;$s -le $tailMax;$s++) {
                if($objPosX[$s] -eq $tmpPosX[$r]) {
                    $obj[$s] = $tmp[$r]
                    $objSymbol[$s] = $tmpSymbol[$r]
                }
            }
        }

        $breakpoint=1


        # if the objs are empty
        for($z=0;$z -le $tailMax;$z++) {
            if(!$obj[$z]) {
                $objSymbol[$z] = $null
                $objPosX += 0
            }
        }

        # now that the objs are set, define the distances between each
        # init/reset the array, then populate it
        $distance = @()
        for($gg=0;$gg -le ($playArea);$gg++) {   # heh, gg
            $distance += $null
        }

        # get the distances between each object that we're drawing in the same row
        for($t=0;$t -le ($playArea);$t++) {
            # we do it slightly differently for the first and last distances
            
            # first
            if($t -eq 0) {
                $distance[$t] = $objPosX[0]
            }
            # last
            elseif($t -eq ($playArea)) {
                $distance[$t] = $playArea - $objPosX[($tailMax)]
            }
            # everything else
            else {
                $distance[$t] = $objPosX[$t] - $objPosX[$t-1]
            }

            # check for problems
            if($distance[$t] -eq 0) {
                $distance[$t] = 1
            }

            # if the result is negative, convert to positive by multiplying it by -1 (you had to look this up hahah what a loser)
            if($distance[$t] -lt 0) {
                $distance[$t] = $distance[$t] * (-1)
            }
        }


        # this is the heart of the script. write objects in the row, if any exist
        #   remember that " " is now an object, where in previous versions, only head/apple/tail were objects.
        #   we will store the information to write in a variable, $output. once it is complete, we'll draw it on the screen
        $output = "#"
        for($ii=0;$ii -le $tailMax;$ii++) {
            $output += (" " * ($distance[$ii] - 1) + $objSymbol[$ii])
        }

        # add the last piece of the line
        # if an object is in the furthest right space in the playArea, then just end the play area with the side border. no need to draw a space.
        # this is +1 because we use the width of the playArea + the one "#" used for the left border
        if ($output.Length -eq ($playArea + 1)) {
             $output += "#"
        }
        # for every other case where an object is not in the furthest right position, draw spaces until we hit the border, then draw the border
        else {
            $output += (" " * ($distance[($playArea)])) + "#"
        }

        # write the line
        $output
    }

  
    # draw board bottom
    $borderTopBottom

    # debug
    # update the numOfTails
    numOfTails

    # detect game over
    #  if the player hits the tail. this can only happen on tail[3] or higher
    for($a=3;$a -le $tailMax;$a++) {
        if(($x -eq $global:tailPosX[$a]) -and ($y -eq $global:tailPosY[$a])) {
            write-host "game over - you hit your tail!"
            exit
        }
    }
    #  if the player hits the game border
    if(($x -eq 0) -or ($x -eq ($playArea + 1)) -or ($y -eq 0) -or ($y -eq ($playArea + 1))) {
        write-host "game over - you hit the game border!"
        exit
    }

}






# play
# get user input, draw the board, move the objects
while(1 -eq 1) {

    # apple
    # randomly find an unused location on the board to spawn in, if the apple is not yet spawned
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
        for($jj=0;$jj -le $tailMax;$jj++) {
            if($applePosX -eq $global:tailPosX[$jj]) {
                if($applePosX -eq $playArea) {
                    $applePosX = $applePosX - 1
                }
                if($applePosX -eq 1) {
                    $applePosX = $applePosX + 1
                }
            }
            if($applePosY -eq $global:tailPosY[$jj]) {
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
                    $global:canMoveUp = $true
                    $global:canMoveLeft = $true
                    $global:canMoveRight = $true
                    # restrict movement in the opposite direction
                    $global:canMoveDown = $false

                }
            }
            LeftArrow {
                if($global:canMoveLeft) {
                    $playerInputX=(-1)
                    $playerInputY=0
                    $global:canMoveLeft = $true
                    $global:canMoveUp = $true
                    $global:canMoveDown = $true
                    $global:canMoveRight = $false
                }
            }
            RightArrow {
                if($global:canMoveRight) {
                    $playerInputX=1
                    $playerInputY=0
                    $global:canMoveRight = $true
                    $global:canMoveUp = $true
                    $global:canMoveDown = $true
                    $global:canMoveLeft = $false
                }
            }
            DownArrow {
                if($global:canMoveDown) {
                    $playerInputY=1
                    $playerInputX=0
                    $global:canMoveRight = $true
                    $global:canMoveLeft = $true
                    $global:canMoveDown = $true
                    $global:canMoveUp = $false
                }
            }
            # allows us to enter debugging (only when $debug = 1)
            Spacebar {
                $breakHere = 1
            }
        }
    } 

    # move the player
    # we do some stuff differently on the very first frame
    if($frameCounter -ne 1) {
        # set the position of the tails (in reverse order), if the tail exists, except for on frame one (when the game initializes)
        for($hh=$tailMax;$hh -ge 3;$hh--) {
            if($global:tailExists[$hh]) {
                $global:tailPosX[$hh] = $global:tailPosX[($hh - 1)]
                $global:tailPosY[$hh] = $global:tailPosY[($hh - 1)]
            }
        }
            
        # these tails always exists
        # tails 0-2 always exist
        for($kk=2;$kk -ge 0;$kk--) {
            if($kk -ne 0) {
                $global:tailPosX[$kk] = $global:tailPosX[($kk-1)]
                $global:tailPosY[$kk] = $global:tailPosY[($kk-1)]
            }
            else {
                $global:tailPosX[0] = $playerPosX
                $global:tailPosY[0] = $playerPosY
            }
        }

        # move the player. we skip this on the first frame since we handle this elsewhere
        $playerPosX = $playerPosX + $playerInputX
    }
    
    # I don't really get this
    $global:tailPosY[0] = $playerPosY
    $playerPosY = $playerPosY + $playerInputY
  
    clear
    board -x $playerPosX -y $playerPosY
    #Sleep -m 100
    Sleep -m 20
    $frameCounter++

}
