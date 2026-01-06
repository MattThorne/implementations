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
            
            /////////////////////////////////RESOURCE ESTIMATOR////////////////////////////
            //Unomment below code to test the resources used by the GCD operator         //
            //Set the desired register bit size by varying the registerBitSize variable. //
            ///////////////////////////////////////////////////////////////////////////////
            // ResourcesEstimator estimator = new ResourcesEstimator();
            // Testing_in_Superposition.Run(estimator,20).Wait();
            // Console.WriteLine(estimator.ToTSV());



 
            //////////////////THE TOFFOLI SIMULATOR/////////////////////////////////
            //Use the following code to iterativly check individual inputs to     //
            //the GCD  operator.                                                  //
            //Vary a and b to test different values                               //
            ////////////////////////////////////////////////////////////////////////

            var sim = new ToffoliSimulator();
            for (int i=0;i<100;i++){
             int a = 512 + i;
             int b = 400;
             int [] requiredBits = {Size(a),Size(b)};
             int numBits = requiredBits.Max();
    
             var Quantum = TestGCD.Run(sim,a,b,0,numBits,false).Result;
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