﻿using System;
using System.Linq;
using System.Numerics;
using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace ModularMultiplication.Testing
{
    class Driver
    {
        static void Main(string[] args)
        {
            // The full state Simulator
            using (var qsim = new QuantumSimulator())
            {
                var res = Testing_in_Superposition.Run(qsim).Result;
            }

            // The Toffoli Simulator
            
            // BigInteger a = new BigInteger(1234123);
            // BigInteger b = new BigInteger(1234213);
            // BigInteger m = new BigInteger(6434324);
            // for (int i=0;i<100;i++){
            // TestwithToffoli(a+i,b,m);
            // }
            
        }

public static int Size(BigInteger bits) {
  int size = 0;

  for (; bits != 0; bits >>= 1)
    size++;

  return size;
    }
// public static void TestwithToffoli(BigInteger a,BigInteger b, BigInteger m){
//     var sim = new ToffoliSimulator();
//     int [] requiredBits = {Size(a),Size(b),Size(m)};
//     int numBits = requiredBits.Max();
//     if (numBits == 0){numBits += 1;}
//     Console.WriteLine(numBits);
//     var res = Testing_with_Toffoli.Run(sim,a,b,m,numBits).Result;
//     Console.WriteLine("Quantum Result: {0}*{1} mod({2})= {3}",a,b,m,res);
//     Console.WriteLine("Classical Result: {0}*{1} mod({2})= {3}",a,b,m,((a*b) % m));

// }
}
}