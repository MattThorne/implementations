namespace Quantum.Bell {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Oracles;
    open Microsoft.Quantum.Characterization;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Measurement;
    newtype SignedLittleEndian = LittleEndian;





operation TestCFC() : Unit{

    using ((m,r1,r2,s1,s2,C1) = (Qubit[2],Qubit[2],Qubit[2],Qubit[3],Qubit[3],Qubit())){
        let len = Length(r1);
        X(m[1]);
        X(m[0]);
        X(r1[1]);
        ApplyToEachA(X,r2);
        X(s1[0]);

        CFCheck(r2,s2,m,C1);
        
        ////////CF Iteration//////////////
        using ((quo,qTs2,quoS,anc1,anc2,s2Pad) = (Qubit[len],Qubit[2*len + 1],Qubit(),Qubit(),Qubit(),Qubit[len + 1])){
            Message("Initial");
            DumpMachine();
            DivideI(LittleEndian(r1),LittleEndian(r2),LittleEndian(quo));
            Message("Divided");
            DumpMachine();
            for (i in 0..(Length(quo)-1)){
                SWAP(r1[i],r2[i]);
            }
            Message("Divided and swapped r1 and r2");
            DumpMachine();
            SignedMultiply(s2,quo + [quoS], qTs2);
            Message("Multiplied s2 and quo to qTs2");
            DumpMachine();
            for (i in 0..(Length(s1)-1)){
                SWAP(s1[i],s2[i]);
            }
            Message("Swapped s1 and s2");
            DumpMachine();

            SignedSubtract(s2 + s2Pad,qTs2,anc1,anc2);
            Message("Subtracted qTs2 from s2");
            DumpMachine();
        }


    //ResetAll(t1+t2+C1);
    }

}

operation CFCheck (r2:Qubit[],s2:Qubit[],m:Qubit[],C:Qubit):Unit{
        //CHECKING IF anwser found////////
        let s2LE = LittleEndian(s2[0..(Length(s2)-2)]);
        using ((anc,C2,C3) = (Qubit[Length(s2)-Length(m)-1],Qubit(),Qubit())){
        CompareGTI(s2LE,LittleEndian(m + anc),C2);//C2 set to 1 if s2>M
        
        ApplyToEachA(X,r2);
        Controlled X(r2,C3);//if r2=0 C3=1
        ApplyToEachA(X,r2);
        
        X(C2);
        X(C3);
        Controlled X([C2,C3],C);
        X(C2);
        X(C3);
        X(C);//C1 set to 1 if either r2=0 or s2>m

        ApplyToEachA(X,r2);
        Controlled X(r2,C3);//Resetting C3
        ApplyToEachA(X,r2);

        Adjoint CompareGTI(s2LE,LittleEndian(m + anc),C2);//Resetting C2
        }
        /////////////////////////////////////////

}

  operation MinimalMultiplyI (xs: Qubit[], ys: Qubit[], result: Qubit[]) : Unit {
            let lenXs = Length(xs);
            let lenYs = Length(ys);

            
            EqualityFactI(lenXs + lenYs, Length(result), "Minimal multiplication requires result register to be equal to sum of multiplcan registers");
            AssertAllZero(result);

            for (i in 0..(lenXs-1)) {
                (Controlled AddI) ([xs[i]], (LittleEndian(ys), LittleEndian(result[i..i+lenYs])));
            }
    }
//|a>|b> =>  |a-b>|b>
operation SignedSubtract(a:Qubit[],b:Qubit[],anc:Qubit,anc2:Qubit):Unit{
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


operation SignedMultiply(a : Qubit[], b:Qubit[], c:Qubit[]) : Unit{
    EqualityFactI((2*Length(a) - 1), Length(c), "Signed multiplication requires a (2n-1)-bit result register.");

    let aS = a[Length(a) - 1];
    let bS = b[Length(b) - 1];
    let cS = c[Length(c)- 1];
    CNOT(aS,cS);
    CNOT(bS,cS);

    MultiplyI(LittleEndian(a[0..(Length(a)-2)]),LittleEndian(b[0..(Length(b)-2)]),LittleEndian(c[0..(Length(c)-2)]));
}






operation TestingQFT(): Unit{
    let a = 5;
    let m = 21;
    
using(j = Qubit[9]){
    using (r = Qubit[5]){
        let frequencyEstimateNumerator = LittleEndian(j); 
        let eigenstateRegisterLE = LittleEndian(r); 
        ApplyXorInPlace(1, eigenstateRegisterLE);
        let oracle = DiscreteOracle(ApplyOrderFindingOracle(a, m, _, _));

        QuantumPhaseEstimationTest(oracle, eigenstateRegisterLE!, LittleEndianAsBigEndian(frequencyEstimateNumerator));

        let mes = MeasureInteger(LittleEndian(r)); 
        Message($"{mes}");
        
    }
    DumpMachine("/Users/Matt/Documents/Masters/Dissertation/DisQsharp/Qs_Output3.txt");
    Adjoint QFT(BigEndian(j));
    DumpMachine("/Users/Matt/Documents/Masters/Dissertation/DisQsharp/Qs_Output4.txt");
    let final_mes = MeasureInteger(LittleEndian(j)); 
    Message($"{final_mes}");
ResetAll(j); 
}
    
}
    operation QuantumPhaseEstimationTest (oracle : DiscreteOracle, targetState : Qubit[], controlRegister : BigEndian) : Unit is Adj + Ctl {
        let nQubits = Length(controlRegister!);
        AssertAllZeroWithinTolerance(controlRegister!, 1E-10);
        ApplyToEachCA(H, controlRegister!);
        DumpMachine("/Users/Matt/Documents/Masters/Dissertation/DisQsharp/Qs_Output.txt");
        for (idxControlQubit in 0 .. nQubits - 1) {
            let control = (controlRegister!)[idxControlQubit];
            let power = 2 ^ ((nQubits - idxControlQubit) - 1);
            Controlled oracle!([control], (power, targetState));
        }
        DumpMachine("/Users/Matt/Documents/Masters/Dissertation/DisQsharp/Qs_Output2.txt");
        //Adjoint QFT(controlRegister);
    }







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

    
    operation MultiplySI (xs: SignedLittleEndian,
                          ys: SignedLittleEndian,
                          result: SignedLittleEndian): Unit {
        body (...) {
            (Controlled MultiplySI) (new Qubit[0], (xs, ys, result));
        }
        controlled (controls, ...) {
            let n = Length(xs!!);
            using ((signx, signy) = (Qubit(), Qubit())) {
                CNOT(Tail(xs!!), signx);
                CNOT(Tail(ys!!), signy);
                (Controlled Invert2sSI)([signx], xs);
                (Controlled Invert2sSI)([signy], ys);

                (Controlled MultiplyI) (controls, (xs!, ys!, result!));
                CNOT(signx, signy);
                // No controls required since `result` will still be zero
                // if we did not perform the multiplication above.
                (Controlled Invert2sSI)([signy], result);
                CNOT(signx, signy);

                (Controlled Adjoint Invert2sSI)([signx], xs);
                (Controlled Adjoint Invert2sSI)([signy], ys);
                CNOT(Tail(xs!!), signx);
                CNOT(Tail(ys!!), signy);
            }
        }
        adjoint auto;
        adjoint controlled auto;
    }

     operation Invert2sSI (xs: SignedLittleEndian) : Unit {
        body (...) {
            (Controlled Invert2sSI) (new Qubit[0], xs);
        }
        controlled (controls, ...) {
            ApplyToEachCA((Controlled X)(controls, _), xs!!);

            using (ancillas = Qubit[Length(xs!!)]) {
                (Controlled X)(controls, ancillas[0]);
                AddI(LittleEndian(ancillas), xs!);
                (Controlled X)(controls, ancillas[0]);
            }
        }
        adjoint auto;
        adjoint controlled auto;
    }

}