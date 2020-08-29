namespace SignedMultiply.Testing {


    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;


operation Testing_with_Toffoli(aI:BigInt,aS:Int,bI:BigInt,bS:Int,numBits:Int):Int{
    let aArr = BigIntAsBoolArray(aI);
    let bArr = BigIntAsBoolArray(bI);
    using ((a,b,t) = (Qubit[numBits+1],Qubit[numBits+1],Qubit[2*(numBits+1) -1])){
        //Setting the a and m into quantum registers
        for (i in 0..(Length(aArr) -1)){
            if (aArr[i] == true){X(a[i]);}
        }
        if (aS == 1){X(a[numBits]);}
        for (i in 0..(Length(bArr) -1)){
            if (bArr[i] == true){X(b[i]);}
        }
        if (bS  == 1){X(b[numBits]);}

        //Carrying out modular squaring
        SignedMultiply(a,b,t);
        mutable result = 0;
        //Collecting the result
        set result = MeasureInteger(LittleEndian(t[0..(2*(numBits+1) -3)]));
        let resultSign = MeasureInteger(LittleEndian([t[2*(numBits+1) -2]]));
        if (resultSign == 1){set result = result * -1;}

        ResetAll(a+b+t);
        return result;
    }

}

operation Testing_in_Superposition(): Unit{
let numQubits = 3;
using ((a,b,t) = (Qubit[numQubits],Qubit[numQubits],Qubit[2*numQubits - 1])){
        //Putting both a and m into superposition
        // ApplyToEach(H,a);
        // ApplyToEach(H,b);
        // ApplyToEach(H,m);
        X(a[1]);
        X(a[numQubits-1]);
        X(b[1]);
        
        

        SignedMultiply(a,b,t);

        //Print out Result
        DumpMachine("TestingInSuperpositionResults.txt");
        ResetAll(a+b+t);
    } 
}

operation SignedMultiply(a : Qubit[], b:Qubit[], t:Qubit[]) : Unit is Adj + Ctl{
    
    body(...){
    EqualityFactI((2*Length(a) - 1), Length(t), "Signed multiplication requires a (2n-1)-bit result register.");
    let aS = a[Length(a) - 1];
    let bS = b[Length(b) - 1];
    let tS = t[Length(t)- 1];
    CNOT(aS,tS);
    CNOT(bS,tS);

    MultiplyI(LittleEndian(a[0..(Length(a)-2)]),LittleEndian(b[0..(Length(b)-2)]),LittleEndian(t[0..(Length(t)-2)]));
    }
    adjoint invert;
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