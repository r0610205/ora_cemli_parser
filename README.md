Pre-compilator for CEMLI scanner
=============
  Parses files with differences and provides output to be used by scanner.

Installation
-----------

    git clone https://github.com/r0610205/ora_cemli_parser.git
    cd ora_cemli_parser
    npm install

Usage
-----------

Use node.js to run:

    node index -f /path/to/folder/with/oracle/files

Or as alternative:

    coffee index.coffee -f /path/to/folder/with/oracle/files

Modification
-----------
  Originally written with CoffeScript. Modify only .coffee files.
  If you would like to run .js files compile using `compile.sh`

Results
-----------

  Some benchmarks can be found in a 'results' folder.