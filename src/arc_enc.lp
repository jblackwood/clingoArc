% copyCell
type(Id2, cell) :- 
    copyCell(_, Id2).

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
type(Id2, cell) :- 
    copyCellXY(_, Id2).

y(Id2, Val) :-
    copyCellXY(Id1, Id2),
    y(Id1, Val).

x(Id2, Val) :-
    copyCellXY(Id1, Id2),
    x(Id1, Val).

% % copyCellColor
% type(Id2, cell) :- 
%     copyCellColor(_, Id2).

% color(Id2, Val) :-
%     copyCellXY(Id1, Id2),
%     color(Id1, Val).

%%%%%%%%%%%%%%%%%%%% Grid and Object Properties %%%%%%%%%%%%%%%%%%%%%
hasCell(Id, X, Y, C) :-
    child(Id, _, CellId),
    type(CellId, cell),
    x(CellId, X),
    y(CellId, Y),
    color(CellId, C).

hasColor(Id, C) :- 
    child(Id, _, SubId),
    color(SubId, C).

numColor(Id, C, N) :- 
    hasColor(Id, C), 
    N = #count{SubId : child(Id, _, SubId), color(SubId, C)}.

notMostColor(Id, C1) :-
    numColor(Id, C1, N1),
    numColor(Id, C2, N2),
    C1 != C2,
    N2 > N1.

mostColor(Id, C) :- 
    hasColor(Id, C),
    not notMostColor(Id, C).

% copy input grid cells into var0
copyCell(CellId, NewCellId) :- 
    child(G, N, CellId),
    isInputGrid(G),
    instance(G, I),
    isVarInstance(VarInst),
    instance(VarInst, I),
    lineNum(VarInst, 0),
    child(VarInst, N, NewCellId).

% copy type from variable to varInstances
type(VarInstance, T) :-
    type(VarId, T),
    isVariable(VarId),
    varId(VarInstance, VarId).

% copy lineNum from variable to varInstances
lineNum(VarInstance, L) :-
    lineNum(VarId, L),
    isVariable(VarId),
    varId(VarInstance, VarId).


%%%%%%%%%%%%%%%%%%%% functionCall constraints %%%%%%%%%%%%%%%%%%%%%

% Each functionCall must be associated with at most 1 function
{functionId(CallId, FunId): type(FunId, function)} 1 :- 
    id(CallId),
    type(CallId, functionCall).

% functions must be called sequentially
{functionId(CallId, FunId): type(FunId, function)}=1:-
    functionId(CallId, _),
    lineNum(CallId, LineNum),
    lineNum(PreviousCallId, LineNum-1),
    type(PreviousCallId, functionCall).

% must have at least 1 function call
:- #count{CallId : functionId(CallId, _)} = 0.

% track number of function calls
numFunctionCalls(N) :-
    N=#count{CallId : functionId(CallId, _)},
    N=1..programLength.

% Don't allow function calls with exact same args. 
% Shouldn't be needed since variables are immutable.
:-
    functionId(CallId1, F),
    lineNum(CallId1, LN1),
    lineNum(ArgId, LN1),
    argVal(ArgId, Val),
    argPos(ArgId, Pos),
    functionId(CallId2, F),
    lineNum(CallId2, LN2),
    lineNum(ArgId2, LN2),
    argVal(ArgId2, Val),
    argPos(ArgId2, Pos),
    LN1 != LN2.



% Variables must be used after calculation
:- 
    argVal(ArgId, VarId),
    lineNum(ArgId, N1),
    lineNum(VarId, N2),
    N1 <= N2.



%%%%%%%%%%%%%%%%%%%% parseObjects %%%%%%%%%%%%%%%%%%%%%
id(parseObjects).
type(parseObjects, function).

% parseObjects first arg is a grid variable
{argVal(ArgId, VarId) : isVariable(VarId), type(VarId, grid)} = 1 :-  
    functionId(CallId, parseObjects),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isArgument(ArgId),
    lineNum(ArgId, LineNum),
    argPos(ArgId, 0).

