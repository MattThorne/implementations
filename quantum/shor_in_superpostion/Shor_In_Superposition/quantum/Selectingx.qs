/////////////////////////////////////////////////////////////////////////
//This program implements the selection of x step in Shor's algorithm  //
//in superposition                                                     //
//Performing the transformation |N>|0> -> |a>|x>                       //
//Where x = 1 + R mod N and R is a random number less than N           //
/////////////////////////////////////////////////////////////////////////


namespace ShorInSuperposition {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;


    //Generates x = 1 + (R mod (M-1))
    //takes |M>|0> -> |M>|x>
    //Ms must be superpostition greater than 1
    operation GenerateX(Ms:Qubit[],As: Qubit[],Ran: Int) : Unit is Adj{
      let num = Length(Ms);
      using ((tmp1,tmp2,tmpM) = (Qubit[num],Qubit[num],Qubit[num])){
          //Generate Random int between 1 <= Ran <= (upper bound of m - 1)
          //let Ran = RandomInt((2^4) - 2) + 1;
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

}