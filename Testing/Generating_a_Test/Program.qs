namespace SignedMultiply.Testing {


    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;


operation Testing_with_Toffoli(mI:BigInt,numBits:Int, Ran: BigInt):Int{
    let mArr = BigIntAsBoolArray(mI);
    using ((a,m) = (Qubit[numBits],Qubit[numBits])){
        //Setting the a and m into quantum registers
        for (i in 0..(Length(mArr) -1)){
            if (mArr[i] == true){X(m[i]);}
        }

        //Carrying out modular squaring
        GenerateA(m,a,Ran);
        mutable result = 0;
        //Collecting the result
        set result = MeasureInteger(LittleEndian(a));

        ResetAll(a+m);
        return result;
    }

}

operation Testing_in_Superposition(Ran: Int, numQubits: Int): Unit{
using ((a,m) = (Qubit[numQubits],Qubit[numQubits])){
        //Putting both a and m into superposition
        ApplyToEach(H,m);
        
        
        
        
        //DumpMachine("TestingInSuperpositionResults.txt");

        //GenerateA(m,a,Ran);

        //Print out Result
        DumpMachine("TestingInSuperpositionResults.txt");
        ResetAll(a+m);
    } 
}



    //Generates a = 1 + (R mod (M-1))
    //takes |M>|0> -> |M>|a>
    //Ms must be superpostition greater than 1
    operation GenerateA(Ms:Qubit[],As: Qubit[],Ran: BigInt) : Unit{
      let num = Length(Ms);
      using ((tmp1,tmp2,tmpM) = (Qubit[num],Qubit[num],Qubit[num])){
            //Generate Random int between 1 <= Ran <= (upper bound of m - 1)
          //let Ran = RandomInt((2^4) - 2) + 1;
          Message($"Random Integer is: {Ran}");

          //Seting tmpM to M-1
          ApplyToEachA(X,tmpM);
          AddI(LittleEndian(Ms),LittleEndian(tmpM));

          let RanArr = BigIntAsBoolArray(Ran);
          //Encoding Ran into the quantum register tmp1
          for (i in 0..(Length(tmp1)-1)){
            if (RanArr[i] == true){
              X(tmp1[i]);
            } 
          }

          //Creating Divide results
          DivideI(LittleEndian(tmp1),LittleEndian(tmpM),LittleEndian(tmp2));

          //Setting As to |1>
          X(As[0]);
          //Adding As to tmp1 to create |1+ R mod (M-1)>
          AddI(LittleEndian(tmp1),LittleEndian(As));

          //Uncomputing the Divide
          Adjoint DivideI(LittleEndian(tmp1),LittleEndian(tmpM),LittleEndian(tmp2));
          //Decoding Ran from tmp1
          for (i in 0..(Length(tmp1)-1)){
            if (RanArr[i] == true){
              X(tmp1[i]);
              } 
            }
          //Reseting tmpM to 0
          Adjoint AddI(LittleEndian(Ms),LittleEndian(tmpM));
          ApplyToEachA(X,tmpM);
          
          
      }
    }



//Required Operators
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
operation CompareGTI (xs: LittleEndian, ys: LittleEndian,
                            result: Qubit) : Unit is Adj + Ctl {
        GreaterThan(xs, ys, result);
    }

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


}