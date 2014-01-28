Pre-compilator for CEMLI scanner
=============
  Parses files provided by Oracle and compiles output for CEMLI scanner.

Installation
-----------

    git clone https://github.com/r0610205/ora_cemli_parser.git
    cd ora_cemli_parser


Usage
-----------

Use [Node.js](http://nodejs.org) to run:

    node index -f /path/to/folder/with/oracle/files


Modification
-----------
  * Originally written in CoffeScript. It's recommended to make changes in `.coffee` files and compile using `compile.sh`. CoffeeScript should be installed in the system to compile.
  * All the "messy" file-specific code is concentrated in `lib/config` file. 

Results
-----------

  `Results` folder includes:
  * benchmarks
  * archive of results obtained with current version of scanner
  * archive of results obtainer with original version of scanner (1C)

TODO
-----------
 Grunt task to compile all `.coffee` files into one single JavaScript to run
