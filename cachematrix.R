# WHAT DOES THIS SCRIPT DO AND WHEN TO USE IT ####
## Provides a way to speed up a process,
## that uses a group of matrices in some computations,
## which involve inverting the original matrices (a costly task),
## multiple times for each matrix.'=
## You can expect the best results if your use a group of big matrices
## from which you take samples and invert them for your reasons.
## So if your process:
##      * does a lot of matrix inversions
##      * and the some of the matrices are used more than one time
## then you can significantly improve the performance of the process.
## To do this the matrices transform to special matrices
## with the function makeCacheMatrix() that creates objects
## which can store their inverses (so no need for recalculating them!)
## only if it gets computed by the function cacheSolve() (instead of solve())
## and will be available when we ask for it in the future.

# I WANT THE DETAILS ####
## These two functions: makeCacheMatrix() and cacheSolve()
## are created to be used together for the propose of speeding up
## a computational process under 2 assumptions:
##      * we want to calculate the inverse of some matrices,
##        and this makes our process slow (matrix inversions is costly)
##      * in addition to the above,
##        our process uses some of the matrices more than one time
## The first function makeCacheMatrix() is used to create a special S3 object
## and takes one argument, the matrix 'x' we want to convert
##      x       an ordinary square invertible matrix
## Then executes the following steps:
##      0. by default the argument 'x' get initialized with 'x = matrix()'
##      1. uses force to make the environment store the value of matrix 'x'
##      2. a NULL object created to cache the inverse of 'x', called 'inverse_x'
##      3. a getter for the matrix 'x' is created,
##         with name 'get_matrix()' that:
##              1. Searches inside the makeCacheMatrix object
##                 for the matrix 'x' and returns its value
##      4. a getter for the inverse of the matrix 'x' created,
##         with name 'get_inverse()' that:
##              1. Searches inside the makeCacheMatrix object
##                 for the 'inverse_x' and returns its value
##      5. a setter for the matrix 'x' is created,
##         with name 'set_matrix(new_x)' that:
##              Takes an argument 'new_x'       the new matrix (class: matrix)
##              1. Searches inside the parent frame with operator '<<-'
##                 for the matrix 'x' and assigns the new value 'new_x'
##      6. a setter for the 'inverse_x' is created,
##         with name 'set_inverse(new_inverse)' that:
##              Takes an argument 'new_inverse' the new value of inverse
##              1. Searches inside the parent frame with operator '<<-'
##                 for the 'inverse_x' and assigns the new value 'new_inverse'
##      7. finally stores the four functions created in steps 3,4,5,6
##         and stores them in a list. The 2 objects created at steps 0,1,2
##         are not lost because the object will remember the environment in
##         which it was created that includes both 'x' and 'inverse_x'
## The result is an S3 object that can be initialized with a matrix
## with the ability to remember the value of it's inverse
## ONLY if used along with the function cacheSolve(x, ...)
## that takes one argument 'x'  an object created by makeCacheMatrix()
## and executes the following steps:
##      1. gets the value of the inverse stored in the makeCacheMatrix object 'x',
##         to a variable with name 'inverse_x'
##      2. checks if 'inverse_x' is not NULL, so a value is already cached,
##         and retrieves it, prints a message in console
##         and returns the value on 'inverse_x'
##      3. if the 'inverse_x' is NULL, so no value cached,
##         gets the value of matrix and tries to find the inverse
##         by 'solve(matrix)' (unavoidable..),
###             * with 'try(solve, silent = TRUE) avoids the termination
###               of the process in case a matrix is not invertible
##         and stores it in a variable called 'inverse_x'
##      4. sets the 'inverse_x' inside the makeCacheMatrix object 'x'
##         with the value it just computed
##      5. finally returns the inverse of the matrix we want
## The core use of makeCacheMatrix() and cacheSolve()
## is about replacing the work-flow:
##               'matrix object' ----> 'makeCacheMatrix object'
##    solve(x = 'matrix object') ----> cacheSolve(x = 'makeCacheMatrix object')

# makeCacheMatrix(x = matrix()) ####
## Takes a matrix as an input and creates a special object,
## that contains the original matrix and a NULL position
## waiting to store it's inverse as well as four other function
## that perform the basic tasks of getting a value stored in the object
## and setting new values to either the matrix or it's inverse..
## These functions are simple accessors and mutators
makeCacheMatrix <- function(x = matrix()) {

        ### we want the environment to remember the matrix x
        force(x)
        ### An object for the inverse of the matrix
        ### gets initialized here
        inverse_x <- NULL

        ### ACCESSORS AND MUTATORS
        #### Initialize the accessors (getters)
        ##### we need a function to return the data of the matrix
        get_matrix <- function() x
        ##### we need a function to return the inverse of the matrix
        get_inverse <- function() inverse_x

        #### Initialize the mutators (setter)
        ##### we need a function to assign new value to x
        ##### and reset the inverse_x to NULL.
        set_matrix <- function(new_x) {
                # when the function set_matrix() is called in the global env,
                # it searches for the value of matrix x inside its body,
                # but nothing is there, neither in the global environment..
                # the matrix x exists inside some makeCacheMatrix object,
                # which exists in the global_env
                # so the operator '<<-' after failing to find matrix x,
                # inside the body of get_matrix(),
                # looks in the parent environment of get_matrix()
                # (the environment in which get_matrix() was created)
                # !! if we use the operator '<-' the function won't be able to
                #    search in the parent environment of set_matrix(),
                #    and will try unsuccessfully the global
                #    up to the Empty environment
                x <<- new_x

                # reset inverse_x to NULL
                # (the reason for using '<<-' operator is the same as above)
                inverse_x <<- NULL
        }
        ##### we need a function to check if the inverse has already been
        ##### computed and cashed to return it as it is, or it should be
        ##### computed and stored now
        set_inverse <- function(new_inverse) inverse_x <<- new_inverse

        ### The result is a list with the functions only, not the objects,
        ### because they will be stored inside the object in a some way.
        ### (matrix x and inverse_x will be remembered in parent env of the functions,
        ###  and the functions will record the the name of this environment)
        list(get_matrix = get_matrix,
             get_inverse = get_inverse,
             set_matrix = set_matrix,
             set_inverse = set_inverse)

}


# cacheSolve(x, ...) ####
## cacheSolve() is responsible to look inside an object,
## created by makeCacheMatrix() for the value of its inverse matrix.
## if the value returned is NULL, means that the inverse hasn't been computed yet
## so it calls solve() to find it and caches the value inside the object
cacheSolve <- function(x, ...) {

        ### Gets the value of the inverse from the makeCacheMatrix object x
        inverse_x <- x$get_inverse()

        ### Checks if the inverse is already computed
        ### and if it has been it returns the value
        if (!is.null(inverse_x)) {
                ### produces a message when cashed data is retrieved
                message(" --> getting cached data for the inverse..")
                ### returns the retrieved value and exit the function
                return(inverse_x)
        }

        ### In case the inverse hasn't been computed yet it computes it
        matrix <- x$get_matrix()
        ### We can never be sure if the matrix is really invertible
        ### so we better protect a long process from breaking
        ### by using the try() wrapper around solve()
        inverse_x <- try(solve(matrix), silent = TRUE)
        ### the value of the inverse then gets stored inside the special matrix x
        x$set_inverse(inverse_x)

        inverse_x
}
