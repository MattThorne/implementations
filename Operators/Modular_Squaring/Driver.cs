﻿using System;
using System.Linq;
using System.Numerics;
using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace ModularSquaring.Testing
{
    class Driver
    {
        static void Main(string[] args)
        {
            //////////////////THE FULL STATE SIMULATOR//////////////////////////////
            //Use the following code to use the full state simulator to test the  //
            //modular squaring operator.                                          //
            // the modular m is put into an even superposition                    //
            ////////////////////////////////////////////////////////////////////////
            // using (var qsim = new QuantumSimulator())
            // {
            //     var res = Testing_in_Superposition.Run(qsim).Result;
            // }

            //////////////////THE TOFFOLI SIMULATOR/////////////////////////////////
            //Use the following code to iterativly check individual inputs to     //
            //the Modular squaring operator                                 //
            //Vary a, b and m                                                     //
            ////////////////////////////////////////////////////////////////////////
            BigInteger a = new BigInteger(95361);
            BigInteger m = new BigInteger(93456);
            TestwithToffoli(a,m);

            /////////////////////////////////RESOURCE ESTIMATOR//////////////////////////////////////
            //Unomment below code to test the resources used by the modular multiplication operator//
            //Set the desired register bit size by varying m                                       //
            //Set the random integer R by varying R                                                //
            /////////////////////////////////////////////////////////////////////////////////////////
            // ResourcesEstimator estimator = new ResourcesEstimator();
            // int RegisterSize = 4; 
            // Testing_in_Superposition.Run(estimator,RegisterSize).Wait();
            // Console.WriteLine(estimator.ToTSV());
            
        }

public static int Size(BigInteger bits) {
  int size = 0;

  for (; bits != 0; bits >>= 1)
    size++;

  return size;
    }
public static void TestwithToffoli(BigInteger a, BigInteger m){
    var sim = new ToffoliSimulator();
    int [] requiredBits = {Size(a),Size(m)};
    int numBits = requiredBits.Max();
    Console.WriteLine(numBits);
    var res = Testing_with_Toffoli.Run(sim,a,m,numBits).Result;
    Console.WriteLine("Quantum Result: {0}^2 mod({1})= {2}",a,m,res);
    Console.WriteLine("Classical Result: {0}^2 mod({1})= {2}",a,m,((a*a) % m));
    
    double count = 0;
    for (int i = 1; i < 10; i++){
        Console.WriteLine(Math.Pow(2,2*i));
     count +=  Math.Pow(2,2*i);
    }
    Console.WriteLine(count);
}
}
}