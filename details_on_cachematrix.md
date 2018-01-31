# Details on the 'cachematrix.R' script:  
  
These two functions: makeCacheMatrix() and cacheSolve()
are created to be used together for the propose of speeding up
a computational process under 2 assumptions:  
  
  - we want to calculate the inverse of some matrices,
    and this makes our process slow (matrix inversions is costly)
  - in addition to the above,
    our process uses some of the matrices more than one time  
    
The first function makeCacheMatrix() is used to create a special S3 object  
and takes one argument, the matrix 'x' we want to convert  
  
> x : an ordinary square invertible matrix  
  
Then executes the following steps:   
  
  0. By default the argument 'x' get initialized with 'x = matrix()'  
  1. Uses force to make the environment store the value of matrix 'x'  
  2. A NULL object created to cache the inverse of 'x', called 'inverse_x'  
  3. A getter for the matrix 'x' is created, with name 'get_matrix()' that:  
         1. Searches inside the makeCacheMatrix object
  for the matrix 'x' and returns its value  
  4. A getter for the inverse of the matrix 'x' created,
     with name 'get_inverse()' that:  
         1. Searches inside the makeCacheMatrix object
            for the 'inverse_x' and returns its value
  5. A setter for the matrix 'x' is created, 
     with name 'set_matrix(new_x)' that:  
         Takes an argument 'new_x' the new matrix (class: matrix)  
         1. Searches inside the parent frame with operator '<<-'
              for the matrix 'x' and assigns the new value 'new_x'  
  6. A setter for the 'inverse_x' is created,
     with name 'set_inverse(new_inverse)' that:
         Takes an argument 'new_inverse' the new value of inverse
         1. Searches inside the parent frame with operator '<<-'
            for the 'inverse_x' and assigns the new value 'new_inverse'  
  7. Finally stores the four functions created in steps 3,4,5,6
     and stores them in a list. The 2 objects created at steps 0,1,2
     are not lost because the object will remember the environment in
     which it was created that includes both 'x' and 'inverse_x'  
  
The result is an S3 object that can be initialized with a matrix
with the ability to remember the value of it's inverse
ONLY if used along with the function cacheSolve(x, ...)
that takes one argument 'x'  an object created by makeCacheMatrix()
and executes the following steps:  
  
  1. Gets the value of the inverse stored in the makeCacheMatrix object 'x',
     to a variable with name 'inverse_x'  
  2. Checks if 'inverse_x' is not NULL, so a value is already cached,
     and retrieves it, prints a message in console
     and returns the value on 'inverse_x'  
  3. If the 'inverse_x' is NULL, so no value cached,
     gets the value of matrix and tries to find the inverse
     by 'solve(matrix)' (unavoidable..),  
       * with 'try(solve, silent = TRUE) avoids the termination
         of the process in case a matrix is not invertible  
         and stores it in a variable called 'inverse_x'  
  4. Gets the 'inverse_x' inside the makeCacheMatrix object 'x'
     with the value it just computed  
  5. Finally returns the inverse of the matrix we want  
  
The core use of makeCacheMatrix() and cacheSolve() is about replacing the work-flow:  

```      
           'matrix object' ----> 'makeCacheMatrix object'  
solve(x = 'matrix object') ----> cacheSolve(x = 'makeCacheMatrix object')  
```
