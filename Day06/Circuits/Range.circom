pragma circom 2.1.4;

// In this exercise , we will learn how to check the range of a private variable and prove that 
// it is within the range . 

// For example we can prove that a certain person's income is within the range
// Declare 3 input signals `a`, `lowerbound` and `upperbound`.
// If 'a' is within the range, output 1 , else output 0 using 'out'

function check(a,b,c)
{
    if (a > b && a < c){
        return 1;
    }else{
        return 0;
    }
}


template Range() {
    // your code here

    signal input a;
    signal input lowerbound;
    signal input upperbound;
    signal output out;

    out <-- check(a, lowerbound, upperbound);
   
}

component main  = Range();


