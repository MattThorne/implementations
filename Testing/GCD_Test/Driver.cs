﻿using System;
using System.Linq;
using System.Numerics;

using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace Quantum.Bell
{
    class Driver
    {
        static void Main(string[] args)
        {


             var sim = new ToffoliSimulator();
             
             
             for (int i=0;i<100;i++){
             int a = 512;
             int b = 400+i;
             int [] requiredBits = {Size(a),Size(b)};
             int numBits = requiredBits.Max();
    
             var Quantum = TestGCD.Run(sim,a,b,numBits).Result;
             Console.WriteLine("{0}",numBits);
             Console.WriteLine("GCD({0},{1})",a,b);
             Console.WriteLine("Quantum Result: {0}",Quantum);
             Console.WriteLine("Classical Result: {0}",(GCD(a,b)));
             }
        }
public static int Size(int bits) {
  int size = 0;

  for (; bits != 0; bits >>= 1)
    size++;

  return size;
    }

    public static int GCD(int p, int q)
{
    if(q == 0)
    {
         return p;
    }

    int r = p % q;

    return GCD(q, r);
}
    }
}