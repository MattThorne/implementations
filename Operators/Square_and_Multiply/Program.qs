namespace ModularMultiplication.Testing {


    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;


operation Testing_with_Toffoli(aI:BigInt,jI:BigInt,mI:BigInt,numBits:Int):Int{
    let aArr = BigIntAsBoolArray(aI);
    let jArr = BigIntAsBoolArray(jI);
    let mArr = BigIntAsBoolArray(mI);
    using ((a,m,j,t) = (Qubit[numBits],Qubit[numBits],Qubit[numBits],Qubit[numBits])){
        //Setting the a and m into quantum registers
        for (i in 0..(Length(aArr) -1)){
            if (aArr[i] == true){X(a[i]);}
        }
        for (i in 0..(Length(jArr) -1)){
            if (jArr[i] == true){X(j[i]);}
        }
        for (i in 0..(Length(mArr) -1)){
            if (mArr[i] == true){X(m[i]);}
        }

        //Carrying out modular squaring
        SquareAndMultiply(a,m,j,t);
        

        //Collecting the result
        let result = MeasureInteger(LittleEndian(t));
        ResetAll(a+j+m+t);
        return result;
    }

}

operation Testing_in_Superposition(bitSize: Int): Unit{
    using ((a,m,j,t) = (Qubit[bitSize],Qubit[bitSize],Qubit[2*bitSize + 1],Qubit[bitSize])){
        
        
        SquareAndMultiply(a,m,j,t);
        
        ResetAll(a+j+m+t);
    }

}

operation SquareAndMultiply(a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[]): Unit{
    let lenJ = Length(j);
    let lenA = Length(a);
    let numAnc = Ceiling(Lg(IntAsDouble(lenJ -1))) + 1;
    //Message($"{numAnc}");

    mutable arr = new Int[numAnc + 2]; // last item in array used to contol if result has been found
    set arr w/= 0 <- 1;  


    using ((v,c,z,az,ld) = (Qubit[lenA*numAnc],Qubit(),Qubit(),Qubit(),Qubit())){

                //Checking for j = 0
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);
                X(az);

                set arr w/= (0..(Length(arr)-1)) <- Pebble(1,numAnc,arr,a,m,j,result,v,c,z,az,ld);
                set arr w/= (0..(Length(arr)-1)) <- Unpebble(1,numAnc,arr,a,m,j,result,v,c,z,az,ld);

                //Resetting control all zero qubit
                X(az);
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);
    
    }
    
   


}



operation Pebble(s: Int, n:Int, arr:Int[],a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[],v:Qubit[],c:Qubit,z:Qubit,az:Qubit,ld:Qubit): Int[]{
    mutable narr = new Int[0];
    for (i in 0..(Length(arr) -1)){
        set narr += [arr[i]]; 
    }
    if (n!=0){
        let t = s + PowI(2,(n-1));
        set narr w/= (0..(Length(narr)-1)) <- Pebble(s,(n-1),narr,a,m,j,result,v,c,z,az,ld);
        //put a free pebble on node t
        set narr w/= (0..(Length(narr)-1)) <- SquareAndMultiplyStep(t,narr,1,a,m,j,result,v,c,z,az,ld);
        // Message($"{narr}");
        // DumpRegister((),v);
        set narr w/= (0..(Length(narr)-1)) <- Unpebble(s,(n-1),narr,a,m,j,result,v,c,z,az,ld);
        set narr w/= (0..(Length(narr)-1)) <- Pebble(t,(n-1),narr,a,m,j,result,v,c,z,az,ld);
        
    }
    return narr;
}

operation Unpebble(s: Int, n:Int, arr:Int[],a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[],v:Qubit[],c:Qubit,z:Qubit,az:Qubit,ld:Qubit):Int[]{
    mutable narr = new Int[0];
    for (i in 0..(Length(arr) -1)){
        set narr += [arr[i]]; 
    }
    if (n!=0){
        let t = s + PowI(2,(n-1));
        set narr w/= (0..(Length(narr)-1)) <-Unpebble(t,(n-1),narr,a,m,j,result,v,c,z,az,ld);
        set narr w/= (0..(Length(narr)-1)) <-Pebble(s,(n-1),narr,a,m,j,result,v,c,z,az,ld);
        //take a  pebble from node t
        set narr w/= (0..(Length(narr)-1)) <- SquareAndMultiplyStep(t,narr,0,a,m,j,result,v,c,z,az,ld);
        // Message($"{narr}");
        // DumpRegister((),v);
        set narr w/= (0..(Length(narr)-1)) <-Unpebble(s,(n-1),narr,a,m,j,result,v,c,z,az,ld);
    }
    return narr;
}

