﻿using System;
using System.Linq;
using System.Numerics;
using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace SignedSubtract.Testing
{
    class Driver
    {
        static void Main(string[] args)
        {
            // The full state Simulator
            // using (var qsim = new QuantumSimulator())
            // {
            //     var res = Testing_in_Superposition.Run(qsim).Result;
            // }

            // The Toffoli Simulator
            
            BigInteger a = new BigInteger(-15);
            BigInteger b = new BigInteger(3);
            for (int i=0;i<101;i++){
            TestwithToffoli(a+i,b);
            }
        }
            
        

public static int Size(BigInteger bits) {
  int size = 0;

  for (; bits != 0; bits >>= 1)
    size++;

  return size;
    }
public static void TestwithToffoli(BigInteger a,BigInteger b){
    BigInteger aCls = a;
    BigInteger bCls = b;
    var sim = new ToffoliSimulator();
    int [] requiredBits = {Size(BigInteger.Abs(a)),Size(BigInteger.Abs(b))};
    int numBits = requiredBits.Max();
    if (numBits == 0){numBits += 1;}
    Console.WriteLine(numBits);

    int aS = 0;
    if (a<0){aS += 1;a = a*-1;}
    int bS = 0;
    if (b<0){bS += 1;b = b*-1;}


    var res = Testing_with_Toffoli.Run(sim,a,aS,b,bS,numBits).Result;
    Console.WriteLine("Quantum Result: {0}-{1}= {2}",aCls,bCls,res);
    Console.WriteLine("Classical Result: {0}-{1} = {2}",aCls,bCls,((aCls-bCls)));

}
}
}