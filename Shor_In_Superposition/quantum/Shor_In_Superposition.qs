////////////////////////////////////////////////////////////////
//This code outlines the process of conducting Shor's         //
//algorithm in superposition. Unfortunatly it requires more   //
//than 30 qubits even with the smallest input, it therefore   //
//cannot be tested using the full state simulator. It is also //
//outside the scope of the Toffoli simulator becuase of the   // 
//use of the QFT. So for now it cannot be run.                //            
////////////////////////////////////////////////////////////////  


namespace ShorInSuperposition {
  open Microsoft.Quantum.Intrinsic;
  open Microsoft.Quantum.Arithmetic;
  open Microsoft.Quantum.Diagnostics;
  open Microsoft.Quantum.Measurement;
  open Microsoft.Quantum.Math;
  open Microsoft.Quantum.Arrays;
  open Microsoft.Quantum.Convert;
  open Microsoft.Quantum.Canon;

  operation InvokeSIS():Unit{
      using ((N,N1) = (Qubit[3],Qubit[3])){
          //Setting the superposition N
          H(N[0]);

          ShorInSuperposition(N,N1);

          ResetAll(N+N1);
      }

  }

  operation ShorInSuperposition(N:Qubit[],N1:Qubit[]): Unit{
      let bitsize = Length(N) -1;
    using ((x,J,SMRes,Order,xR2,AR,N1Tmp) = (Qubit[bitsize],Qubit[bitsize*2 + 1],Qubit[bitsize],Qubit[bitsize],Qubit[bitsize],Qubit[bitsize],Qubit[bitsize])){
      
      //Selection of x
      //|N>|0>|0>|0>|0>|0>|0>|0>|0> -> |N>|x>|0>|0>|0>|0>|0>|0>|0>
      let RanNum = RandomInt(PowI(2,bitsize) - 2);
      GenerateX(N,x,RanNum);


      //Square and multiply Modular exponenentiation
      //|N>|x>|0>|0>|0>|0>|0>|0> -> |N>|x>|j>|x^j mod N>|0>|0>|0>|0>
      ApplyToEachA(H,J);
      SquareAndMultiply(x,N,J,SMRes,false);

      //Inverse Quantum Fourier Transform
      Adjoint QFT(BigEndian(J));

      //Continued Fractions
      //|N>|x>|theta>|x^j mod N>|0>|0>|0>|0> -> |N>|x>|theta>|x^j mod N>|Order>|0>|0>|0>
      CFMain(Order,N,J,false);

      
      //Caclulation of x^(r/2)-1
      //Removing first qubit of Order does the halving operation
      //|N>|x>|theta>|x^j mod N>|Order>|0>|0>|0> -> |N>|x>|theta>|x^j mod N>|Order>|x^(Order/2)-1>|0>|0>
      SquareAndMultiply(x,N,Order[1..(Length(Order)-1)],xR2,false);
      IncrementByInteger(-1,LittleEndian(Order[xR2]));
      
      //Greatest Common Divisor
      //|N>|x>|theta>|x^j mod N>|Order>|x^(Order/2)-1>|0>|0> -> |N>|x>|theta>|x^j mod N>|Order>|x^(Order/2)-1>|N1>|0>
      GCDMain(N1Tmp,N,xR2,false);

      //Adding to result Register
      //|N>|x>|theta>|x^j mod N>|Order>|x^(Order/2)-1>|N1>|0> -> |N>|x>|theta>|x^j mod N>|Order>|x^(Order/2)-1>|N1>|N1>
      AddI(LittleEndian(N1Tmp),LittleEndian(N1));

      //Inverse Greatest Common Divisor
      //|N>|x>|theta>|x^j mod N>|Order>|x^(Order/2)-1>|N1>|N1> -> |N>|x>|theta>|x^j mod N>|Order>|x^(Order/2)-1>|0>|N1>
      GCDMain(N1Tmp,N,xR2,true);

      //Inverse Caclulation of x^(r/2)-1
      //Removing first qubit of Order does the halving operation
      //|N>|x>|theta>|x^j mod N>|Order>|x^(Order/2)-1>|0>|N1> -> |N>|x>|theta>|x^j mod N>|Order>|0>|0>|N1> 
      IncrementByInteger(1,LittleEndian(Order[xR2]));
      SquareAndMultiply(x,N,Order[1..(Length(Order)-1)],xR2,true);
      
      //Inverse Continued Fractions
      //|N>|x>|theta>|x^j mod N>|Order>|0>|0>|N1> -> |N>|x>|theta>|x^j mod N>|0>|0>|0>|N1>
      CFMain(Order,N,J,false);

      //Quantum Fourier Transform
      QFT(BigEndian(J));

      //Square and multiply Modular exponenentiation
      //|N>|x>|j>|x^j mod N>|0>|0>|0>|N1> -> |N>|x>|0>|0>|0>|0>|0>|N1>
      SquareAndMultiply(x,N,J,SMRes,true);
      ApplyToEachA(H,J);

      //Selection of x
      //|N>|x>|0>|0>|0>|0>|0>|0>|N1> -> |N>|0>|0>|0>|0>|0>|0>|0>|N1>
      Adjoint GenerateX(N,x,RanNum);
      }

    //Finally we are just left with |N>|N1>
    }
}