% parseObjects returns a list of objects
type(VarId, listObjects) :-  
    functionId(CallId, parseObjects),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isVariable(VarId),
    lineNum(VarId, LineNum).

% Any child that's not the most color must be copied to a a child object
% of the output var inst
{copyToObject_parseObjects(LineNum, I, InputChildId, OutputObjId) 
: child(OutVarInst, _, OutputObjId) }=1 :- 
    functionId(CallId, parseObjects),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    lineNum(ArgId, LineNum),
    argVal(ArgId, VarId),
    isVarInstance(ArgVarInst),
    varId(ArgVarInst, VarId),
    instance(ArgVarInst, I),
    child(ArgVarInst, N, InputChildId),
    color(InputChildId, C),
    mostColor(ArgVarInst, MostC),
    C != MostC,
    isVarInstance(OutVarInst),
    instance(OutVarInst, I),
    lineNum(OutVarInst, LineNum).
    
% Input children with same color must be copied to same child object
:- 
    copyToObject_parseObjects(LineNum, I, ChildId_1, OutputObjId_1),
    copyToObject_parseObjects(LineNum, I, ChildId_2, OutputObjId_2),
    ChildId_1 != ChildId_2,
    color(ChildId_1, C),
    color(ChildId_2, C),
    OutputObjId_1 != OutputObjId_2.

% Input children with different color must be copied to different object
:- 
    copyToObject_parseObjects(LineNum, I, ChildId_1, OutputObjId_1),
    copyToObject_parseObjects(LineNum, I, ChildId_2, OutputObjId_2),
    ChildId_1 != ChildId_2,
    color(ChildId_1, C1),
    color(ChildId_2, C2),
    C1 != C2,
    OutputObjId_1 = OutputObjId_2.

% Output children are populated in ascending order
 :- 
    copyToObject_parseObjects(LineNum, I, _, OutputObjId_1),
    child(P, N1, OutputObjId_1),
    child(P, N2, OutputObjId_2),
    N1 > N2,
    not copyToObject_parseObjects(LineNum, I, _, OutputObjId_2).
    

% Copy cells to same index
copyCell(InputChildId, OutputCellId):- 
    child(_, N, InputChildId),
    copyToObject_parseObjects(LineNum, I, InputChildId, OutputObjId),
    child(OutputObjId, N, OutputCellId).

% Type of output object is object
type(OutputObjId, object):- 
    copyToObject_parseObjects(_, _, _, OutputObjId).


%%%%%%%%%%%%%%%%%%%% moveDown %%%%%%%%%%%%%%%%%%%%%
id(moveDown).
type(moveDown, function).

% moveDown first arg is a grid variable
{argVal(ArgId, VarId) : isVariable(VarId), type(VarId, grid)} = 1 :-  
    functionId(CallId, moveDown),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isArgument(ArgId),
    lineNum(ArgId, LineNum),
    argPos(ArgId, 0).

% moveDown 2nd arg is a listObject variable
{argVal(ArgId, VarId) : isVariable(VarId), type(VarId, listObjects)} = 1 :-  
    functionId(CallId, moveDown),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isArgument(ArgId),
    lineNum(ArgId, LineNum),
    argPos(ArgId, 1).

% moveDown returns a grid
type(VarId, grid) :- 
    functionId(CallId, moveDown),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isVariable(VarId),
    lineNum(VarId, LineNum).

% moveDown bind variable instances
moveDown(FirstArgInst, SecondArgInst, OutputVarInst):- 
    functionId(CallId, moveDown),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    argPos(FirstArg, 0),
    lineNum(FirstArg, LineNum),
    argVal(FirstArg, FirstArgVarId),
    isVarInstance(FirstArgInst),
    varId(FirstArgInst, FirstArgVarId),
    instance(FirstArgInst, I),
    argPos(SecondArg, 1),
    lineNum(SecondArg, LineNum),
    argVal(SecondArg, SecondArgVarId),
    isVarInstance(SecondArgInst),
    varId(SecondArgInst, SecondArgVarId),
    instance(SecondArgInst, I),
    isVariable(VarId),
    lineNum(OutputVarInst, LineNum),
    instance(OutputVarInst, I).

