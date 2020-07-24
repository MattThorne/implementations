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
    using ((Ms,As) = (Qubit[num],Qubit[num])){

        //|0>|0>
        //Create M
        X(Ms[2]);
        H(Ms[1]);
        H(Ms[0]);
        //|M>|0>
        DumpMachine();
        GenerateA(Ms,As);
        //|M>|a>
        DumpMachine();



        ResetAll((Ms + As));
      }
      
    }

    operation ModularSquaring(Ms:Qubit[],As:Qubit[],As_modM:Qubit[],pow:Int): Unit{
      let num = Length(Ms);
      if (pow == 1) {AddI(LittleEndian(As),LittleEndian(As_modM));}
      elif (pow == 2){
        using (pad = Qubit[num]){
        SquareI(LittleEndian(As),LittleEndian(As_modM + pad));
        
        }
      }
    }

    //Generates a = 1 + (R mod (M-1))
    //takes |M>|0> -> |M>|a>
    //Ms must be superpostition greater than 1
    operation GenerateA(Ms:Qubit[],As: Qubit[]) : Unit{
      let num = Length(Ms);
      using ((tmp1,tmp2) = (Qubit[num],Qubit[num])){
            //Generate Random int between 1 <= Ran <= (upper bound of m - 1)
          //let Ran = RandomInt((2^4) - 2) + 1;
          let Ran = 13;
          Message($"Random Integer is: {Ran}");
          IncrementByInteger(-1,LittleEndian(Ms));
          let RanArr = IntAsBoolArray(Ran,num);
          //Encoding Ran into the quantum register tmp1
          for (i in 0..(Length(tmp1)-1)){
            if (RanArr[i] == true){
              X(tmp1[i]);
            } 
          }
          //Creating Divide results
          DivideI(LittleEndian(tmp1),LittleEndian(Ms),LittleEndian(tmp2));

          //Setting As to |1>
          X(As[0]);
          //Adding As to tmp1 to create |1+ R mod (M-1)>
          AddI(LittleEndian(tmp1),LittleEndian(As));

          //Uncomputing the Divide
          Adjoint DivideI(LittleEndian(tmp1),LittleEndian(Ms),LittleEndian(tmp2));
          //Decoding Ran from tmp1
          for (i in 0..(Length(tmp1)-1)){
            if (RanArr[i] == true){
              X(tmp1[i]);
              } 
            }
          IncrementByInteger(1,LittleEndian(Ms));
      }
    }


/////UNFINISHED SQUARE AND MULTIPLY SECTION/////////////
    operation SquareAndMultiply(): Unit{

    using ((a,m,j)=(Qubit[2],Qubit[2],Qubit[4])){
        X(a[1]);
        //X(a[0]);
        X(m[1]);
        X(m[0]);
        X(j[0]);
        X(j[1]);



        let len = Length(j) - 1;
        mutable numAnc = 0;
        mutable sum = 0;
        mutable add = 1;
        repeat {
            set sum = sum + add;
            set add = add + 1;
            set numAnc = numAnc + 1;
        }until (len <= sum);

        Message($"{numAnc}");
        mutable curr = 0;
        let lenA = Length(a);
        using ((v,c,z,az,sc) = (Qubit[lenA*numAnc],Qubit(),Qubit(),Qubit(),Qubit())){
                
                //Checking for j = 0
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);
                X(az);

                //Checking for j = 2
                //setting squareing control qubit
                X(j[1]);
                ApplyToEachA(X,j);
                Controlled X(j,sc);
                ApplyToEachA(X,j);
                X(j[1]);
                X(sc);


                DumpMachine();
                for (i in 0..(numAnc-1)){
                    Message($"{i}");
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    Controlled X(j[(i+curr+1)...],z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    X(z);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(i+curr+1)]],c);
                    
                    
                    //Conducting square and multiply iteration
                    Controlled SquareAndMultiplyIteration([az],(a,(a+v)[((i+curr)*lenA)..((((i+curr)*lenA)+lenA)-1)],m,c,z,sc,v[((i+curr)*lenA)..((((i+curr)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],v[((i+curr)*lenA)]);
                    X(az);


                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(i+curr+1)]],c);

                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                    Controlled X(j[(i+curr+1)...],z);
                    ApplyToEachA(X,j[(i+curr+1)...]);
                }
                DumpMachine();
                mutable q=0;
                for (k in 0..(numAnc-2)){
                    set q = (numAnc-2) - k;
                    Message($"{q}");
                    //Checking for remainder of j being all zero
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    X(z);

                    //setting control qubit for is j[i] = 1
                    Controlled X([j[(q+curr+1)]],c);
                    

                    //Conducting square and multiply iteration
                    Controlled Adjoint SquareAndMultiplyIteration([az],(a,(a+v)[((q+curr)*lenA)..((((q+curr)*lenA)+lenA)-1)],m,c,z,sc,v[((q+curr)*lenA)..((((q+curr)*lenA)+lenA)-1)]));
                    //If all j is all zero setting target to 1 as a^0=1
                    X(az);
                    Controlled X([az],v[((q+curr)*lenA)]);
                    X(az);


                    //Resetting control qubit for is j[i]=1
                    Controlled X([j[(q+curr+1)]],c);

                    

                    //Resetting remainder of j zero qubit
                    X(z);
                    ApplyToEachA(X,j[(q+curr+1)...]);
                    Controlled X(j[(q+curr+1)...],z);
                    ApplyToEachA(X,j[(q+curr+1)...]);

                    
                }

                DumpMachine();

                //resetting squareing control qubit
                    X(sc);
                    X(j[1]);
                    ApplyToEachA(X,j);
                    Controlled X(j,sc);
                    ApplyToEachA(X,j);
                    X(j[1]);

                //Resetting control all zero qubit
                X(az);
                ApplyToEachA(X,j);
                Controlled X(j,az);
                ApplyToEachA(X,j);

                

                ResetAll(v);
                Reset(c);
                Reset(z);
                Reset(az);
                
        }
        // SquareAndMultiplyIteration(a,v,m,c,z,t);
        // DumpMachine("/Users/Matt/Documents/Masters/Dissertation/DisQsharp/Qs_Output.txt");   

        ResetAll(a + m + j);
    }
}
operation SquareAndMultiplyIteration(a:Qubit[],v:Qubit[],m:Qubit[],c:Qubit,z:Qubit,sc:Qubit,t:Qubit[]) : Unit is Adj + Ctl{
        X(z);
        Controlled AddI([z],(LittleEndian(v),LittleEndian(t)));
        X(z);

        using (anc = Qubit[2]){
        Controlled SquareModM([z],(v,m,anc));
        Controlled MultiplyModM([z,c,sc],(a,anc,m,t));
        X(c);
        Controlled AddI([z,c],(LittleEndian(anc),LittleEndian(t)));
        X(c);
        X(sc);
        Controlled AddI([sc],(LittleEndian(anc),LittleEndian(t)));
        X(sc);

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
