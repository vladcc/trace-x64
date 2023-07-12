#!/usr/bin/awk -f

function ident_get() {return B_ident}
function ident_up() {B_ident = (B_ident "----")}
function ident_down() {B_ident = substr(B_ident, 1, length(B_ident)-4)}
function out_ident() {print (ident_get() $1 "|" $NF)}

function RE_CALL() {return " call "}
function RE_FJMP() {return " jmp qword ptr "}
function RE_RET() {return " ret "}

BEGIN {FS="\\|"}
FNR == 1 && !(match($NF, RE_CALL()) || match($NF, RE_FJMP())) {print}
match($NF, RE_CALL()) {out_ident(); ident_up(); if (getline > 0) out_ident()}
match($NF, RE_FJMP()) {out_ident(); if (getline > 0) out_ident()}
match($NF, RE_RET()) {out_ident(); ident_down(); if (getline > 0) out_ident()}
