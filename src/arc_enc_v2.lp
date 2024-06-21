% A cell is populated if it has a y, x, or color
isPopulated(CellId) :-
    y(CellId, _).

isPopulated(CellId) :-
    x(CellId, _).

isPopulated(CellId) :-
    color(CellId, _).

% An object is populated if it has a populated cell
isPopulated(ObjId) :-
    isPopulated(CellId),
    cellList(ObjId, _, CellId).


% copyCell
y(Id2, Val) :-
    copyCell(Id1, Id2),
    y(Id1, Val).

x(Id2, Val) :-
    copyCell(Id1, Id2),
    x(Id1, Val).

color(Id2, Val) :-
    copyCell(Id1, Id2),
    color(Id1, Val).

% copyCellXY
y(Id2, Val) :-
    copyCellXY(Id1, Id2),
    y(Id1, Val).

x(Id2, Val) :-
    copyCellXY(Id1, Id2),
    x(Id1, Val).


% copyCellToObject copies the cell into one of the objects cells
{copyCell(CellId1, CellId2) : cellList(ObjId1, _, CellId2)}=1 :-
    copyCellToObject(CellId1, ObjId1).

% copyCellToObject can only copy once to a given cell
:-
    copyCellToObject(_, ObjId),
    cellList(ObjId, _, TargetCell),
    copyCell(CellId1, TargetCell),
    copyCell(CellId2, TargetCell),
    CellId1 != CellId2.


% Populate cellList in order. A populated cell should always have an x.
:- 
    type(Id, object),
    cellList(Id, N1, CellId1),
    cellList(Id, N2, CellId2),
    N1 > N2,
    isPopulated(CellId1),
    not isPopulated(CellId2).

% Populate cellList of object in order of y, and then x within each y. Else populate by color order
:-
    type(Id, object),
    cellList(Id, N1, CellId1),
    cellList(Id, N2, CellId2),
    y(CellId1, Y1),
    y(CellId2, Y2),
    N1<N2,
    Y1>Y2.

:-
    type(Id, object),
    cellList(Id, N1, CellId1),
    cellList(Id, N2, CellId2),
    y(CellId1, Y),
    y(CellId2, Y),
    x(CellId1, X1),
    x(CellId2, X2),
    N1<N2,
    X1>X2.

:-
    type(Id, object),
    cellList(Id, N1, CellId1),
    cellList(Id, N2, CellId2),
    not y(CellId1, _),
    not y(CellId2, _),
    not x(CellId1, _),
    not x(CellId2, _),
    color(CellId1, C1),
    color(CellId2, C2),
    N1<N2,
    C1>C2.

% Populate objList in order.
:-
    type(Id, listObjects),
    objList(Id, N1, ObjId1),
    objList(Id, N2, ObjId2),
    N1 > N2,
    isPopulated(ObjId1),
    not isPopulated(ObjId2).



%%%%%%%%%%%%%%%%%%%% Object Properties %%%%%%%%%%%%%%%%%%%%%
hasCell(Id, X, Y, C) :-
    type(Id, object),
    cellList(Id, _, CellId),
    x(CellId, X),
    y(CellId, Y),
    color(CellId, C).

hasCellWithColor(Id, C) :-
    type(Id, object), 
    cellList(Id, _, SubId),
    color(SubId, C).

numColor(Id, C, N) :-
    type(Id, object),
    hasCellWithColor(Id, C), 
    N = #count{SubId : cellList(Id, _, SubId), color(SubId, C)}.

notMostColor(Id, C1) :-
    type(Id, object),
    numColor(Id, C1, N1),
    numColor(Id, C2, N2),
    C1 != C2,
    N2 > N1.

mostColor(Id, C) :- 
    type(Id, object),
    hasCellWithColor(Id, C),
    not notMostColor(Id, C).

%%%%%%%%%%%%%%%%%%%% Predefined Variables %%%%%%%%%%%%%%%%%%%%%
variableId(null).
type(null, null).





