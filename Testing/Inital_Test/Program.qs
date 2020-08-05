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
operation TestD() : Unit{

    using ((r1,s1,m,C1)=(Qubit[2],Qubit[3],Qubit[2],Qubit())){
        X(m[1]);
        X(m[0]);
        DumpMachine();
        CFCheck(r1,s1,m,C1);
        DumpMachine();
        Adjoint CFCheck(r1,s1,m,C1);
        DumpMachine();
        ResetAll(r1+s1+m+[C1]);
    }
}


operation TestCFC() : Unit{
    using ((p,m,u)=(Qubit[4],Qubit[4],Qubit[4])){
        X(m[1]);
        X(m[0]);
        X(u[1]);
        X(u[2]);

        let len = Length(u);
        let num_its = Ceiling(1.5*IntAsDouble(len));
        mutable numAnc = 0;
        mutable sum = 0;
        mutable add = 1;
        repeat {
            set sum = sum + add;
            set add = add + 1;
            set numAnc = numAnc + 1;
        }until (num_its <= sum);
        let origNumAnc = numAnc;

    using ((r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2) = (Qubit[len*numAnc],Qubit[len*numAnc],Qubit[(len + 1)*numAnc],Qubit[(len + 1)*numAnc],Qubit[len*numAnc],Qubit[(2*len + 1)*numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc])){
        let lens = len + 1;
        // DumpRegister((),r1);
        // DumpRegister((),r2);
        // DumpRegister((),s1);
        // DumpRegister((),s2);

        
        mutable curReg = 0;
        mutable curr = 0;
        mutable j = 0;
        repeat{
            ////ASCENDING////////
            for (i in 0..(numAnc-1)){
                set j = i+curReg;
                if (j==0){
                    ApplyToEachA(X,r2[0..(len-1)]);
                    X(s1[0]);
                    AddI(LittleEndian(u),LittleEndian(r1));
                }
                if (j != 0){
                AddI(LittleEndian(r1[((j*len) - len)..((j*len)-1)]),LittleEndian(r1[(j*len)..((j*len)+len-1)]));
                AddI(LittleEndian(r2[((j*len) - len)..((j*len)-1)]),LittleEndian(r2[(j*len)..((j*len)+len-1)]));
                
                AddI(LittleEndian(s1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s1[(j*lens)..((j*lens)+lens-1)]));
                AddI(LittleEndian(s2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s2[(j*lens)..((j*lens)+lens-1)]));
                }

                CFCheck(r2[(j*len)..((j*len)+len-1)],s2[(j*lens)..((j*lens)+lens-1)],m,C1[j]);//C1 set to 1 if either r2=0 or s2>m
                X(C1[j]);
                Controlled CFIteration([C1[j]],(r1[(j*len)..((j*len)+len-1)],r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)],quo[(j*len)..((j*len)+len-1)],qTs2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],anc1[j],anc2[j]));
                //Message($"{i+curr},{num_its}");
                if ((i + curr + 1) == num_its){
                    Message("Found");
                    CFExtractRes(u,m,r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)]);
                }
            
            }
            ////DESCENDING////////
            mutable q=0;
            for (k in 0..(numAnc-2)){
                set q = (numAnc-2) - k;
                set j = q+curReg;
                
                Controlled Adjoint CFIteration([C1[j]],(r1[(j*len)..((j*len)+len-1)],r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)],quo[(j*len)..((j*len)+len-1)],qTs2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],anc1[j],anc2[j]));
                X(C1[j]);
                Adjoint CFCheck(r2[(j*len)..((j*len)+len-1)],s2[(j*lens)..((j*lens)+lens-1)],m,C1[j]);//C1 set to 1 if either r2=0 or s2>m
                
                if (j != 0){
                Adjoint AddI(LittleEndian(r1[((j*len) - len)..((j*len)-1)]),LittleEndian(r1[(j*len)..((j*len)+len-1)]));
                Adjoint AddI(LittleEndian(r2[((j*len) - len)..((j*len)-1)]),LittleEndian(r2[(j*len)..((j*len)+len-1)]));
                
                Adjoint AddI(LittleEndian(s1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s1[(j*lens)..((j*lens)+lens-1)]));
                Adjoint AddI(LittleEndian(s2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s2[(j*lens)..((j*lens)+lens-1)]));
                }
                if (j==0){
                    ApplyToEachA(X,r2[0..(len-1)]);
                    X(s1[0]);
                    Adjoint AddI(LittleEndian(u),LittleEndian(r1));
                }
           
            }
            ///SWAPPING//////
            if (curReg != (origNumAnc-1)){
            for (i in 0..(len-1)){
                SWAP(r1[curReg*len + i],r1[i + (origNumAnc-1)*len]);
                SWAP(r2[curReg*len + i],r2[i + (origNumAnc-1)*len]);
                SWAP(quo[curReg*len + i],quo[i + (origNumAnc-1)*len]);
            }
            
            for (i in 0..(lens-1)){
                SWAP(s1[curReg*lens + i],s1[i + (origNumAnc-1)*lens]);
                SWAP(s2[curReg*lens + i],s2[i + (origNumAnc-1)*lens]);
            }
            
            for (i in 0..(2*len)){
                SWAP(qTs2[curReg*(2*len + 1) + i],qTs2[i + (origNumAnc-1)*(2*len + 1)]);
            }
            
            SWAP(C1[curReg],C1[origNumAnc-1]);
            SWAP(anc1[curReg],anc1[origNumAnc-1]);
            SWAP(anc2[curReg],anc2[origNumAnc-1]);
            
            }
            
            set curr = curr + numAnc;
            set numAnc = numAnc -1;
            set curReg = curReg + 1;
        }until(numAnc==0);

        
        /////Resetting////
        repeat{
            set curReg = curReg - 1;
            set numAnc = numAnc + 1;
            set curr = curr - numAnc;
            
            ///SWAPPING//////
            if (curReg != (origNumAnc-1)){
            for (i in 0..(len-1)){
                SWAP(r1[curReg*len + i],r1[i + (origNumAnc-1)*len]);
                SWAP(r2[curReg*len + i],r2[i + (origNumAnc-1)*len]);
                SWAP(quo[curReg*len + i],quo[i + (origNumAnc-1)*len]);
            }
            for (i in 0..(lens-1)){
                SWAP(s1[curReg*lens + i],s1[i + (origNumAnc-1)*lens]);
                SWAP(s2[curReg*lens + i],s2[i + (origNumAnc-1)*lens]);
            }
            for (i in 0..(2*len)){
                SWAP(qTs2[curReg*(2*len + 1) + i],qTs2[i + (origNumAnc-1)*(2*len + 1)]);
            }
            SWAP(C1[curReg],C1[origNumAnc-1]);
            SWAP(anc1[curReg],anc1[origNumAnc-1]);
            SWAP(anc2[curReg],anc2[origNumAnc-1]);
            }
            
            ////Adjoint DESCENDING////////
            for (q in 0..(numAnc-2)){
                set j = q+curReg;

                if (j==0){
                    ApplyToEachA(X,r2[0..(len-1)]);
                    X(s1[0]);
                    AddI(LittleEndian(u),LittleEndian(r1));
                }

                if (j != 0){
                AddI(LittleEndian(r1[((j*len) - len)..((j*len)-1)]),LittleEndian(r1[(j*len)..((j*len)+len-1)]));
                AddI(LittleEndian(r2[((j*len) - len)..((j*len)-1)]),LittleEndian(r2[(j*len)..((j*len)+len-1)]));
                
                AddI(LittleEndian(s1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s1[(j*lens)..((j*lens)+lens-1)]));
                AddI(LittleEndian(s2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s2[(j*lens)..((j*lens)+lens-1)]));
                }

                CFCheck(r2[(j*len)..((j*len)+len-1)],s2[(j*lens)..((j*lens)+lens-1)],m,C1[j]);//C1 set to 1 if either r2=0 or s2>m
                X(C1[j]);
                Controlled CFIteration([C1[j]],(r1[(j*len)..((j*len)+len-1)],r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)],quo[(j*len)..((j*len)+len-1)],qTs2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],anc1[j],anc2[j]));
            }
            
            ////Adjoint ASCENDING////////
            for (k in 0..(numAnc-1)){
                let i = (numAnc-1) - k;
                set j = i+curReg;

                Controlled Adjoint CFIteration([C1[j]],(r1[(j*len)..((j*len)+len-1)],r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)],quo[(j*len)..((j*len)+len-1)],qTs2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],anc1[j],anc2[j]));
                X(C1[j]);
                Adjoint CFCheck(r2[(j*len)..((j*len)+len-1)],s2[(j*lens)..((j*lens)+lens-1)],m,C1[j]);//C1 set to 1 if either r2=0 or s2>m
                
                
            
                if (j != 0){
                Adjoint AddI(LittleEndian(r1[((j*len) - len)..((j*len)-1)]),LittleEndian(r1[(j*len)..((j*len)+len-1)]));
                Adjoint AddI(LittleEndian(r2[((j*len) - len)..((j*len)-1)]),LittleEndian(r2[(j*len)..((j*len)+len-1)]));
                
                Adjoint AddI(LittleEndian(s1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s1[(j*lens)..((j*lens)+lens-1)]));
                Adjoint AddI(LittleEndian(s2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s2[(j*lens)..((j*lens)+lens-1)]));
                }

                if (j==0){
                        ApplyToEachA(X,r2[0..(len-1)]);
                        X(s1[0]);
                        Adjoint AddI(LittleEndian(u),LittleEndian(r1));
                    }
            }
        }until (numAnc==origNumAnc);

    //ResetAll(r1 + r2+s1+s2+quo+qTs2+C1+anc1+anc2);
    }
    DumpMachine();
    ResetAll(m+u+p);
    }

}
operation CFExtractRes(res:Qubit[],m:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[]):Unit{


    using ((c1,c2,c3) = (Qubit(),Qubit(),Qubit())){
        ApplyToEachA(X,r2);
        Controlled X(r2,c1);
        CompareGTI(LittleEndian(m),LittleEndian(s2[0..(Length(s2)-1)]),c2);
        Controlled X([c1,c2],c3);
        X(c3);

        Controlled AddI([c1,c2],(LittleEndian(s2[0..(Length(s2)-1)]),LittleEndian(res)));
        Controlled AddI([c3],(LittleEndian(s1[0..(Length(s1)-1)]),LittleEndian(res)));
        
        X(c3);
        Controlled X([c1,c2],c3);
        Adjoint CompareGTI(LittleEndian(m),LittleEndian(s2[0..(Length(s2)-1)]),c2);
        Controlled X(r2,c1);
        ApplyToEachA(X,r2);
    }
}