operation SquareAndMultiplyStep(t:Int,arr:Int[] ,d:Int,a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[],v:Qubit[],c:Qubit,z:Qubit,az:Qubit,ld:Qubit):Int[]{
    


    mutable narr = new Int[0];
    for (k in 0..(Length(arr) -1)){
        set narr += [arr[k]]; 
    }


    mutable next = 0;
    mutable curr = 0;
    let lenA = Length(a);
    

    
    //Find Current Register
    mutable found = false;
    mutable i = 0;
    repeat{
        if (arr[i] == (t-1)){
            set curr = i;
            set found = true;
        }
        set i = i + 1;
    }until (found == true);
    

    if (d==1){

        //Finds first empty item in a
        set found = false;
        set i = 0; 
        repeat{
        if (arr[i] == 0){
            set next = i;
            set found = true;
        }
        set i = i + 1;
        }until (found == true);

    //set arr[next] = arr[next] + (arr[curr] + 1);
    set narr w/= next <- narr[next] + (narr[curr] + 1);

    //Conduct Pebble calculation

    if ((narr[next]-1)<=(Length(j)-1)){


                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(Length(j) - 1 - narr[curr])...]);
                    Controlled X(j[(Length(j) - 1 - narr[curr])...],z);
                    ApplyToEachA(X,j[(Length(j) - 1 - narr[curr])...]);
                    X(z);


                    //checking for last digit and zero
                    ApplyToEachA(X,j[(Length(j) - 1 - (narr[curr] -1))...]);
                    Controlled X(j[(Length(j) - 1 - (narr[curr] -1))...],ld);
                    ApplyToEachA(X,j[(Length(j) - 1 - (narr[curr] -1))...]);
                    X(ld);



                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(Length(j) - 1 - narr[curr])]],c);

                    
                    //Conducting square and multiply iteration
                    Controlled SquareAndMultiplyIteration([az],(a,(a+v)[(curr*lenA)..(((curr*lenA)+lenA)-1)],m,c,z,ld,(a+v)[(next*lenA)..(((next*lenA)+lenA)-1)]));

                    
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],(a+v)[(next*lenA)]);
                    X(az);

                    


                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(Length(j) - 1 - narr[curr])]],c);
                    
                    
                    //Resseting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(Length(j) - 1 - (narr[curr] -1))...]);
                    Controlled X(j[(Length(j) - 1 - (narr[curr] -1))...],ld);
                    ApplyToEachA(X,j[(Length(j) - 1 - (narr[curr] -1))...]);
                    
                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(Length(j) - 1 - narr[curr])...]);
                    Controlled X(j[(Length(j) - 1 - narr[curr])...],z);
                    ApplyToEachA(X,j[(Length(j) - 1 - narr[curr])...]);
                    }

                    if ((narr[next] - 1) == (Length(j)-1) and (narr[Length(narr)-1] == 0)){

                        AddI(LittleEndian((a+v)[(next*lenA)..(((next*lenA)+lenA)-1)]),LittleEndian(result));
                        set narr w/= (Length(narr)-1) <- 1;
                    }
   



    }


    if (d==0){
        
        set found = false;
        set i = 0;
        repeat{
        if (arr[i] == t){
            set next = i;
            set found = true;
        }
        set i = i + 1;
    }until (found == true);
    

    if ((narr[next]-1)<=(Length(j)-1)){

                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(Length(j) - 1 - narr[curr])...]);
                    Controlled X(j[(Length(j) - 1 - narr[curr])...],z);
                    ApplyToEachA(X,j[(Length(j) - 1 - narr[curr])...]);
                    X(z);


                    //checking for last digit and zero
                    ApplyToEachA(X,j[(Length(j) - 1 - (narr[curr] -1))...]);
                    Controlled X(j[(Length(j) - 1 - (narr[curr] -1))...],ld);
                    ApplyToEachA(X,j[(Length(j) - 1 - (narr[curr] -1))...]);
                    X(ld);



                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(Length(j) - 1 - narr[curr])]],c);

                    //Conducting square and multiply iteration
                    Controlled Adjoint SquareAndMultiplyIteration([az],(a,(a+v)[(curr*lenA)..(((curr*lenA)+lenA)-1)],m,c,z,ld,(a+v)[(next*lenA)..(((next*lenA)+lenA)-1)]));


                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],(a+v)[(next*lenA)]);
                    X(az);
    
                    


                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(Length(j) - 1 - narr[curr])]],c);
                    
                    
                    //Resseting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(Length(j) - 1 - (narr[curr] -1))...]);
                    Controlled X(j[(Length(j) - 1 - (narr[curr] -1))...],ld);
                    ApplyToEachA(X,j[(Length(j) - 1 - (narr[curr] -1))...]);
                    
                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(Length(j) - 1 - narr[curr])...]);
                    Controlled X(j[(Length(j) - 1 - narr[curr])...],z);
                    ApplyToEachA(X,j[(Length(j) - 1 - narr[curr])...]);
                    }

                    set narr w/= next <- narr[next] - (narr[curr] + 1);




    }
    return narr;
}



operation SquareAndMultiplyIteration(a:Qubit[],v:Qubit[],m:Qubit[],c:Qubit,z:Qubit,ld:Qubit,t:Qubit[]) : Unit is Adj + Ctl{
        X(z);
        Controlled AddI([z],(LittleEndian(v),LittleEndian(t)));
        X(z);

        X(ld);
        Controlled AddI([z,ld],(LittleEndian(v),LittleEndian(t)));
        X(ld);

        using (anc = Qubit[Length(v)]){
        Controlled SquareModM([z,ld],(v,m,anc));
        Controlled MultiplyModM([z,c,ld],(a,anc,m,t));
        X(c);
        Controlled AddI([z,c,ld],(LittleEndian(anc),LittleEndian(t)));
        X(c);
        

        Controlled Adjoint SquareModM([z,ld],(v,m,anc));
        } 
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



}