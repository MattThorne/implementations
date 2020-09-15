////////////////////////////////////////////////////////////////////////////////////////////////////////
////This code implements a fully reversible Continued Fractions Convergent algorithm                  //
////This is required for Shor's algorithm in Superposition                                            //  
////It is based on the classical algorithm and uses Bennett's generic conversion to make it reversible//
////////////////////////////////////////////////////////////////////////////////////////////////////////


namespace ShorInSuperposition
{
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



operation CFMain(p:Qubit[],m:Qubit[],u:Qubit[]):Unit{
    let len = Length(u);
    //Calculating the number of steps that must be stored at once using Bennett's
    mutable numAnc = Ceiling(Lg(1.44*IntAsDouble(len + 1))) + 1;

    // Initialsing classical array.
    mutable arr = new Int[numAnc + 2]; // last item in array used to contol if result has been found
    //Setting first element in classicla array as 1
    set arr w/= 0 <- 1;
    set numAnc = numAnc + 1;  

    //Initialising the quantum registers.
    //r1 and r2 are the current split and invert values
    //s1 and s2 are the current and previous approximation of the denominator
    //quo stores the quotient of r1/r2
    //qTs2 stores the quotient multiplyied by s2
    //C1 is used to control if the best approximation has been found
    //anc1 and anc2 are used to store the garbage from the signed subtraction operation 
    using ((r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2) = (Qubit[(len+1)*numAnc],Qubit[(len+1)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len+1)*numAnc],Qubit[(2*(len+1) + 1)*numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc])){
        set numAnc = numAnc - 1; 

        //Calling the pebble and unpebble functions to carry out the operation
        set arr w/= (0..(Length(arr)-1)) <- CFPebble(1,numAnc,arr,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
        set arr w/= (0..(Length(arr)-1)) <- CFUnpebble(1,numAnc,arr,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);

    }
}


operation CFPebble(s: Int, n:Int, arr:Int[],p:Qubit[],m:Qubit[],u:Qubit[],r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],quo:Qubit[],qTs2:Qubit[],C1:Qubit[],anc1:Qubit[],anc2:Qubit[]): Int[]{
    //Since mutable arrays cannot be passed in Q# the classical arrayed had to be copied every time it was passed to a new function
    mutable narr = new Int[0];
    for (i in 0..(Length(arr) -1)){
        set narr += [arr[i]]; 
    }
    if (n!=0){
        let t = s + PowI(2,(n-1));
        set narr w/= (0..(Length(narr)-1)) <- CFPebble(s,(n-1),narr,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
        //put a free pebble on node t
        set narr w/= (0..(Length(narr)-1)) <- CFStep(t,narr,1,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
        set narr w/= (0..(Length(narr)-1)) <- CFUnpebble(s,(n-1),narr,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
        set narr w/= (0..(Length(narr)-1)) <- CFPebble(t,(n-1),narr,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
        
    }
    return narr;
}

operation CFUnpebble(s: Int, n:Int, arr:Int[],p:Qubit[],m:Qubit[],u:Qubit[],r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],quo:Qubit[],qTs2:Qubit[],C1:Qubit[],anc1:Qubit[],anc2:Qubit[]):Int[]{
    mutable narr = new Int[0];
    for (i in 0..(Length(arr) -1)){
        set narr += [arr[i]]; 
    }
    if (n!=0){
        let t = s + PowI(2,(n-1));
        set narr w/= (0..(Length(narr)-1)) <-CFUnpebble(t,(n-1),narr,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
        set narr w/= (0..(Length(narr)-1)) <-CFPebble(s,(n-1),narr,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
        //take a  pebble from node t
        set narr w/= (0..(Length(narr)-1)) <- CFStep(t,narr,0,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
        set narr w/= (0..(Length(narr)-1)) <-CFUnpebble(s,(n-1),narr,p,m,u,r1,r2,s1,s2,quo,qTs2,C1,anc1,anc2);
    }
    return narr;
}


//Operator to carry out a single step of the Continued fractions calculation
operation CFStep(t:Int,arr:Int[] ,d:Int,p:Qubit[],m:Qubit[],u:Qubit[],r1:Qubit[],r2:Qubit[],s1:Qubit[],s2:Qubit[],quo:Qubit[],qTs2:Qubit[],C1:Qubit[],anc1:Qubit[],anc2:Qubit[]):Int[]{
    mutable narr = new Int[0];
    for (k in 0..(Length(arr) -1)){
        set narr += [arr[k]]; 
    }


    mutable next = 0;
    mutable curr = 0;
    let len = Length(u) + 1;
    let lens = len + 1;

    //If the first step must copy the correct values into the working registers.
    if ((t == 2) and (d==1)){
        X(r2[len -1]);
        X(s1[0]);
        AddI(LittleEndian(u),LittleEndian(r1[0..(len -2)]));
        
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

    if (d==1){//If Pebbling 

        //Finds first empty item in classical array
        set found = false;
        set i = 0; 
        repeat{
        if (arr[i] == 0){
            set next = i;
            set found = true;
        }
        set i = i + 1;
        }until (found == true);
    //Setting the next value of th classical array.
    set narr w/= next <- narr[next] + (narr[curr] + 1);


    //Conduct Pebble calculation
    AddI(LittleEndian(r1[(curr*len)..((curr*len) + len-1)]),LittleEndian(r1[(next*len)..((next*len) + len-1)]));
    AddI(LittleEndian(r2[(curr*len)..((curr*len) + len-1)]),LittleEndian(r2[(next*len)..((next*len) + len-1)]));
    
    AddI(LittleEndian(s1[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(s1[(next*lens)..((next*lens) + lens -1)]));
    AddI(LittleEndian(s2[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(s2[(next*lens)..((next*lens) + lens -1)]));
    

    CFCheck(r2[(next*len)..((next*len) + len-1)],s2[(next*lens)..((next*lens) + lens -1)],m,C1[next]);//C1 set to 1 if either r2=0 or s2>m
    X(C1[next]);
    Controlled CFIteration([C1[next]],(r1[(next*len)..((next*len) + len-1)],r2[(next*len)..((next*len) + len-1)],s1[(next*lens)..((next*lens) + lens -1)],s2[(next*lens)..((next*lens) + lens -1)],quo[(next*len)..((next*len)+len-1)],qTs2[(next*(2*len+1))..((next*(2*len+1))+(2*len+1)-1)],anc1[next],anc2[next]));
   
    if ((Ceiling(1.44*IntAsDouble(len)) <= narr[next]) and (narr[Length(narr)-1] == 0)){
        CFExtractRes(p,m,r2[(next*len)..((next*len)+len-1)],s1[(next*lens)..((next*lens)+lens-1)],s2[(next*lens)..((next*lens)+lens-1)]);
        set narr w/= (Length(narr)-1) <- 1;
    }
    
    }


    if (d==0){//If removing a pebble
        
        set found = false;
        set i = 0;
        repeat{
        if (arr[i] == t){
            set next = i;
            set found = true;
        }
        set i = i + 1;
    }until (found == true);

    Controlled Adjoint CFIteration([C1[next]],(r1[(next*len)..((next*len) + len-1)],r2[(next*len)..((next*len) + len-1)],s1[(next*lens)..((next*lens) + lens -1)],s2[(next*lens)..((next*lens) + lens -1)],quo[(next*len)..((next*len)+len-1)],qTs2[(next*(2*len+1))..((next*(2*len+1))+(2*len+1)-1)],anc1[next],anc2[next]));
    X(C1[next]);
    Adjoint CFCheck(r2[(next*len)..((next*len) + len-1)],s2[(next*lens)..((next*lens) + lens -1)],m,C1[next]);//C1 set to 1 if either r2=0 or s2>m


    Adjoint AddI(LittleEndian(r1[(curr*len)..((curr*len) + len-1)]),LittleEndian(r1[(next*len)..((next*len) + len-1)]));
    Adjoint AddI(LittleEndian(r2[(curr*len)..((curr*len) + len-1)]),LittleEndian(r2[(next*len)..((next*len) + len-1)]));
    
    Adjoint AddI(LittleEndian(s1[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(s1[(next*lens)..((next*lens) + lens -1)]));
    Adjoint AddI(LittleEndian(s2[(curr*lens)..((curr*lens) + lens -1)]),LittleEndian(s2[(next*lens)..((next*lens) + lens -1)]));
    

    set narr w/= next <- narr[next] - (narr[curr] + 1);
    }


    if ((t == 2) and (d==0)){
        X(r2[len -1]);
        X(s1[0]);
        Adjoint AddI(LittleEndian(u),LittleEndian(r1[0..(len -2)]));
    }
    

    return narr;
}




//This operator extracts the final result of the continued fractions operations
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




//Carries out the logic of each step.
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


//Checks if a the result has been found.
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

}