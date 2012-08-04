
lappend auto_path lib

package require tna-as

tna::array create x float 10 10 
tna::array create y float 10 10 

tna::expr { x = 5*y }


exit



# Example:
#
lappend auto_path lib

package require tna-vm
source tna-as.tcl

    tna::array create A float 1024 1024
    tna::array create B float 1024 1024

    # tna::set B { A + 4 + X * Y }

    tna::as create X {
	register A  A(:511,*)
	register B  B

	register 4  4 float
	register X  * float
	register Y  * float

	register T1 * float
	register T2 * float

	add A   4  -> T1	; # B = A+4 + X*Y
	xxx X      -> T2
	mul T2  Y  -> T2
	add T2  T1 -> B
    }

