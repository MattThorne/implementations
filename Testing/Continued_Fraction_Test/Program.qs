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



operation CFCControl(n: Int,mI:Int,bitSize:Int) : (Int,BigInt){
    mutable res = 0;

    //Getting Classcial Result
    let approximatedFraction =
        ContinuedFractionConvergentL(BigFraction(IntAsBigInt(n), IntAsBigInt(2^bitSize)), IntAsBigInt(mI));
    let (approximatedNumerator, approximatedDenominator) = approximatedFraction!;

    //Getting Quantum Result
    using ((p,m,u)=(Qubit[bitSize],Qubit[bitSize],Qubit[bitSize])){

        let nArr = IntAsBoolArray(n,bitSize);
        let mArr = IntAsBoolArray(mI,bitSize);

        for (t in 0..(Length(nArr)-1)){
            if (nArr[t] == true){X(u[t]);}
            if (mArr[t] == true){X(m[t]);}
        }
        set res = CFC(p,m,u);
        ResetAll(p+m+u);
        return(res,approximatedDenominator);

}
}
operation CFC(p:Qubit[],m:Qubit[],u:Qubit[]):Int{
        mutable result = 0;
    using (c=Qubit()){

        ApplyToEachA(X,u);
        Controlled X(u,c);
        ApplyToEachA(X,u);
        X(c);

        Controlled CFCMain([c],(p,m,u));

        X(c);
        ApplyToEachA(X,u);
        Controlled X(u,c);
        ApplyToEachA(X,u);

        set result = MeasureInteger(LittleEndian(p));
        
    }
        return(result);
}



operation CFCMain(p:Qubit[],m:Qubit[],u:Qubit[]):Unit is Ctl{

        mutable len = Length(u);
        let num_its = Ceiling(1.44*IntAsDouble(len + 1));
        mutable numAnc = 0;
        mutable sum = 0;
        mutable add = 1;
        repeat {
            set sum = sum + add;
            set add = add + 1;
            set numAnc = numAnc + 1;
        }until (num_its <= sum);
        let origNumAnc = numAnc;

    using ((r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2) = (Qubit[(len+1)*numAnc],Qubit[(len+1)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len+1)*numAnc],Qubit[(2*(len+1) + 1)*numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc])){
        set len = len + 1;
        let lens = len + 1;

        
        mutable curReg = 0;
        mutable curr = 0;
        mutable j = 0;
        
        repeat{
            ////ASCENDING////////
            for (i in 0..(numAnc-1)){
                
                set j = i+curReg;
                if (j==0){
                    //ApplyToEachA(X,r2[0..(len-1)]);
                    X(r2[len -1]);
                    X(s1[0]);
                    AddI(LittleEndian(u),LittleEndian(r1[0..(len -2)]));
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
                
                if ((i + curr + 1) == num_its){
                    CFExtractRes(p,m,r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)]);
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
                    //ApplyToEachA(X,r2[0..(len-1)]);
                    X(r2[len -1]);
                    X(s1[0]);
                    Adjoint AddI(LittleEndian(u),LittleEndian(r1[0..(len -2)]));
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
                    //ApplyToEachA(X,r2[0..(len-1)]);
                    X(r2[len -1]);
                    X(s1[0]);
                    AddI(LittleEndian(u),LittleEndian(r1[0..(len - 2)]));
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
                        //ApplyToEachA(X,r2[0..(len-1)]);
                        X(r2[len - 1]);
                        X(s1[0]);
                        Adjoint AddI(LittleEndian(u),LittleEndian(r1[0..(len - 2)]));
                    }
            }
            
            
        }until (numAnc==origNumAnc);
    }
    }




operation CFExtractRes(res:Qubit[],m:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[]):Unit is Ctl{
    body(...){
    using ((c1,c2,c3,mPad) = (Qubit(),Qubit(),Qubit(),Qubit())){
        ApplyToEachA(X,r2);
        Controlled X(r2,c1);

        CompareGTI(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(m + [mPad]),c2);
        X(c2);

        Controlled X([c1,c2],c3);
        X(c3);

        Controlled AddI([c1,c2],(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(res + [mPad])));

        Controlled AddI([c3],(LittleEndian(s1[0..(Length(s1)-2)]),LittleEndian(res + [mPad])));
        
        X(c3);
        Controlled X([c1,c2],c3);
        X(c2);
        Adjoint CompareGTI(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(m + [mPad]),c2);
        
        Controlled X(r2,c1);
        ApplyToEachA(X,r2);
    }
    }
    controlled (cs,...){
    using ((c1,c2,c3,mPad) = (Qubit(),Qubit(),Qubit(),Qubit())){
        ApplyToEachA(X,r2);
        Controlled X(r2,c1);

        CompareGTI(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(m + [mPad]),c2);
        X(c2);

        Controlled X([c1,c2],c3);
        X(c3);

        Controlled AddI([c1,c2],(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(res + [mPad])));

        Controlled AddI([c3],(LittleEndian(s1[0..(Length(s1)-2)]),LittleEndian(res + [mPad])));
        
        X(c3);
        Controlled X([c1,c2],c3);
        X(c2);
        Adjoint CompareGTI(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(m + [mPad]),c2);
        
        Controlled X(r2,c1);
        ApplyToEachA(X,r2);
    }
    }

    
}





operation CFIteration (r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],quo:Qubit[],qTs2:Qubit[],anc1:Qubit,anc2:Qubit):Unit is Adj + Ctl{

   let len = Length(r1);
   using ((s2Pad,quoS) = (Qubit[len+1],Qubit())){

           
            DivideI(LittleEndian(r1),LittleEndian(r2),LittleEndian(quo));
    
            for (i in 0..(len-1)){
                SWAP(r1[i],r2[i]);
            }
        
            SignedMultiply(s2,quo + [quoS], qTs2);
          
            for (i in 0..(Length(s1)-1)){
                SWAP(s1[i],s2[i]);
            }
            
            SignedSubtract(s2[0..(Length(s2)-2)] + s2Pad + [s2[(Length(s2)-1)]],qTs2,anc1,anc2);
           
   }



}

operation CFCheck (r2:Qubit[],s2:Qubit[],m:Qubit[],C:Qubit):Unit is Adj + Ctl{
    body (...){
        //CHECKING IF anwser found////////
        
        using ((C2,C3,mPad) = (Qubit(),Qubit(),Qubit())){

        CompareGTI(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(m + [mPad]),C2);//C2 set to 1 if s2>M
        
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

        Adjoint CompareGTI(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(m + [mPad]),C2);//Resetting C2
        }
        /////////////////////////////////////////
    }
    controlled (cs,...){
        //CHECKING IF anwser found////////
        
        using ((C2,C3,mPad) = (Qubit(),Qubit(),Qubit())){

        CompareGTI(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(m + [mPad]),C2);//C2 set to 1 if s2>M
        
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

        Adjoint CompareGTI(LittleEndian(s2[0..(Length(s2)-2)]),LittleEndian(m + [mPad]),C2);//Resetting C2
        }
        /////////////////////////////////////////
    }

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
//|a>|b> =>  |a-b>|garbage>
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