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
    using ((Ms,As,Js,Rs,Os,Gs,Ds) = (Qubit[bitsize],Qubit[bitsize],Qubit[bitsize*2],Qubit[bitsize],Qubit[bitsize*2],Qubit[bitsize],Qubit[bitsize])){
        DumpMachine();

        ResetAll((Ms + As + Js + Rs + Os + Gs + Ds));
      }
      
    }
}
