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
    Message("Hello World");
    using ((Ms,As,Js,Rs) = (Qubit[num],Qubit[num],Qubit[num*2],Qubit[num])){
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
        DumpMachine();

        Message("Creating J...");
        //|M>|a>|J>|0>
        ApplyToEachA(H,Js);
        //X(Js[2]);//////SET THIS TO UE IN TOFFOLI SIMULATOR
        DumpMachine();

        Message("Creating Rs...");
        SquareAndMultiply(As,Ms,Js,Rs);
        //|M>|a>|J>|R> = |M>|1+ mod (M-1)>|J>|a^j mod M>
        DumpMachine();
        




        ResetAll((Ms + As + Js + Rs));
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


}
