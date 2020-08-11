namespace Shor {
  open Microsoft.Quantum.Intrinsic;
  open Microsoft.Quantum.Arithmetic;
  open Microsoft.Quantum.Diagnostics;
  open Microsoft.Quantum.Measurement;
  open Microsoft.Quantum.Math;
  open Microsoft.Quantum.Arrays;
  open Microsoft.Quantum.Convert;
  open Microsoft.Quantum.Canon;

  operation FactorInteger() : Unit{
    let num = 4;
    Message("Hello Quantum World");
    using ((Ms,As,Js,Rs,Os,Gs,Ds) = (Qubit[num],Qubit[num],Qubit[num*2],Qubit[num],Qubit[num*2],Qubit[num],Qubit[num])){
        DumpMachine();
        //|M>|a>|j>
        //|0>|0>|0>|0>
        //Create M
        X(Ms[2]);
        X(Ms[3]);
        Message("Creating M...");
        //|M>|0>|0>|0>
        DumpMachine();

        Message("Creating A...");
        GenerateA(Ms,As);
        //|M>|a>|0>|0> = |M>|1+ Rmod (M-1)>|0>|0>

        Message("Creating J...");
        //|M>|a>|J>|0>
        ApplyToEachA(H,Js);
        //X(Js[2]);//////SET THIS TO UE IN TOFFOLI SIMULATOR

        Message("Creating Rs...");
        SquareAndMultiply(As,Ms,Js,Rs);
        //|M>|a>|J>|R> = |M>|1+ mod (M-1)>|J>|a^j mod M>

        Message("Performing QFT on J...");
        Adjoint QFT(BigEndian(Js));

        Message("Finding Orders...");
        CFC(Os,Ms,Js);

        Message("Finding Orders...");
        GCD(As,Ms,Os,Gs,Ds);
        


        
        ResetAll((Ms + As + Js + Rs + Os + Gs + Ds));
      }
      
    }


    //Generates a = 1 + (R mod (M-1))
    //takes |M>|0> -> |M>|a>
    //Ms must be superpostition greater than 1
    operation GenerateA(Ms:Qubit[],As: Qubit[]) : Unit{
      let num = Length(Ms);
      using ((tmp1,tmp2,tmpM) = (Qubit[num],Qubit[num],Qubit[num])){
            //Generate Random int between 1 <= Ran <= (upper bound of m - 1)
          //let Ran = RandomInt((2^4) - 2) + 1;
          let Ran = 13;
          Message($"Random Integer is: {Ran}");

          //Seting tmpM to M-1
          ApplyToEachA(X,tmpM);
          AddI(LittleEndian(Ms),LittleEndian(tmpM));

          let RanArr = IntAsBoolArray(Ran,num);
          //Encoding Ran into the quantum register tmp1
          for (i in 0..(Length(tmp1)-1)){
            if (RanArr[i] == true){
              X(tmp1[i]);
            } 
          }

          //Creating Divide results
          DivideI(LittleEndian(tmp1),LittleEndian(tmpM),LittleEndian(tmp2));

          //Setting As to |1>
          X(As[0]);
          //Adding As to tmp1 to create |1+ R mod (M-1)>
          AddI(LittleEndian(tmp1),LittleEndian(As));

          //Uncomputing the Divide
          Adjoint DivideI(LittleEndian(tmp1),LittleEndian(tmpM),LittleEndian(tmp2));
          //Decoding Ran from tmp1
          for (i in 0..(Length(tmp1)-1)){
            if (RanArr[i] == true){
              X(tmp1[i]);
              } 
            }
          //Reseting tmpM to 0
          Adjoint AddI(LittleEndian(Ms),LittleEndian(tmpM));
          ApplyToEachA(X,tmpM);
          
          
      }
    }



///////SQUARE AND MULTIPLY/////////////
/////////NEEDS REFACTORING////////////////
operation SquareAndMultiply(a:Qubit[],m:Qubit[],j:Qubit[],result:Qubit[]): Unit{

        body(...){
        let len = Length(j) - 1;
        mutable numAnc = 0;
        mutable sum = 0;
        mutable add = 1;
        repeat {
            set sum = sum + add;
            set add = add + 1;
            set numAnc = numAnc + 1;
        }until (len <= sum);
        let origNumAnc = numAnc;

        
        let lenA = Length(a);
        using ((v,c,z,az,ld) = (Qubit[lenA*numAnc],Qubit(),Qubit(),Qubit(),Qubit())){

                mutable curr = 0;
                mutable curReg = 0;
        
                //Checking for j = 0
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);
                X(az);
     
                repeat{
                for (i in 0..(numAnc-1)){


                    if ((i+curr+1)<=(Length(j)-1)){
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    Controlled X(j[(i+curr+1)...],z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    X(z);

                    //checking for last digit and zero
                    ApplyToEachA(X,j[(i+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(i+curr+2)...] + [j[0]] + [j[(i+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(i+curr+2)...]);
                    X(ld);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(i+curr+1)]],c);

                    
                    //Conducting square and multiply iteration
                    Controlled SquareAndMultiplyIteration([az],(a,(a+v)[((i + curReg)*lenA)..((((i + curReg)*lenA)+lenA)-1)],m,c,z,ld,v[((i + curReg)*lenA)..((((i + curReg)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],v[((i+curReg)*lenA)]);
                    X(az);
                    


                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(i+curr+1)]],c);

                    //resetting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(i+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(i+curr+2)...] + [j[0]] + [j[(i+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(i+curr+2)...]);
                    
                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    Controlled X(j[(i+curr+1)...],z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    }
                    if ((i+curr+1) == (Length(j)-1)){
                        AddI(LittleEndian(v[((i + curReg)*lenA)..((((i + curReg)*lenA)+lenA)-1)]),LittleEndian(result));
                    }
                }
                
                mutable q=0;
               
                for (k in 0..(numAnc-2)){
                    set q = (numAnc-2) - k;
                    if ((q+curr+1)<=(Length(j)-1)){
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    X(z);

                    //checking for last digit and zero
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(q+curr+2)...] + [j[0]] + [j[(q+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(ld);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(q+curr+1)]],c);
                    
                    
                    //Conducting square and multiply iteration
                    Controlled Adjoint SquareAndMultiplyIteration([az],(a,(a+v)[((q + curReg)*lenA)..((((q+ curReg)*lenA)+lenA)-1)],m,c,z,ld,v[((q+ curReg)*lenA)..((((q+ curReg)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],v[((q+curReg)*lenA)]);
                    X(az);

                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(q+curr+1)]],c);

                    //resetting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(q+curr+2)...] + [j[0]] + [j[(q+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    
                    }
                
                }
                
                if (curReg != (origNumAnc-1)){
                for (i in 0..(lenA-1)){
                    SWAP(v[i+ curReg*lenA],v[i + (origNumAnc-1)*lenA]);
                }}
                

                set curr = curr + numAnc;
                set curReg = curReg + 1;
                set numAnc = numAnc -1;
                }until (numAnc == 0);



                repeat{
                    set numAnc = numAnc + 1;
                    set curReg = curReg - 1;
                    set curr = curr - numAnc;

                    if (curReg != (origNumAnc-1)){
                    for (i in 0..(lenA-1)){
                        SWAP(v[i+ curReg*lenA],v[i + (origNumAnc-1)*lenA]);
                    }}

                    for (q in 0..(numAnc-2)){
                    if ((q+curr+1)<=(Length(j)-1)){
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    X(z);

                    //checking for last digit and zero
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(q+curr+2)...] + [j[0]] + [j[(q+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(ld);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(q+curr+1)]],c);
                    

                    //Conducting square and multiply iteration
                    Controlled SquareAndMultiplyIteration([az],(a,(a+v)[((q + curReg)*lenA)..((((q+ curReg)*lenA)+lenA)-1)],m,c,z,ld,v[((q+ curReg)*lenA)..((((q+ curReg)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],v[((q+curReg)*lenA)]);
                    X(az);

                    
                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(q+curr+1)]],c);

                    //resetting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(q+curr+2)...] + [j[0]] + [j[(q+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    
                    }

                }
                mutable g = 0;
                for (k in 0..(numAnc-1)){
                    set g = (numAnc -1) - k;

                    if ((g+curr+1)<=(Length(j)-1)){
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(g+curr+1)...]);
                    Controlled X(j[(g+curr+1)...],z);
                    ApplyToEachA(X,j[(g+curr+1)...]);
                    X(z);

                    //checking for last digit and zero
                    ApplyToEachA(X,j[(g+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(g+curr+2)...] + [j[0]] + [j[(g+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(g+curr+2)...]);
                    X(ld);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(g+curr+1)]],c);

                    
                    //Conducting square and multiply iteration
                    Controlled Adjoint SquareAndMultiplyIteration([az],(a,(a+v)[((g + curReg)*lenA)..((((g + curReg)*lenA)+lenA)-1)],m,c,z,ld,v[((g + curReg)*lenA)..((((g + curReg)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1

                    X(az);
                    Controlled X([az],v[((g+curReg)*lenA)]);
                    X(az);
                    


                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(g+curr+1)]],c);

                    //resetting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(g+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(g+curr+2)...] + [j[0]] + [j[(g+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(g+curr+2)...]);
                    
                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(g+curr+1)...]);
                    Controlled X(j[(g+curr+1)...],z);
                    ApplyToEachA(X,j[(g+curr+1)...]);
                    }

                    
                }

                }until(numAnc == origNumAnc);


                //Resetting control all zero qubit
                X(az);
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);

                
        }  
        
        
}

controlled (cs,...) {

        let len = Length(j) - 1;
        mutable numAnc = 0;
        mutable sum = 0;
        mutable add = 1;
        repeat {
            set sum = sum + add;
            set add = add + 1;
            set numAnc = numAnc + 1;
        }until (len <= sum);
        let origNumAnc = numAnc;

        
        let lenA = Length(a);
        using ((v,c,z,az,ld) = (Qubit[lenA*numAnc],Qubit(),Qubit(),Qubit(),Qubit())){

                mutable curr = 0;
                mutable curReg = 0;
        
                //Checking for j = 0
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);
                X(az);
     
                repeat{
                for (i in 0..(numAnc-1)){


                    if ((i+curr+1)<=(Length(j)-1)){
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    Controlled X(j[(i+curr+1)...],z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    X(z);

                    //checking for last digit and zero
                    ApplyToEachA(X,j[(i+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(i+curr+2)...] + [j[0]] + [j[(i+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(i+curr+2)...]);
                    X(ld);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(i+curr+1)]],c);

                    
                    //Conducting square and multiply iteration
                    Controlled SquareAndMultiplyIteration([az],(a,(a+v)[((i + curReg)*lenA)..((((i + curReg)*lenA)+lenA)-1)],m,c,z,ld,v[((i + curReg)*lenA)..((((i + curReg)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],v[((i+curReg)*lenA)]);
                    X(az);
                    


                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(i+curr+1)]],c);

                    //resetting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(i+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(i+curr+2)...] + [j[0]] + [j[(i+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(i+curr+2)...]);
                    
                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    Controlled X(j[(i+curr+1)...],z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    }
                    if ((i+curr+1) == (Length(j)-1)){
                        AddI(LittleEndian(v[((i + curReg)*lenA)..((((i + curReg)*lenA)+lenA)-1)]),LittleEndian(result));
                    }
                }
                
                mutable q=0;
               
                for (k in 0..(numAnc-2)){
                    set q = (numAnc-2) - k;
                    if ((q+curr+1)<=(Length(j)-1)){
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    X(z);

                    //checking for last digit and zero
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(q+curr+2)...] + [j[0]] + [j[(q+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(ld);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(q+curr+1)]],c);
                    
                    
                    //Conducting square and multiply iteration
                    Controlled Adjoint SquareAndMultiplyIteration([az],(a,(a+v)[((q + curReg)*lenA)..((((q+ curReg)*lenA)+lenA)-1)],m,c,z,ld,v[((q+ curReg)*lenA)..((((q+ curReg)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],v[((q+curReg)*lenA)]);
                    X(az);

                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(q+curr+1)]],c);

                    //resetting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(q+curr+2)...] + [j[0]] + [j[(q+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    
                    }
                
                }
                
                if (curReg != (origNumAnc-1)){
                for (i in 0..(lenA-1)){
                    SWAP(v[i+ curReg*lenA],v[i + (origNumAnc-1)*lenA]);
                }}
                

                set curr = curr + numAnc;
                set curReg = curReg + 1;
                set numAnc = numAnc -1;
                }until (numAnc == 0);



                repeat{
                    set numAnc = numAnc + 1;
                    set curReg = curReg - 1;
                    set curr = curr - numAnc;

                    if (curReg != (origNumAnc-1)){
                    for (i in 0..(lenA-1)){
                        SWAP(v[i+ curReg*lenA],v[i + (origNumAnc-1)*lenA]);
                    }}

                    for (q in 0..(numAnc-2)){
                    if ((q+curr+1)<=(Length(j)-1)){
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    X(z);

                    //checking for last digit and zero
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(q+curr+2)...] + [j[0]] + [j[(q+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(ld);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(q+curr+1)]],c);
                    

                    //Conducting square and multiply iteration
                    Controlled SquareAndMultiplyIteration([az],(a,(a+v)[((q + curReg)*lenA)..((((q+ curReg)*lenA)+lenA)-1)],m,c,z,ld,v[((q+ curReg)*lenA)..((((q+ curReg)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],v[((q+curReg)*lenA)]);
                    X(az);

                    
                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(q+curr+1)]],c);

                    //resetting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(q+curr+2)...] + [j[0]] + [j[(q+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(q+curr+2)...]);
                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    
                    }

                }
                mutable g = 0;
                for (k in 0..(numAnc-1)){
                    set g = (numAnc -1) - k;

                    if ((g+curr+1)<=(Length(j)-1)){
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(g+curr+1)...]);
                    Controlled X(j[(g+curr+1)...],z);
                    ApplyToEachA(X,j[(g+curr+1)...]);
                    X(z);

                    //checking for last digit and zero
                    ApplyToEachA(X,j[(g+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(g+curr+2)...] + [j[0]] + [j[(g+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(g+curr+2)...]);
                    X(ld);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(g+curr+1)]],c);

                    
                    //Conducting square and multiply iteration
                    Controlled Adjoint SquareAndMultiplyIteration([az],(a,(a+v)[((g + curReg)*lenA)..((((g + curReg)*lenA)+lenA)-1)],m,c,z,ld,v[((g + curReg)*lenA)..((((g + curReg)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1

                    X(az);
                    Controlled X([az],v[((g+curReg)*lenA)]);
                    X(az);
                    


                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(g+curr+1)]],c);

                    //resetting for last digit and zero
                    X(ld);
                    ApplyToEachA(X,j[(g+curr+2)...]);
                    X(j[0]);
                    Controlled X(j[(g+curr+2)...] + [j[0]] + [j[(g+curr+1)]],ld);
                    X(j[0]);
                    ApplyToEachA(X,j[(g+curr+2)...]);
                    
                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(g+curr+1)...]);
                    Controlled X(j[(g+curr+1)...],z);
                    ApplyToEachA(X,j[(g+curr+1)...]);
                    }

                    
                }

                }until(numAnc == origNumAnc);


                //Resetting control all zero qubit
                X(az);
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);

                
        }  
        
  
}
        
        
    
}
operation SquareAndMultiplyIteration(a:Qubit[],v:Qubit[],m:Qubit[],c:Qubit,z:Qubit,ld:Qubit,t:Qubit[]) : Unit is Adj + Ctl{
        X(z);
        Controlled AddI([z],(LittleEndian(v),LittleEndian(t)));
        X(z);
        using (anc = Qubit[Length(v)]){
        Controlled SquareModM([z],(v,m,anc));
        Controlled MultiplyModM([z,c,ld],(a,anc,m,t));
        X(c);
        Controlled AddI([z,c],(LittleEndian(anc),LittleEndian(t)));
        X(c);
        X(ld);
        Controlled AddI([ld],(LittleEndian(anc),LittleEndian(t)));
        X(ld);

        Controlled Adjoint SquareModM([z],(v,m,anc));
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







//////////Continued Fraction Convergent//////////
///////////NEEDS REFACTORING//////////////

operation CFC(p:Qubit[],m:Qubit[],u:Qubit[]):Unit{
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
    }
        
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



////Greatest Common Divisor/////
/////NEEDS REFACTING///////



operation GCD(a:Qubit[],m:Qubit[],o:Qubit[],g:Qubit[],d:Qubit[]):Unit{
    
    using (c=Qubit()){

        CNOT(o[0],c);
        X(c);//Sets c to 1 if o is even
        
        Controlled SquareAndMultiply([c],(a,m,o[1..(Length(o)-1)],g));

        //IncrementByInteger(-1,LittleEndian(g));////MUST UNCOMMENT FOR ACTUAL TEST, WONT WORK IN TOFFOLI

        Controlled GCDMain([c],(d,m,g));
        



    Reset(c);
    }
}



operation GCDMain(d:Qubit[],m:Qubit[],g:Qubit[]):Unit is Ctl{

        mutable len = Length(g);
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

    using ((r1,r2,s1,s2,t1,t2,quo,qTs2,qTt2,C1,anc1,anc2,anc3,anc4) = (Qubit[(len+1)*numAnc],Qubit[(len+1)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len + 2)*numAnc],Qubit[(len+1)*numAnc],Qubit[(2*(len+1) + 1)*numAnc],Qubit[(2*(len+1) + 1)*numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc],Qubit[numAnc])){
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
                    X(s1[0]);
                    X(t2[0]);
                    AddI(LittleEndian(g),LittleEndian(r1[0..(len -2)]));
                    AddI(LittleEndian(m),LittleEndian(r2[0..(len -2)]));
                }
                
                
                if (j != 0){
                AddI(LittleEndian(r1[((j*len) - len)..((j*len)-1)]),LittleEndian(r1[(j*len)..((j*len)+len-1)]));
                AddI(LittleEndian(r2[((j*len) - len)..((j*len)-1)]),LittleEndian(r2[(j*len)..((j*len)+len-1)]));
                
                AddI(LittleEndian(s1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s1[(j*lens)..((j*lens)+lens-1)]));
                AddI(LittleEndian(s2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s2[(j*lens)..((j*lens)+lens-1)]));

                AddI(LittleEndian(t1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(t1[(j*lens)..((j*lens)+lens-1)]));
                AddI(LittleEndian(t2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(t2[(j*lens)..((j*lens)+lens-1)]));
                }
                

                GCDCheck(r2[(j*len)..((j*len)+len-1)],C1[j]);//C1 set to 1 if either r2=0 or s2>m
                X(C1[j]);

                Controlled GCDIteration([C1[j]],(r1[(j*len)..((j*len)+len-1)],r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)],t1[(j*lens)..((j*lens)+lens-1)],t2[(j*lens)..((j*lens)+lens-1)],quo[(j*len)..((j*len)+len-1)],qTs2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],qTt2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],anc1[j],anc2[j],anc3[j],anc4[j]));
                
                if ((i + curr + 1) == num_its){
                    ///GCDExtractRes(res:Qubit[],g:Qubit[],m:Qubit[],s1:Qubit[],t1:Qubit[])

                    GCDExtractRes(d,g,m,s1[(j*lens)..((j*lens)+lens-1)],t1[(j*lens)..((j*lens)+lens-1)]);
                }
            }
            ////DESCENDING////////
            mutable q=0;
            for (k in 0..(numAnc-2)){
                set q = (numAnc-2) - k;
                set j = q+curReg;
                
                Controlled Adjoint GCDIteration([C1[j]],(r1[(j*len)..((j*len)+len-1)],r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)],t1[(j*lens)..((j*lens)+lens-1)],t2[(j*lens)..((j*lens)+lens-1)],quo[(j*len)..((j*len)+len-1)],qTs2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],qTt2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],anc1[j],anc2[j],anc3[j],anc4[j]));
                
                X(C1[j]);
                Adjoint GCDCheck(r2[(j*len)..((j*len)+len-1)],C1[j]);//C1 set to 1 if either r2=0 or s2>m
                
                if (j != 0){
                Adjoint AddI(LittleEndian(r1[((j*len) - len)..((j*len)-1)]),LittleEndian(r1[(j*len)..((j*len)+len-1)]));
                Adjoint AddI(LittleEndian(r2[((j*len) - len)..((j*len)-1)]),LittleEndian(r2[(j*len)..((j*len)+len-1)]));
                
                Adjoint AddI(LittleEndian(s1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s1[(j*lens)..((j*lens)+lens-1)]));
                Adjoint AddI(LittleEndian(s2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s2[(j*lens)..((j*lens)+lens-1)]));

                Adjoint AddI(LittleEndian(t1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(t1[(j*lens)..((j*lens)+lens-1)]));
                Adjoint AddI(LittleEndian(t2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(t2[(j*lens)..((j*lens)+lens-1)]));
                }
                if (j==0){
                    X(s1[0]);
                    X(t2[0]);
                    Adjoint AddI(LittleEndian(g),LittleEndian(r1[0..(len -2)]));
                    Adjoint AddI(LittleEndian(m),LittleEndian(r2[0..(len -2)]));
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
                SWAP(t1[curReg*lens + i],t1[i + (origNumAnc-1)*lens]);
                SWAP(t2[curReg*lens + i],t2[i + (origNumAnc-1)*lens]);
            }
            
            for (i in 0..(2*len)){
                SWAP(qTs2[curReg*(2*len + 1) + i],qTs2[i + (origNumAnc-1)*(2*len + 1)]);
                SWAP(qTt2[curReg*(2*len + 1) + i],qTt2[i + (origNumAnc-1)*(2*len + 1)]);
            }
            
            SWAP(C1[curReg],C1[origNumAnc-1]);
            SWAP(anc1[curReg],anc1[origNumAnc-1]);
            SWAP(anc2[curReg],anc2[origNumAnc-1]);
            SWAP(anc3[curReg],anc2[origNumAnc-1]);
            SWAP(anc4[curReg],anc2[origNumAnc-1]);
            
            }

            
            set curr = curr + numAnc;
            set numAnc = numAnc -1;
            set curReg = curReg + 1;
            
        }until(numAnc==0);


