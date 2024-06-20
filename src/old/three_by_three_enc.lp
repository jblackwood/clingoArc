#const lastTimestep=2.
#const gridSize=2.
#const maxNumObjects=1.

% there are two colors
color(red;black).

% background is a single color
{background(Color) : color(Color)}=1. 

% there are 1..maxNumObjects
% obj(ObjId) :- ObjId=1..maxNumObjects.
obj(a).

% color at timestep 1 is the input color
color(Row, Col, 1, Color) :- inputColor(Row, Col, Color).

% color at final timestep is the outputcolor
color(Row, Col, lastTimestep, Color) :- outputColor(Row, Col, Color).

% A given (row, col, timestep) can only be occupied by at most 1 object
{occupiedBy(Row, Col, T, ObjId) : obj(ObjId)} 1 :- 
    Row=1..gridSize,
    Col=1..gridSize,
    T=1..lastTimestep.

% If color is not the background color, that row, col must be occupied by an object
occupiedBy(Row, Col, T, ObjId) :- 
    color(Row, Col, T, Color1),
    background(Color2),
    Color1 != Color2,
    obj(ObjId).

% If a (row, col) is not occupied it is the background color
color(Row, Col, T, BgColor) :- 
    not occupiedBy(Row, Col, T, _),
    T=1..lastTimestep,
    Row=1..gridSize,
    Col=1..gridSize,
    background(BgColor).

% can't have a row, col occupied and be the background color
:- occupiedBy(Row, Col, T, ObjId),
   color(Row, Col, T, BgColor),
   background(BgColor),
   obj(ObjId).

% A max of one object can be moved right at each timestep.
{moveRight(ObjId, T): obj(ObjId)}=1 :- T=1..(lastTimestep-1).

% If you move an object to the right, it occupies that (row, col) at next timestep
occupiedBy(Row, Col+1, T+1, ObjId) :- 
    moveRight(ObjId, T), 
    occupiedBy(Row, Col, T, ObjId), 
    T=1..lastTimestep.

% Move colors if object is moved
color(Row, Col+1, T+1, Color) :- 
    moveRight(ObjId, T), 
    occupiedBy(Row, Col, T, ObjId),
    color(Row, Col, T, Color),
    T=1..lastTimestep.
