//////////////////////////////////////////////////////////////////////////////////////
//This program implements a fully reversible Signed subtraction operation/          //
//Performing the transformation |a>|b>|0>|0> -> |a>|b>|a - b>|garbage>              //
//Where a and b are both signed integers                                            //
//Since there is garbage in the output this implementation is not optimal in space. //
//////////////////////////////////////////////////////////////////////////////////////

namespace SignedSubtract.Testing {


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

    using ((a,b,c1,c2) = (Qubit[numBits+2],Qubit[numBits+1],Qubit(),Qubit())){
        //Setting the a and m into quantum registers
        for (i in 0..(Length(aArr) -1)){
            if (aArr[i] == true){X(a[i]);}
        }
        if (aS == 1){X(a[Length(a) -1]);}
        for (i in 0..(Length(bArr) -1)){
            if (bArr[i] == true){X(b[i]);}
        }
        if (bS  == 1){X(b[Length(b) -1]);}
        
         
        SignedSubtract(a,b,c1,c2);
        mutable result = 0;
        
        //Collecting the result
        set result = MeasureInteger(LittleEndian(a[0..numBits]));
        let resultSign = MeasureInteger(LittleEndian([a[numBits+1]]));
        if (resultSign == 1){set result = result * -1;}

        ResetAll(a+b+[c1,c2]);
        return result;
    }

 }

operation Testing_in_Superposition(): Unit{
let numQubits = 5;
using ((a,b,c1,c2) = (Qubit[numQubits+1],Qubit[numQubits],Qubit(),Qubit())){
        //Putting both a and m into superposition
        // ApplyToEach(H,a);
        // ApplyToEach(H,b);
        // ApplyToEach(H,m);
        X(a[1]);
        X(a[numQubits-1]);
        X(b[1]);
        

        SignedSubtract(a,b,c1,c2);

        //Print out Result
        //DumpMachine("TestingInSuperpositionResults.txt");
        ResetAll(a+b+[c1,c2]);
    } 
}


operation SignedSubtract(a:Qubit[],b:Qubit[],anc:Qubit,anc2:Qubit):Unit is Adj + Ctl{
    body(...){
    EqualityFactI(Length(a) , Length(b) + 1, "Signed Subtraction, a must have one more qubit than b");
    CNOT(a[Length(a)-1],anc2);
    CNOT(b[Length(b)-1],anc2);
    X(anc2);

    
    Controlled CompareGTI([anc2],(LittleEndian(b[0..(Length(b)-2)]),LittleEndian(a[0..(Length(a)-3)]),anc));
    for (i in 0..(Length(a)-3)){
        Controlled SWAP([anc,anc2],(a[i],b[i]));
    }
    Controlled Adjoint AddI([anc2],(LittleEndian(b[0..(Length(b)-2)]),LittleEndian(a[0..(Length(a)-3)])));
    Controlled X([anc,anc2],a[Length(a)-1]);


    X(anc2);
    Controlled AddI([anc2],(LittleEndian(b[0..(Length(b)-2)]),LittleEndian(a[0..(Length(a)-2)])));
    X(anc2);
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