namespace Shor {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Oracles;
    open Microsoft.Quantum.Characterization;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;

operation Mk1() : Unit{

using (a0 = Qubit[2]){
    X(a0[1]);
    using (a1 = Qubit[4]){
        SquareI(LittleEndian(a0),LittleEndian(a1));
        DumpMachine("/Users/Matt/Documents/Masters/Dissertation/Qsharp/Qs_Output.txt");
        using (a2 = Qubit[8]){
            SquareI(LittleEndian(a1),LittleEndian(a2));
            //DumpMachine("/Users/Matt/Documents/Masters/Dissertation/Qsharp/Qs_Output.txt");
            Adjoint SquareI(LittleEndian(a0),LittleEndian(a1));
            //DumpMachine();
            DumpRegister((),a1);
            ResetAll(a2);
        }
        ResetAll(a1);
        }
        ResetAll(a0);
    }
    
}




operation Test_Operation (number : Int, isOdd : Bool) : Unit {


    using (qs = Qubit[number]){
        X(qs[0]);
        H(qs[1]);
        DumpMachine();
        using (ys = Qubit[number]){
            H(ys[1]);
            DumpMachine();
            using (rs = Qubit[number]){
                let qsLE = LittleEndian(qs);
                let ysLE = LittleEndian(ys);
                let rsLE = LittleEndian(rs);

                DivideI(ysLE,qsLE,rsLE);
                DumpMachine();
                ResetAll(rs);
            }
            ResetAll(ys);
        }
        ResetAll(qs);
    }
}




operation EvenOddNumbersSuperposition (isOdd : Bool, qs : Qubit[]) : Unit {

    
    let N = Length(qs);
    for (i in 1 .. N-1) {
        H(qs[i]);
    }
    // for odd numbers, flip the first bit to 1
    if (isOdd) {
        X(qs[0]);
    }  

}





  operation Set(desired : Result, q1 : Qubit) : Unit {
        if (desired != M(q1)) {
            X(q1);
        }
    }  

