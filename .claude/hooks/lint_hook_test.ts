// This file has intentional linting issues to test our hook

import { readFileSync } from 'fs'; // valid import but unused (will trigger linting warning)

function badFunction11( x:number,y:number ):number{  // bad spacing around parameters and return type
    if(x>0){ // missing spaces around operators and braces
        return x+y // missing spaces around operator
    }else{
        return 0
    }
}
// missing blank line before function
function anotherFunction():void{
    const unusedVariable = "this will trigger a linting error" // unused variable
    console.log( "bad spacing in console.log" ) // bad spacing
}

// trailing whitespace on next line
const x=1+2 // bad spacing around operators

// Missing semicolons and bad formatting
const result=badFunction11(1,2) // bad spacing
console.log(result)

// Unused imports and variables
const unusedConst = "unused"

// Any type usage (should trigger @typescript-eslint/no-explicit-any)
function badAnyFunction3(param: any): any {
    return param
}