%%%%%%%%%%%%%%%%%%%% functionCall constraints. %%%%%%%%%%%%%%%%%%%%%

% Each functionCall must be associated with at most 1 function
{functionCall(LN, R, F, A1, A2): variableId(R), functionId(F), variableId(A1), variableId(A2)} 1 :- 
    LN=1..maxProgramLength.

% must have at least 1 function call
:- #count{LN : functionCall(LN, _, _, _, _)} = 0.

% functions must be called sequentially
:-
    functionCall(LN, _, _, _, _),
    not functionCall(LN-1, _, _, _, _),
    LN > 1.

% track number of function calls
numFunctionCalls(N) :-
    N=#count{LN : functionCall(LN, _, _, _, _)},
    N=1..maxProgramLength.

% Don't allow function calls with exact same args. 
% Shouldn't be needed since variables are immutable.
:-
    functionCall(LN1, _, F, A1, A2),
    functionCall(LN2, _, F, A1, A2),
    LN1 != LN2.

% Functions return the variable for that line number
:-
    functionCall(LN1, R, F, A1, A2),
    lineNum(R, LN2),
    LN1 != LN2.

:-
    functionCall(LN1, R, F, A1, A2),
    not lineNum(R, _).


% Variables must be used after they are calculated
:- 
    functionCall(LN1, R, F, A1, A2),
    lineNum(A1, LN2),
    LN1 <= LN2.

:- 
    functionCall(LN1, R, F, A1, A2),
    lineNum(A2, LN2),
    LN1 <= LN2.

% copy type from variable to assignedValues
type(ValId, T) :-
    variableId(VarId),
    type(VarId, T),
    assignedToVar(ValId, VarId).



% %%%%%%%%%%%%%%%%%%%% parseObjects %%%%%%%%%%%%%%%%%%%%%
functionId(parseObjects).

% parseObjects 1st arg is an object
:- 
    functionCall(LN, R, parseObjects, A1, A2),
    type(A1, T),
    T != object.

% parseObjects 2nd arg is null
:- 
    functionCall(LN, R, parseObjects, A1, A2),
    A2 != null.

% parseObjects returns a list of objects
type(R, listObjects) :-  
    functionCall(LN, R, parseObjects, A1, A2).

% parseObjects bind values
parseObjects(Val_R, Val_A) :- 
    functionCall(LN, R, parseObjects, A, null),
    assignedToVar(Val_R, R),
    assignedToVar(Val_A, A),
    partOfInstance(Val_R, I),
    partOfInstance(Val_A, I).


% Any cell that's not the most color must be copied to obj in R
{copyCellToObject(CellId, ObjId) : objList(R, _, ObjId)} = 1 :- 
    parseObjects(R, A1),
    cellList(A1, _, CellId),
    color(CellId, C),
    mostColor(A1, MostColor),
    C != MostColor.
    
% Input children with same color must be copied to same child object
:- 
    parseObjects(R, A1),
    cellList(A1, _, CellId1),
    cellList(A1, _, CellId2),
    CellId1 != CellId2,
    color(CellId1, C),
    color(CellId2, C),
    copyCellToObject(CellId1, ObjId1),
    copyCellToObject(CellId2, ObjId2),
    ObjId1 != ObjId2.

% Input children with different color must be copied to different object
:- 
    parseObjects(R, A1),
    cellList(A1, _, CellId1),
    cellList(A1, _, CellId2),
    CellId1 != CellId2,
    color(CellId1, C1),
    color(CellId2, C2),
    C1 != C2,
    copyCellToObject(CellId1, ObjId1),
    copyCellToObject(CellId2, ObjId2),
    ObjId1 = ObjId2.





% %%%%%%%%%%%%%%%%%%%% moveDown %%%%%%%%%%%%%%%%%%%%%
functionId(moveDown).

% moveDown first arg is a object
:- 
    functionCall(LN, R, moveDown, A1, A2),
    type(A1, T),
    T != object.

% moveDown 2nd arg is a list of object
:- 
    functionCall(LN, R, moveDown, A1, A2),
    type(A2, T),
    T != listObjects.

