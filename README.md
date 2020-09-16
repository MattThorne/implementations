# Quantum #
This repository stores the code for my masters Dissertation project. The aim of the project was to help determine if Bernstein, Biasse and Msoca's low resource quantum factoring algorithm (https://link.springer.com/chapter/10.1007/978-3-319-59879-6_19 )would use less qubits than Shor's algorithm would to factor a common RSA key size such as 2048-bit. To determine this the main quantum component of the BBM algorithm was implemented. The main component is Shor's algorithm run in superposition. This code therefore implements Shor's algorithm in superposition using the MQDK to determine a minimum bound for the qubits required by the BBM algorithm to factor an n bit number.
It was found that the BBM algorithm would use at least more than double the number of qubits to factor a 2048-bit number than Shor's conventional algorithm would. The BBM algorithm only began to use less qubits than Shor's algorithm once n = 4*10^6.

To implement Shor's algorithm in superposition a number of new fundemental reversible operations were implemented in superposition:

* Modular Multiplication
* Modular Squaring
* Signed Multiplication
* Signed Subtraction
* Square and Multiply Modular Exponentiation
* Continued Fractions Convergent
* Greatest Common Divisor
          

