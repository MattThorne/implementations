namespace ModularMultiplication.Testing {


    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;


operation Testing_with_Toffoli(aI:BigInt,bI:BigInt,mI:BigInt,numBits:Int):Int{
    let aArr = BigIntAsBoolArray(aI);
    let bArr = BigIntAsBoolArray(bI);
    let mArr = BigIntAsBoolArray(mI);
    using ((a,b,m,t) = (Qubit[numBits],Qubit[numBits],Qubit[numBits],Qubit[numBits])){
        //Setting the a and m into quantum registers
        for (i in 0..(Length(aArr) -1)){
            if (aArr[i] == true){X(a[i]);}
        }
        for (i in 0..(Length(bArr) -1)){
            if (bArr[i] == true){X(b[i]);}
        }
        for (i in 0..(Length(mArr) -1)){
            if (mArr[i] == true){X(m[i]);}
        }

        //Carrying out modular squaring
        ModularMultiply(a,b,m,t);

        //Collecting the result
        let result = MeasureInteger(LittleEndian(t));
        ResetAll(a+b+m+t);
        return result;
    }

}

operation Testing_in_Superposition(): Unit{
let numQubits = 2;
using ((a,b,m,t) = (Qubit[numQubits],Qubit[numQubits],Qubit[numQubits],Qubit[numQubits])){
        //Putting both a and m into superposition
        ApplyToEach(H,a);
        ApplyToEach(H,b);
        ApplyToEach(H,m);
        

        ModularMultiply(a,b,m,t);

        //Print out Result
        DumpMachine("TestingInSuperpositionResults.txt");
        ResetAll(a+b+m+t);
    } 
}

operation ModularMultiply(a:Qubit[],b:Qubit[],m:Qubit[],Ts:Qubit[]) : Unit is Adj + Ctl{
    let num = Length(a);
    using ((aS,aSPad,zC) = (Qubit[num],Qubit[num],Qubit())){
        ApplyToEachCA(X,m);
        Controlled X(m,zC);
        ApplyToEachCA(X,m);
        X(zC);

        Controlled MultiplyI([zC],(LittleEndian(a),LittleEndian(b),LittleEndian(aS + aSPad)));
        using ((anc,mPad) = (Qubit[num*2],Qubit[num])){
            Controlled DivideI([zC],(LittleEndian(aS + aSPad),LittleEndian(m + mPad),LittleEndian(anc)));
            Controlled AddI([zC],(LittleEndian(aS),LittleEndian(Ts)));
            Controlled Adjoint DivideI([zC],(LittleEndian(aS + aSPad),LittleEndian(m + mPad),LittleEndian(anc)));
        } 
        Controlled Adjoint  MultiplyI([zC],(LittleEndian(a),LittleEndian(b),LittleEndian(aS + aSPad)));
        
        X(zC);
        ApplyToEachCA(X,m);
        Controlled X(m,zC);
        ApplyToEachCA(X,m);
        
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