% moveDown returns a object
type(R, object) :- 
    functionCall(LN, R, moveDown, A1, A2).

% moveDown bind values
moveDown(Val_R, Val_A1, Val_A2) :-
    functionCall(LN, R, moveDown, A1, A2),
    assignedToVar(Val_R, R),
    assignedToVar(Val_A1, A1),
    assignedToVar(Val_A2, A2),
    partOfInstance(Val_R, I),
    partOfInstance(Val_A1, I),
    partOfInstance(Val_A2, I).
    

% moveDown object must exist in the InputGrid to be called with moveDown
:-
    moveDown(_, InputObj, ListObjects),
    objList(ListObjects, _, Obj),
    hasCell(Obj, X, Y, C),
    not hasCell(InputObj, X, Y, C).


% moveDown copy coordinates from input to output
copyCellXY(InputCell, OutputCell):- 
    moveDown(OutputObj, InputObj, _),
    cellList(InputObj, N, InputCell),
    cellList(OutputObj, N, OutputCell).

% moveDown copies color of object cell with Y-1 coord to output grid
moveDown_case1_color(OutputCell, C) :- 
    moveDown(OutputGrid, _, ListObjects),
    objList(ListObjects, _, Obj),
    cellList(OutputGrid, _, OutputCell),
    x(OutputCell, X),
    y(OutputCell, Y),
    hasCell(Obj, X, Y-1, C).

color(Id, C) :- moveDown_case1_color(Id, C).

% moveDown fills with mostColor if cell was occupied by obj and 
% isn't occupied by obj in output grid . 
moveDown_case2_color(OutputCell, C) :- 
    moveDown(OutputGrid, InputGrid, ListObjects),
    objList(ListObjects, _, Obj),
    cellList(OutputGrid, _, OutputCell),
    x(OutputCell, X),
    y(OutputCell, Y),
    hasCell(Obj, X, Y, _),
    not moveDown_case1_color(OutputCell, _),
    mostColor(InputGrid,C).


color(Id, C) :- moveDown_case2_color(Id, C).

% moveDown fills with existing color otherwise
color(OutputCell, C) :- 
    moveDown(OutputGrid, InputGrid, ListObjects),
    objList(ListObjects, _, Obj),
    cellList(OutputGrid, _, OutputCell),
    x(OutputCell, X),
    y(OutputCell, Y),
    not moveDown_case1_color(OutputCell, _),
    not moveDown_case2_color(OutputCell, _),
    hasCell(InputGrid,X, Y, C).

%%%%%%%%%%%%%%%%%%%% Output Grid Constraint %%%%%%%%%%%%%%%%%%%%%
% Output grid must be equal to last var instance
objEqual(OutputGridValId, ValId):- 
    numFunctionCalls(N),
    functionCall(N, VarId, _, _, _),
    assignedToVar(ValId, VarId),
    partOfInstance(ValId, I),
    isOutputGrid(OutputGridValId),
    partOfInstance(OutputGridValId, I),
    instanceType(I, train).

:- 
    objEqual(G1, G2),
    hasCell(G1, X, Y, C),
    not hasCell(G2, X, Y, C).

:- 
    objEqual(G1, G2),
    hasCell(G2, X, Y, C),
    not hasCell(G1, X, Y, C).

    

%%%%%%%%%%%%%%%%%%%% Show %%%%%%%%%%%%%%%%%%%%%
varType(VarId, T) :- 
    variableId(VarId),
    type(VarId, T).

hasCellAndNotGrid(Id, X, Y, C) :-
    hasCell(Id, X, Y, C),
    not assignedToVar(Id, varInputGrid),
    not isOutputGrid(Id).

hasCellOutputTestGrid(I, X, Y, C) :-
    numFunctionCalls(N),
    functionCall(N, VarId, _, _, _),
    assignedToVar(ValId, VarId),
    partOfInstance(ValId, I),
    instanceType(I, test),
    hasCell(ValId, X, Y, C).



% #show hasCellOutputTestGrid/4.