//HERE//
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
                SWAP(t1[curReg*lens + i],t1[i + (origNumAnc-1)*lens]);
                SWAP(t2[curReg*lens + i],t2[i + (origNumAnc-1)*lens]);
            }
            for (i in 0..(2*len)){
                SWAP(qTs2[curReg*(2*len + 1) + i],qTs2[i + (origNumAnc-1)*(2*len + 1)]);
                SWAP(qTt2[curReg*(2*len + 1) + i],qTt2[i + (origNumAnc-1)*(2*len + 1)]);
            }
            SWAP(C1[curReg],C1[origNumAnc-1]);
            SWAP(anc1[curReg],anc1[origNumAnc-1]);
            SWAP(anc2[curReg],anc2[origNumAnc-1]);
            SWAP(anc3[curReg],anc2[origNumAnc-1]);
            SWAP(anc4[curReg],anc2[origNumAnc-1]);
            }
            ////Adjoint DESCENDING////////
            for (q in 0..(numAnc-2)){
                set j = q+curReg;

                if (j==0){
                    //ApplyToEachA(X,r2[0..(len-1)]);
                    X(s1[0]);
                    X(t2[0]);
                    AddI(LittleEndian(g),LittleEndian(r1[0..(len -2)]));
                    AddI(LittleEndian(m),LittleEndian(r2[0..(len -2)]));
                }

                if (j != 0){
                AddI(LittleEndian(r1[((j*len) - len)..((j*len)-1)]),LittleEndian(r1[(j*len)..((j*len)+len-1)]));
                AddI(LittleEndian(r2[((j*len) - len)..((j*len)-1)]),LittleEndian(r2[(j*len)..((j*len)+len-1)]));
                
                AddI(LittleEndian(s1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s1[(j*lens)..((j*lens)+lens-1)]));
                AddI(LittleEndian(s2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s2[(j*lens)..((j*lens)+lens-1)]));

                AddI(LittleEndian(t1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(t1[(j*lens)..((j*lens)+lens-1)]));
                AddI(LittleEndian(t2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(t2[(j*lens)..((j*lens)+lens-1)]));
                }

                GCDCheck(r2[(j*len)..((j*len)+len-1)],C1[j]);//C1 set to 1 if either r2=0 or s2>m
                X(C1[j]);
                Controlled GCDIteration([C1[j]],(r1[(j*len)..((j*len)+len-1)],r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)],t1[(j*lens)..((j*lens)+lens-1)],t2[(j*lens)..((j*lens)+lens-1)],quo[(j*len)..((j*len)+len-1)],qTs2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],qTt2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],anc1[j],anc2[j],anc3[j],anc4[j]));

            }
            ////Adjoint ASCENDING////////
            for (k in 0..(numAnc-1)){
                let i = (numAnc-1) - k;
                set j = i+curReg;

                Controlled Adjoint GCDIteration([C1[j]],(r1[(j*len)..((j*len)+len-1)],r2[(j*len)..((j*len)+len-1)],s1[(j*lens)..((j*lens)+lens-1)],s2[(j*lens)..((j*lens)+lens-1)],t1[(j*lens)..((j*lens)+lens-1)],t2[(j*lens)..((j*lens)+lens-1)],quo[(j*len)..((j*len)+len-1)],qTs2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],qTt2[(j*(2*len+1))..((j*(2*len+1))+(2*len+1)-1)],anc1[j],anc2[j],anc3[j],anc4[j]));
                X(C1[j]);
                Adjoint GCDCheck(r2[(j*len)..((j*len)+len-1)],C1[j]);//C1 set to 1 if either r2=0 or s2>m
                
                
                if (j != 0){
                Adjoint AddI(LittleEndian(r1[((j*len) - len)..((j*len)-1)]),LittleEndian(r1[(j*len)..((j*len)+len-1)]));
                Adjoint AddI(LittleEndian(r2[((j*len) - len)..((j*len)-1)]),LittleEndian(r2[(j*len)..((j*len)+len-1)]));
                
                Adjoint AddI(LittleEndian(s1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s1[(j*lens)..((j*lens)+lens-1)]));
                Adjoint AddI(LittleEndian(s2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(s2[(j*lens)..((j*lens)+lens-1)]));

                Adjoint AddI(LittleEndian(t1[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(t1[(j*lens)..((j*lens)+lens-1)]));
                Adjoint AddI(LittleEndian(t2[((j*lens) - lens)..((j*lens)-1)]),LittleEndian(t2[(j*lens)..((j*lens)+lens-1)]));
                }

                if (j==0){
                        X(s1[0]);
                    X(t2[0]);
                    Adjoint AddI(LittleEndian(g),LittleEndian(r1[0..(len -2)]));
                    Adjoint AddI(LittleEndian(m),LittleEndian(r2[0..(len -2)]));
                    }
            }
            
            
        }until (numAnc==origNumAnc);
    }
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


}