% Object must exist in the InputGrid to be called with moveDown
:-
    moveDown(InputGrid, ListObjects, _),
    child(ListObjects, _, Obj),
    hasCell(Obj, X, Y, C),
    not hasCell(InputGrid, X, Y, C).


% moveDown copy coordinates from input to output
copyCellXY(InputCell, OutputCell):- 
    moveDown(InputGrid, ListObjects, OutputGrid),
    child(InputGrid, N, InputCell),
    child(OutputGrid, N, OutputCell).

% moveDown copies color of object cell with Y-1 coord to output grid
moveDown_case1_color(OutputCell, C) :- 
    moveDown(InputGrid, ListObjects, OutputGrid),
    child(InputGrid, N, InputGridCell),
    child(OutputGrid, N, OutputCell),
    child(ListObjects, _, Obj),
    child(Obj, _, InputObjCell),
    x(OutputCell, X),
    y(OutputCell, Y),
    x(InputObjCell, X),
    y(InputObjCell, Y-1),
    color(InputObjCell, C).

color(Id, C) :- moveDown_case1_color(Id, C).

% moveDown fills with mostColor if cell was occupied by obj and 
% isn't occupied by obj in output grid . 
moveDown_case2_color(OutputCell, C) :- 
    moveDown(InputGrid, ListObjects, OutputGrid),
    child(InputGrid, N, InputGridCell),
    child(OutputGrid, N, OutputCell),
    child(ListObjects, _, Obj),
    child(Obj, _, InputObjCell),
    x(OutputCell, X),
    y(OutputCell, Y),
    x(InputObjCell, X),
    y(InputObjCell, Y),
    not moveDown_case1_color(_, OutputCell),
    mostColor(InputGrid,C).

color(Id, C) :- moveDown_case2_color(Id, C).

% moveDown fills with existing color otherwise
color(OutputCell, C) :- 
    moveDown(InputGrid, ListObjects, OutputGrid),
    child(InputGrid, N, InputGridCell),
    child(OutputGrid, N, OutputCell),
    not moveDown_case1_color(OutputCell, _),
    not moveDown_case2_color(OutputCell, _),
    color(InputGridCell, C).
    



%%%%%%%%%%%%%%%%%%%% Output Grid Constraint %%%%%%%%%%%%%%%%%%%%%
% Output grid must be equal to var2 instance
gridEqual(OutputGrid, VarInst):- 
    isOutputGrid(OutputGrid),
    instance(OutputGrid, I),
    isVarInstance(VarInst),
    instance(VarInst, I),
    numFunctionCalls(N),
    lineNum(VarInst, N).

:- 
    gridEqual(G1, G2),
    hasCell(G1, X, Y, C),
    not hasCell(G2, X, Y, C).

:- 
    gridEqual(G1, G2),
    hasCell(G2, X, Y, C),
    not hasCell(G1, X, Y, C).



%%%%%%%%%%%%%%%%%%%% Show %%%%%%%%%%%%%%%%%%%%%
varType(VarId, T) :- 
    isVariable(VarId),
    type(VarId, T).

var1_train0_child_numColors(Id, C,N) :- 
    child(var1_train0, _, Id),
    numColor(Id, C, N).

% #show varType/2.
% #show argVal/2.
% #show functionId/2.
% #show var1_train0_child_numColors/3.
% #show moveDown/3.

% show var0_train0 num colors
% var0_train0_numColor(C, N) :- 
%     numColor(var0_train0, C, N).
% var0_train0_mostColor(C) :- mostColor(var0_train0, C).
% #show var0_train0_numColor/2.
% #show var0_train0_mostColor/1.