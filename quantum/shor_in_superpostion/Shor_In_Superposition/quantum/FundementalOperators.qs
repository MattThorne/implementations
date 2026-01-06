//////////////////////////////////////////////////////////////
//This file contains all the fundemental operators required //
//to implement Shor's algorithm in superposition.           //
//////////////////////////////////////////////////////////////

namespace ShorInSuperposition {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Oracles;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Characterization;
    open Microsoft.Quantum.Diagnostics;


operation SquareModM(a:Qubit[],Ms:Qubit[],Ts:Qubit[]) : Unit is Adj + Ctl{
    let num = Length(a);
    using ((aS,aSPad) = (Qubit[num],Qubit[num])){
        SquareI(LittleEndian(a),LittleEndian(aS + aSPad));
        using ((anc,MsPad) = (Qubit[num*2],Qubit[num])){
            DivideI(LittleEndian(aS + aSPad),LittleEndian(Ms + MsPad),LittleEndian(anc));
            AddI(LittleEndian(aS),LittleEndian(Ts));
            Adjoint DivideI(LittleEndian(aS + aSPad),LittleEndian(Ms + MsPad),LittleEndian(anc));
        } 
        Adjoint  SquareI(LittleEndian(a),LittleEndian(aS + aSPad)); 
    }  
}



operation MultiplyModM(a:Qubit[],b:Qubit[],Ms:Qubit[],Ts:Qubit[]) : Unit is Adj + Ctl{
    let num = Length(a);
    using ((aS,aSPad) = (Qubit[num],Qubit[num])){
        MultiplyI(LittleEndian(a),LittleEndian(b),LittleEndian(aS + aSPad));
        using ((anc,MsPad) = (Qubit[num*2],Qubit[num])){
            DivideI(LittleEndian(aS + aSPad),LittleEndian(Ms + MsPad),LittleEndian(anc));
            AddI(LittleEndian(aS),LittleEndian(Ts));
            Adjoint DivideI(LittleEndian(aS + aSPad),LittleEndian(Ms + MsPad),LittleEndian(anc));
        } 
        Adjoint  MultiplyI(LittleEndian(a),LittleEndian(b),LittleEndian(aS + aSPad));
    }  
}



operation SignedMultiply(a : Qubit[], b:Qubit[], c:Qubit[]) : Unit is Adj + Ctl{
    
    body(...){
    EqualityFactI((2*Length(a) - 1), Length(c), "Signed multiplication requires a (2n-1)-bit result register.");
    let aS = a[Length(a) - 1];
    let bS = b[Length(b) - 1];
    let cS = c[Length(c)- 1];
    CNOT(aS,cS);
    CNOT(bS,cS);

    MultiplyI(LittleEndian(a[0..(Length(a)-2)]),LittleEndian(b[0..(Length(b)-2)]),LittleEndian(c[0..(Length(c)-2)]));
    }
    adjoint invert;
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

///////////////////////
///////////////////////Operators Beyond here are Microsoft Implemented basic operations obtained from their github page.//////////////////
///////////////////////Copyright (c) Microsoft Corporation. All rights reserved.
///////////////////////Licensed under the MIT License.

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
