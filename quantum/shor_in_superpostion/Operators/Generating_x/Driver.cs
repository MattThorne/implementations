﻿using System;
using System.Linq;
using System.Numerics;
using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace SignedMultiply.Testing {
    class Driver
    {
        static void Main(string[] args)
        {
            //////////////////THE FULL STATE SIMULATOR//////////////////////////////
            //Use the following code to use the full state simulator to test the  //
            //generation of x operator.                                           //
            // the modular m is put into an even superposition                    //
            ////////////////////////////////////////////////////////////////////////
            // using (var qsim = new QuantumSimulator())
            // {
            //     var res = Testing_in_Superposition.Run(qsim,21,5).Result;
            // }

            //////////////////THE TOFFOLI SIMULATOR/////////////////////////////////
            //Use the following code to iterativly check individual inputs to     //
            //the generation of x operator.                                       //
            //Vary m and R                                                        //
            ////////////////////////////////////////////////////////////////////////
            BigInteger m = new BigInteger(12);
            BigInteger R = new BigInteger(14);
            for (int i=0;i<100;i++){
            TestwithToffoli(R+i,m);
            }

            /////////////////////////////////RESOURCE ESTIMATOR////////////////////////////////////
            //Unomment below code to test the resources used by the GENERATION OF X operator     //
            //Set the desired register bit size by varying m                                     //
            //Set the random integer R by varying R                                              //
            ///////////////////////////////////////////////////////////////////////////////////////
            // ResourcesEstimator estimator = new ResourcesEstimator();
            // int m = 5;
            // int R = 13;
            // Testing_in_Superposition.Run(estimator,R,m).Wait();
            // Console.WriteLine(estimator.ToTSV());
        
        }
            
        

public static int Size(BigInteger bits) {
  int size = 0;

  for (; bits != 0; bits >>= 1)
    size++;

  return size;
    }
// public static void TestwithToffoli(BigInteger R,BigInteger m){
//     BigInteger mCls = m;
//     var sim = new ToffoliSimulator();
//     int [] requiredBits = {Size(BigInteger.Abs(m)),Size(BigInteger.Abs(R))};
//     int numBits = requiredBits.Max();
//     if (numBits == 0){numBits += 1;}
//     Console.WriteLine(numBits);

//     var res = Testing_with_Toffoli.Run(sim,m,numBits,R).Result;
//     Console.WriteLine("Quantum Result: 1 + {0} mod({1}-1) = {2}",R,m,res);
//     Console.WriteLine("Classical Result: 1 + {0} mod({1}-1) = {2}",R,m,(1+ (R % (m-1))));

// }
}
}