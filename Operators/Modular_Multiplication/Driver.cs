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
            //////////////////THE FULL STATE SIMULATOR//////////////////////////////
            //Use the following code to use the full state simulator to test the  //
            //modular multiplication operator.                                    //
            // the modular m is put into an even superposition                    //
            //////////////////////////////////////////////////////////////////////// 
            // using (var qsim = new QuantumSimulator())
            // {
            //     int RegisterSize = 4;      
            //     var res = Testing_in_Superposition.Run(qsim,RegisterSize).Result;
            // }

            //////////////////THE TOFFOLI SIMULATOR/////////////////////////////////
            //Use the following code to iterativly check individual inputs to     //
            //the Modular multiplication operator                                 //
            //Vary a, b and m                                                     //
            ////////////////////////////////////////////////////////////////////////
            BigInteger a = new BigInteger(1234123);
            BigInteger b = new BigInteger(1234213);
            BigInteger m = new BigInteger(6434324);
            for (int i=0;i<100;i++){
            TestwithToffoli(a+i,b,m);
            }

            
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
public static void TestwithToffoli(BigInteger a,BigInteger b, BigInteger m){
    var sim = new ToffoliSimulator();
    int [] requiredBits = {Size(a),Size(b),Size(m)};
    int numBits = requiredBits.Max();
    if (numBits == 0){numBits += 1;}
    Console.WriteLine(numBits);
    var res = Testing_with_Toffoli.Run(sim,a,b,m,numBits).Result;
    Console.WriteLine("Quantum Result: {0}*{1} mod({2})= {3}",a,b,m,res);
    Console.WriteLine("Classical Result: {0}*{1} mod({2})= {3}",a,b,m,((a*b) % m));

}
}
}