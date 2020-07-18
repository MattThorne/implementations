namespace Shor {
  open Microsoft.Quantum.Intrinsic;
  open Microsoft.Quantum.Arithmetic;
  open Microsoft.Quantum.Diagnostics;
  open Microsoft.Quantum.Measurement;
  open Microsoft.Quantum.Math;
  open Microsoft.Quantum.Arrays;
  open Microsoft.Quantum.Convert;
  open Microsoft.Quantum.Canon;

  operation FactorInteger(N : Int) : (Int,Int){
    //Pick random integer between 1 and N-1
    //let x = RandomInt(N - 2) + 1;
    let x = 7;
    Message($"checking {x}");
    //Check that the gcd(N,x) = 1, else we have found a factor by chance
    let gcd = GreatestCommonDivisorI(N, x);
    if (gcd > 1){return (gcd, N/gcd);}

    //Now have N and x, which are coprime

    //Calculating the number of bits required
    let numBits = BitSizeI(N);
    let estimateBitPrecision = 2*numBits + 1;
    Message($"Need {numBits} qubits for register 1");
    mutable result = 0;
    mutable period = 0;

    repeat{
      Message("============");
    using ((q1,q2) = (Qubit[estimateBitPrecision],Qubit[numBits])){
      //|0>|0>//
      ApplyToEachA(H,q1);//|0> -> |y>
      //|y>|0>//
      X(q2[0]);//|0> -> |1>
      //|y>|1>//

      for (i in 0..(Length(q1)-1)){ //|1> ->|x^y modN>
        mutable x_modN = 1;
        for (pow in 0..(2^((Length(q1)-1)-i))){
          set x_modN = (x_modN * x) % N;
        }//x^2^j modN

        Controlled MultiplyByModularInteger([q1[i]],(x_modN,N,LittleEndian(q2)));
      }

      //|y>|x^y modN> //
      Adjoint QFT(BigEndian(q1));

      set result = MeasureInteger(LittleEndian(q1));
      ResetAll(q1);
      ResetAll(q2);
    }

      Message($"The result is {result}");
      let gcdResult = GreatestCommonDivisorI(result,2^numBits);
      let numerator = result/gcdResult;
      let denominator = 2^numBits / gcdResult;
      //  s/r //
      Message($"s/r = {numerator}/{denominator}");
      let aFraction = ContinuedFractionConvergentL(BigFraction(IntAsBigInt(numerator), IntAsBigInt(denominator)), IntAsBigInt(N));
      let (aNumerator, aDenominator) = aFraction!;
      let periodL = AbsL(aDenominator);
      set period = ReduceBigIntToInt(periodL);

    }
    until((period != 0) and (ExpModI(x, period, N) == 1) and (period % 2 == 0));

    let halfPower = ExpModI(x,period / 2, N);
    if (halfPower != -1){
      let factor = MaxI(
                GreatestCommonDivisorI(halfPower - 1, N), 
                GreatestCommonDivisorI(halfPower + 1, N)
            );

            return (factor, N / factor);
    }
      
    return (0,0);
  }


}