    operation TestBellState(count : Int, initial : Result) : (Int, Int, Int) {

    mutable numOnes = 0;
    mutable agree = 0;
    using ((q0,q1) = (Qubit(),Qubit())) {

        for (test in 1..count) {
            Set(initial, q0);
            Set(Zero,q1);
            H(q0);
            CNOT(q0,q1);

            //AssertProb([PauliZ], [q0], Zero, 0.5, "Outcomes must be equally likely", 1e-5);
            //AssertProb([PauliZ], [q1], Zero, 0.5, "Outcomes must be equally likely", 1e-5);
            let res = M(q0);

            if(M(q1) == res){
                set agree += 1;
            }

            // Count the number of ones we saw:
            if (res == One) {
                set numOnes += 1;
            }
        }
        
        Set(Zero, q1);
    }

    // Return number of times we saw a |0> and number of times we saw a |1>
    return (count-numOnes, numOnes, agree);
}

/// # Summary
    /// Divides two quantum integers.
    ///
    /// # Description
    /// `xs` will hold the
    /// remainder `xs - floor(xs/ys) * ys` and `result` will hold
    /// `floor(xs/ys)`.
    ///
    /// # Input
    /// ## xs
    /// $n$-bit dividend, will be replaced by the remainder.
    /// ## ys
    /// $n$-bit divisor
    /// ## result
    /// $n$-bit result, must be in state $\ket{0}$ initially
    /// and will be replaced by the result of the integer division.
    ///
    /// # Remarks
    /// Uses a standard shift-and-subtract approach to implement the division.
    /// The controlled version is specialized such the subtraction does not
    /// require additional controls.
    operation DivideI (xs: LittleEndian, ys: LittleEndian,
                               result: LittleEndian) : Unit {
        body (...) {
            (Controlled DivideI) (new Qubit[0], (xs, ys, result));
        }
        controlled (controls, ...) {
            let n = Length(result!);

            EqualityFactI(n, Length(ys!), "Integer division requires
                           equally-sized registers ys and result.");
            EqualityFactI(n, Length(xs!), "Integer division
                            requires an n-bit dividend registers.");
            AssertAllZero(result!);

            let xpadded = LittleEndian(xs! + result!);

            for (i in (n-1)..(-1)..0) {
                let xtrunc = LittleEndian(xpadded![i..i+n-1]);
                
                (Controlled CompareGTI) (controls, (ys, xtrunc, result![i]));
                // if ys > xtrunc, we don't subtract:
                (Controlled X) (controls, result![i]);
                (Controlled Adjoint AddI) ([result![i]], (ys, xtrunc));
            }
        }
        adjoint auto;
        adjoint controlled auto;
    }



      /// # Summary
    /// Automatically chooses between addition with
    /// carry and without, depending on the register size of `ys`.
    ///
    /// # Input
    /// ## xs
    /// $n$-bit addend.
    /// ## ys
    /// Addend with at least $n$ qubits. Will hold the result.
    operation AddI (xs: LittleEndian, ys: LittleEndian) : Unit is Adj + Ctl {
        if (Length(xs!) == Length(ys!)) {
            RippleCarryAdderNoCarryTTK(xs, ys);
        }
        elif (Length(ys!) > Length(xs!)) {
            using (qs = Qubit[Length(ys!) - Length(xs!) - 1]){
                RippleCarryAdderTTK(LittleEndian(xs! + qs),
                                    LittleEndian(Most(ys!)), Tail(ys!));
            }
        }
        else {
            fail "xs must not contain more qubits than ys!";
        }
    }

       /// # Summary
    /// Wrapper for integer comparison: `result = x > y`.
    ///
    /// # Input
    /// ## xs
    /// First $n$-bit number
    /// ## ys
    /// Second $n$-bit number
    /// ## result
    /// Will be flipped if $x > y$
    operation CompareGTI (xs: LittleEndian, ys: LittleEndian,
                            result: Qubit) : Unit is Adj + Ctl {
        GreaterThan(xs, ys, result);
    }

        /// # Summary
    /// Multiply integer `xs` by integer `ys` and store the result in `result`,
    /// which must be zero initially.
    ///
    /// # Input
    /// ## xs
    /// $n$-bit multiplicand (LittleEndian)
    /// ## ys
    /// $n$-bit multiplier (LittleEndian)
    /// ## result
    /// $2n$-bit result (LittleEndian), must be in state $\ket{0}$ initially.
    ///
    /// # Remarks
    /// Uses a standard shift-and-add approach to implement the multiplication.
    /// The controlled version was improved by copying out $x_i$ to an ancilla
    /// qubit conditioned on the control qubits, and then controlling the
    /// addition on the ancilla qubit.
    operation MultiplyI (xs: LittleEndian, ys: LittleEndian,
                         result: LittleEndian) : Unit {
        body (...) {
            let n = Length(xs!);

            EqualityFactI(n, Length(ys!), "Integer multiplication requires
                           equally-sized registers xs and ys.");
            EqualityFactI(2 * n, Length(result!), "Integer multiplication
                            requires a 2n-bit result registers.");
            AssertAllZero(result!);

            for (i in 0..n-1) {
                (Controlled AddI) ([xs![i]], (ys, LittleEndian(result![i..i+n])));
            }
        }
        controlled (controls, ...) {
            let n = Length(xs!);

            EqualityFactI(n, Length(ys!), "Integer multiplication requires
                           equally-sized registers xs and ys.");
            EqualityFactI(2 * n, Length(result!), "Integer multiplication
                            requires a 2n-bit result registers.");
            AssertAllZero(result!);

            using (anc = Qubit()) {
                for (i in 0..n-1) {
                    (Controlled CNOT) (controls, (xs![i], anc));
                    (Controlled AddI) ([anc], (ys, LittleEndian(result![i..i+n])));
                    (Controlled CNOT) (controls, (xs![i], anc));
                }
            }
        }
        adjoint auto;
        adjoint controlled auto;
    } 


     operation ArbitraryAdderInPlace_Reference (a : Qubit[], b : Qubit[], carry : Qubit) : Unit is Adj {
        let N = Length(a);

        using (internalCarries = Qubit[N]) {
            // Set up the carry bits
            LowestBitCarry_Reference(a[0], b[0], internalCarries[0]);
            for (i in 1 .. N-1) {
                HighBitCarry_Reference(a[i], b[i], internalCarries[i - 1], internalCarries[i]);
            }
            CNOT(internalCarries[N-1], carry);

            // Clean up carry bits and compute sum
            for (i in N-1 .. -1 .. 1) {
                Adjoint HighBitCarry_Reference(a[i], b[i], internalCarries[i - 1], internalCarries[i]);
                HighBitSumInPlace_Reference(a[i], b[i], internalCarries[i - 1]);
            }
            Adjoint LowestBitCarry_Reference(a[0], b[0], internalCarries[0]);
            LowestBitSumInPlace_Reference(a[0], b[0]);
        }

        
    }

     operation LowestBitCarry_Reference (a : Qubit, b : Qubit, carry : Qubit) : Unit is Adj {
        CCNOT(a, b, carry);
    }

    operation HighBitCarry_Reference (a : Qubit, b : Qubit, carryin : Qubit, carryout : Qubit) : Unit is Adj {
        CCNOT(a, b, carryout);
        CCNOT(a, carryin, carryout);
        CCNOT(b, carryin, carryout);
    }

    operation LowestBitSumInPlace_Reference (a : Qubit, b : Qubit) : Unit is Adj {
        CNOT(a, b);
    }

       operation HighBitSumInPlace_Reference (a : Qubit, b : Qubit, carryin : Qubit) : Unit is Adj {
        CNOT(a, b);
        CNOT(carryin, b);
    }

  operation ArbitraryAdder_Challenge_Reference (a : Qubit[], b : Qubit[], sum : Qubit[], carry : Qubit) : Unit is Adj {
        let N = Length(a);

        // Calculate carry bits
        LowestBitCarry_Reference(a[0], b[0], sum[0]);
        for (i in 1 .. N-1) {
            HighBitCarry_Reference(a[i], b[i], sum[i - 1], sum[i]);
        }
        CNOT(sum[N-1], carry);

        // Clean sum qubits and compute sum
        for (i in N-1 .. -1 .. 1) {
            Adjoint HighBitCarry_Reference(a[i], b[i], sum[i - 1], sum[i]);
            HighBitSum_Reference(a[i], b[i], sum[i - 1], sum[i]);
        }
        Adjoint LowestBitCarry_Reference(a[0], b[0], sum[0]);
        LowestBitSum_Reference(a[0], b[0], sum[0]);
    }

     operation HighBitSum_Reference (a : Qubit, b : Qubit, carryin : Qubit, sum : Qubit) : Unit is Adj {
        CNOT(a, sum);
        CNOT(b, sum);
        CNOT(carryin, sum);
    }

        operation LowestBitSum_Reference (a : Qubit, b : Qubit, sum : Qubit) : Unit is Adj {
        CNOT(a, sum);
        CNOT(b, sum);
    }

        /// # Summary
    /// Computes the square of the integer `xs` into `result`,
    /// which must be zero initially.
    ///
    /// # Input
    /// ## xs
    /// $n$-bit number to square (LittleEndian)
    /// ## result
    /// $2n$-bit result (LittleEndian), must be in state $\ket{0}$ initially.
    ///
    /// # Remarks
    /// Uses a standard shift-and-add approach to compute the square. Saves
    /// $n-1$ qubits compared to the straight-forward solution which first
    /// copies out xs before applying a regular multiplier and then undoing
    /// the copy operation.
    operation SquareI (xs: LittleEndian, result: LittleEndian) : Unit {
        body (...) {
            (Controlled SquareI) (new Qubit[0], (xs, result));
        }
        controlled (controls, ...) {
            let n = Length(xs!);

            EqualityFactI(2 * n, Length(result!), "Integer multiplication
                            requires a 2n-bit result registers.");
            AssertAllZero(result!);

            using (anc = Qubit()) {
                for (i in 0..n-1) {
                    (Controlled CNOT) (controls, (xs![i], anc));
                    (Controlled AddI) ([anc], (xs,
                        LittleEndian(result![i..i+n])));
                    (Controlled CNOT) (controls, (xs![i], anc));
                }
            }
        }
        adjoint auto;
        adjoint controlled auto;
    }

}