pragma circom 2.1.4;

// Input : 'a',array of length 2 .
// Output : 'c 
// Using a forLoop , add a[0] and a[1] , 4 times in a row .

function add(a, b){
    var result;
    for (var i=0; i < 4; i++){
        result = a + b + result;
    }
    return result;
}

template ForLoop() {

// Your Code here..
    signal input a[2];
    signal output c;

    c <-- add(a[1], a[0]);
}  

component main = ForLoop();
