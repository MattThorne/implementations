///////////////////////////////////////////////////////////////////////////
//This program implements a fully reversible Square and multiply modular //
//Exponentiation algorithm                                               //
//Performing the transformation |a>|b>|c>|0> -> |a>|b>|a^b mod c>        //
///////////////////////////////////////////////////////////////////////////

namespace ShorInSuperposition {


    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;





operation SquareAndMultiply(a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[],adj:Bool): Unit{
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

                set arr w/= (0..(Length(arr)-1)) <- SMPebble(1,numAnc,arr,a,m,j,result,v,c,z,az,ld,adj);
                set arr w/= (0..(Length(arr)-1)) <- SMUnpebble(1,numAnc,arr,a,m,j,result,v,c,z,az,ld,adj);

                //Resetting control all zero qubit
                X(az);
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);
    
    }
    
   


}



operation SMPebble(s: Int, n:Int, arr:Int[],a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[],v:Qubit[],c:Qubit,z:Qubit,az:Qubit,ld:Qubit,adj:Bool): Int[]{
    mutable narr = new Int[0];
    for (i in 0..(Length(arr) -1)){
        set narr += [arr[i]]; 
    }
    if (n!=0){
        let t = s + PowI(2,(n-1));
        set narr w/= (0..(Length(narr)-1)) <- SMPebble(s,(n-1),narr,a,m,j,result,v,c,z,az,ld,adj);
        //put a free pebble on node t
        set narr w/= (0..(Length(narr)-1)) <- SquareAndMultiplyStep(t,narr,1,a,m,j,result,v,c,z,az,ld,adj);
        // Message($"{narr}");
        // DumpRegister((),v);
        set narr w/= (0..(Length(narr)-1)) <- SMUnpebble(s,(n-1),narr,a,m,j,result,v,c,z,az,ld,adj);
        set narr w/= (0..(Length(narr)-1)) <- SMPebble(t,(n-1),narr,a,m,j,result,v,c,z,az,ld,adj);
        
    }
    return narr;
}

operation SMUnpebble(s: Int, n:Int, arr:Int[],a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[],v:Qubit[],c:Qubit,z:Qubit,az:Qubit,ld:Qubit,adj:Bool):Int[]{
    mutable narr = new Int[0];
    for (i in 0..(Length(arr) -1)){
        set narr += [arr[i]]; 
    }
    if (n!=0){
        let t = s + PowI(2,(n-1));
        set narr w/= (0..(Length(narr)-1)) <- SMUnpebble(t,(n-1),narr,a,m,j,result,v,c,z,az,ld,adj);
        set narr w/= (0..(Length(narr)-1)) <- SMPebble(s,(n-1),narr,a,m,j,result,v,c,z,az,ld,adj);
        //take a  pebble from node t
        set narr w/= (0..(Length(narr)-1)) <- SquareAndMultiplyStep(t,narr,0,a,m,j,result,v,c,z,az,ld,adj);
        // Message($"{narr}");
        // DumpRegister((),v);
        set narr w/= (0..(Length(narr)-1)) <- SMUnpebble(s,(n-1),narr,a,m,j,result,v,c,z,az,ld,adj);
    }
    return narr;
}

operation SquareAndMultiplyStep(t:Int,arr:Int[] ,d:Int,a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[],v:Qubit[],c:Qubit,z:Qubit,az:Qubit,ld:Qubit,adj:Bool):Int[]{
    


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
                        if (adj == false){AddI(LittleEndian((a+v)[(next*lenA)..(((next*lenA)+lenA)-1)]),LittleEndian(result));}
                        if (adj == true){Adjoint AddI(LittleEndian((a+v)[(next*lenA)..(((next*lenA)+lenA)-1)]),LittleEndian(result));}
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


}