operation CFIteration (r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],quo:Qubit[],qTs2:Qubit[],anc1:Qubit,anc2:Qubit):Unit is Adj + Ctl{
   
   let len = Length(r1);
   using ((s2Pad,quoS) = (Qubit[len+1],Qubit())){

            // Message("Initial");
            // DumpMachine();

           
            DivideI(LittleEndian(r1),LittleEndian(r2),LittleEndian(quo));
        //     Message("Divided:");
        //    DumpMachine();
            for (i in 0..(len-1)){
                SWAP(r1[i],r2[i]);
            }
            // Message("Divide and swapped r1 r2:");
            // DumpRegister((),r1);
            // DumpRegister((),r2);
            // DumpRegister((),quo);
            // Message("Divided and swapped r1 and r2");
            // DumpMachine();
            SignedMultiply(s2,quo + [quoS], qTs2);
            // Message("Multiplied s2 and quo to qTs2");
            // DumpMachine();
            for (i in 0..(Length(s1)-1)){
                SWAP(s1[i],s2[i]);
            }
            // Message("Multiplied and swapped s1 s2:");
            // DumpRegister((),s1);
            // DumpRegister((),s2);
            // DumpRegister((),quo);
            // DumpRegister((),qTs2);
            // Message("Swapped s1 and s2");
            //DumpMachine();

            SignedSubtract(s2[0..(Length(s2)-2)] + s2Pad + [s2[(Length(s2)-1)]],qTs2,anc1,anc2);
            // Message("Subtrated qTs2froms2:");
            // DumpRegister((),s1);
            // DumpRegister((),s2);
            // DumpRegister((),quo);
            // DumpRegister((),qTs2);
            // Message("Subtracted qTs2 from s2");
            //DumpMachine();
   }


}

operation CFCheck (r2:Qubit[],s2:Qubit[],m:Qubit[],C:Qubit):Unit is Adj{
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