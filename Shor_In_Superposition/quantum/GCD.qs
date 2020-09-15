/////////////////////////////////////////////////////////////////////////
//This program implements a fully reversible greatest common divisor   //
//operation                                                            //
//Performing the transformation |a>|b>|0> -> |a>|b>|gcd(a,b)>          //
//Where both a and b are quantum numbers                               //
/////////////////////////////////////////////////////////////////////////


namespace ShorInSuperposition {
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



operation GCDMain(p:Qubit[],m:Qubit[],u:Qubit[]):Unit{
    let len = Length(u);
    mutable numAnc = Ceiling(Lg(1.44*IntAsDouble(len + 1))) + 1;
    //Message($"{numAnc}");

    mutable arr = new Int[numAnc + 2]; // last item in array used to contol if result has been found
    set arr w/= 0 <- 1;
    set numAnc = numAnc + 1;  
    using ((r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4) = (Qubit[(len+1)*numAnc],Qubit[(len+1)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len+1)*numAnc],Qubit[(2*(len+1) + 1)*numAnc],Qubit[(2*(len+1) + 1)*numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc])){
        set numAnc = numAnc - 1; 
        set arr w/= (0..(Length(arr)-1)) <- GCDPebble(1,numAnc,arr,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
        set arr w/= (0..(Length(arr)-1)) <- GCDUnpebble(1,numAnc,arr,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);

    }
}


operation GCDPebble(s: Int, n:Int, arr:Int[],p:Qubit[],m:Qubit[],u:Qubit[],r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],t1:Qubit[],t2:Qubit[],quo:Qubit[],qTs2:Qubit[],qTt2:Qubit[],C1:Qubit[],anc1:Qubit[],anc2:Qubit[],anc3:Qubit[],anc4:Qubit[]): Int[]{
    mutable narr = new Int[0];
    for (i in 0..(Length(arr) -1)){
        set narr += [arr[i]]; 
    }
    if (n!=0){
        let t = s + PowI(2,(n-1));
        set narr w/= (0..(Length(narr)-1)) <- GCDPebble(s,(n-1),narr,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
        //put a free pebble on node t
        set narr w/= (0..(Length(narr)-1)) <- GCDStep(t,narr,1,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
        // Message($"{narr}");
        // DumpRegister((),v);
        set narr w/= (0..(Length(narr)-1)) <- GCDUnpebble(s,(n-1),narr,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
        set narr w/= (0..(Length(narr)-1)) <- GCDPebble(t,(n-1),narr,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
        
    }
    return narr;
}

operation GCDUnpebble(s: Int, n:Int, arr:Int[],p:Qubit[],m:Qubit[],u:Qubit[],r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],t1:Qubit[],t2:Qubit[],quo:Qubit[],qTs2:Qubit[],qTt2:Qubit[],C1:Qubit[],anc1:Qubit[],anc2:Qubit[],anc3:Qubit[],anc4:Qubit[]):Int[]{
    mutable narr = new Int[0];
    for (i in 0..(Length(arr) -1)){
        set narr += [arr[i]]; 
    }
    if (n!=0){
        let t = s + PowI(2,(n-1));
        set narr w/= (0..(Length(narr)-1)) <-GCDUnpebble(t,(n-1),narr,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
        set narr w/= (0..(Length(narr)-1)) <-GCDPebble(s,(n-1),narr,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
        //take a  pebble from node t
        set narr w/= (0..(Length(narr)-1)) <- GCDStep(t,narr,0,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
        // Message($"{narr}");
        // DumpRegister((),v);
        set narr w/= (0..(Length(narr)-1)) <-GCDUnpebble(s,(n-1),narr,p,m,u,r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4);
    }
    return narr;
}

operation GCDStep(t:Int,arr:Int[] ,d:Int,p:Qubit[],m:Qubit[],u:Qubit[],r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],t1:Qubit[],t2:Qubit[],quo:Qubit[],qTs2:Qubit[],qTt2:Qubit[],C1:Qubit[],anc1:Qubit[],anc2:Qubit[],anc3:Qubit[],anc4:Qubit[]):Int[]{
    mutable narr = new Int[0];
    for (k in 0..(Length(arr) -1)){
        set narr += [arr[k]]; 
    }


    mutable next = 0;
    mutable curr = 0;
    let len = Length(u) + 1;
    let lens = len + 1;

    if ((t == 2) and (d==1)){
        X(s1[0]);
        X(t2[0]);
        AddI(LittleEndian(u),LittleEndian(r1[0..(len -2)]));
        AddI(LittleEndian(m),LittleEndian(r2[0..(len -2)]));
    }
    
    
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
    AddI(LittleEndian(r1[(curr*len)..((curr*len) + len-1)]),LittleEndian(r1[(next*len)..((next*len) + len-1)]));
    AddI(LittleEndian(r2[(curr*len)..((curr*len) + len-1)]),LittleEndian(r2[(next*len)..((next*len) + len-1)]));
    
    AddI(LittleEndian(s1[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(s1[(next*lens)..((next*lens) + lens -1)]));
    AddI(LittleEndian(s2[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(s2[(next*lens)..((next*lens) + lens -1)]));

    AddI(LittleEndian(t1[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(t1[(next*lens)..((next*lens) + lens -1)]));
    AddI(LittleEndian(t2[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(t2[(next*lens)..((next*lens) + lens -1)]));
    

    GCDCheck(r2[(next*len)..((next*len) + len-1)],C1[next]);//C1 set to 1 if either r2=0 or s2>m
    X(C1[next]);

    Controlled GCDIteration([C1[next]],(r1[(next*len)..((next*len) + len-1)],r2[(next*len)..((next*len) + len-1)],s1[(next*lens)..((next*lens) + lens -1)],s2[(next*lens)..((next*lens) + lens -1)],t1[(next*lens)..((next*lens) + lens -1)],t2[(next*lens)..((next*lens) + lens -1)],quo[(next*len)..((next*len)+len-1)],qTs2[(next*(2*len+1))..((next*(2*len+1))+(2*len+1)-1)],qTt2[(next*(2*len+1))..((next*(2*len+1))+(2*len+1)-1)],anc1[next],anc2[next],anc3[next],anc4[next]));
    if ((Ceiling(1.44*IntAsDouble(len)) <= narr[next]) and (narr[Length(narr)-1] == 0)){
        GCDExtractRes(p,u,m,s1[(next*lens)..((next*lens)+lens-1)],t1[(next*lens)..((next*lens)+lens-1)]);
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

    Controlled Adjoint GCDIteration([C1[next]],(r1[(next*len)..((next*len) + len-1)],r2[(next*len)..((next*len) + len-1)],s1[(next*lens)..((next*lens) + lens -1)],s2[(next*lens)..((next*lens) + lens -1)],t1[(next*lens)..((next*lens) + lens -1)],t2[(next*lens)..((next*lens) + lens -1)],quo[(next*len)..((next*len)+len-1)],qTs2[(next*(2*len+1))..((next*(2*len+1))+(2*len+1)-1)],qTt2[(next*(2*len+1))..((next*(2*len+1))+(2*len+1)-1)],anc1[next],anc2[next],anc3[next],anc4[next]));
    X(C1[next]);
    Adjoint GCDCheck(r2[(next*len)..((next*len) + len-1)],C1[next]);//C1 set to 1 if either r2=0 or s2>m


    Adjoint AddI(LittleEndian(r1[(curr*len)..((curr*len) + len-1)]),LittleEndian(r1[(next*len)..((next*len) + len-1)]));
    Adjoint AddI(LittleEndian(r2[(curr*len)..((curr*len) + len-1)]),LittleEndian(r2[(next*len)..((next*len) + len-1)]));
    
    Adjoint AddI(LittleEndian(s1[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(s1[(next*lens)..((next*lens) + lens -1)]));
    Adjoint AddI(LittleEndian(s2[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(s2[(next*lens)..((next*lens) + lens -1)]));

    Adjoint AddI(LittleEndian(t1[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(t1[(next*lens)..((next*lens) + lens -1)]));
    Adjoint AddI(LittleEndian(t2[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(t2[(next*lens)..((next*lens) + lens -1)]));
    

    set narr w/= next <- narr[next] - (narr[curr] + 1);
    }


    if ((t == 2) and (d==0)){
        X(s1[0]);
        X(t2[0]);
        Adjoint AddI(LittleEndian(u),LittleEndian(r1[0..(len -2)]));
        Adjoint AddI(LittleEndian(m),LittleEndian(r2[0..(len -2)]));
    }
    

    return narr;
}


operation GCDExtractRes(res:Qubit[],g:Qubit[],m:Qubit[],s1:Qubit[],t1:Qubit[]):Unit is Ctl{

    ///s*g + t*m
    let lenS = Length(s1);
    using ((sTg,tTm,Pad,a1,a2)=(Qubit[lenS*2-1],Qubit[lenS*2-1],Qubit[2],Qubit(),Qubit())){
        
        SignedMultiply(s1,g+Pad,sTg);
        
        SignedMultiply(t1,m+Pad,tTm);
        
        X(tTm[Length(tTm)-1]);//Setting tTm to minus a--b = a+b as required
        SignedSubtract(sTg[0..(Length(sTg)-2)] + [Pad[0]] + [sTg[Length(sTg)-1]],tTm,a1,a2);
        
        AddI(LittleEndian(sTg[0..(Length(res)-1)]),LittleEndian(res));
        
        Adjoint SignedSubtract(sTg[0..(Length(sTg)-2)] + [Pad[0]] + [sTg[Length(sTg)-1]],tTm,a1,a2);
        X(tTm[Length(tTm)-1]);
        Adjoint SignedMultiply(s1,g+Pad,sTg);
        Adjoint SignedMultiply(t1,m+Pad,tTm);
    }   
}





operation GCDIteration (r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],t1:Qubit[],t2:Qubit[],quo:Qubit[],qTs2:Qubit[],qTt2:Qubit[],anc1:Qubit,anc2:Qubit,anc3:Qubit,anc4:Qubit):Unit is Adj + Ctl{

   let len = Length(r1);
   using ((s2Pad,quoS) = (Qubit[len+1],Qubit())){

           //Calculating r's
            DivideI(LittleEndian(r1),LittleEndian(r2),LittleEndian(quo));
    
            for (i in 0..(len-1)){
                SWAP(r1[i],r2[i]);
            }
            //Calculating s's
            SignedMultiply(s2,quo + [quoS], qTs2);
          
            for (i in 0..(Length(s1)-1)){
                SWAP(s1[i],s2[i]);
            }
            
            SignedSubtract(s2[0..(Length(s2)-2)] + s2Pad + [s2[(Length(s2)-1)]],qTs2,anc1,anc2);


            //Calculating t's
            SignedMultiply(t2,quo + [quoS], qTt2);
          
            for (i in 0..(Length(t1)-1)){
                SWAP(t1[i],t2[i]);
            }
            
            SignedSubtract(t2[0..(Length(t2)-2)] + s2Pad + [t2[(Length(t2)-1)]],qTt2,anc3,anc4);
           
   }



}
///Sets C to 1 if r2==0///
operation GCDCheck (r2:Qubit[],C:Qubit):Unit is Adj + Ctl{
    body (...){
       
        
        ApplyToEachA(X,r2);
        Controlled X(r2,C);//if r2=0 C3=1
        ApplyToEachA(X,r2);
        
    }
    controlled (cs,...){
       
        ApplyToEachA(X,r2);
        Controlled X(r2,C);//Resetting C3
        ApplyToEachA(X,r2);

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
}