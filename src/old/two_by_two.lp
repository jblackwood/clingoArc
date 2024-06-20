cell(C) :- C=1..2*2.
row(C, (C-1)/2+1) :- cell(C).
col(C, (C-1)\2+1) :- cell(C).

color(red; black).

filled(C,red, 0) :- row(C, 1), col(C, 1).
filled(C,black, 0) :- row(C, 1), col(C, 2).
filled(C,black, 0) :- row(C, 2), col(C, 1).
filled(C,black, 0) :- row(C, 2), col(C, 2).
background(black).

moveRight(C) :- row(C, 1), col(C, 1).

filled(C2, Color1, 1) :- moveRight(C1), filled(C1, Color1, 0),row(C1,Row), col(C1,Col1), row(C2,Row), col(C2,Col1+1).
filled(C, BgColor, 1) :-  moveRight(C), background(BgColor).
filled(C, Color, 1) :- filled(C, Color, 0), not filled(C, Color2, 1), Color != Color2, color(Color2).

ans(Row,Col,Color) :- filled(C, Color, 1), row(C, Row), col(C, Col).

#show ans/3.

