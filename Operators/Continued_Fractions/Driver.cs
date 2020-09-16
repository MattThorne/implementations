﻿using System;

using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace ContinuedFractions
{
    class Driver 
    {
        static void Main(string[] args)
        {
            
            /////////////////////////////////RESOURCE ESTIMATOR////////////////////////////////////
            //Unomment below code to test the resources used by the continued Fractions operator //
            //Set the desired register bit size by varying the registerBitSize variable.         //
            ///////////////////////////////////////////////////////////////////////////////////////
            // ResourcesEstimator estimator = new ResourcesEstimator();
            // int registerBitSize = 8;
            // Testing_in_Superposition.Run(estimator,registerBitSize).Wait();
            // Console.WriteLine(estimator.ToTSV());



            //////////////////THE TOFFOLI SIMULATOR/////////////////////////////////
            //Use the following code to iterativly check individual inputs to     //
            //the Continued fractions operator.                                   //
            //For Shor's algorithm in superposition the denominator is 2^(bitSize)//
            //Vary n and limit to test different numertors and limits             //
            ////////////////////////////////////////////////////////////////////////

            var sim = new ToffoliSimulator();
            for (int i=0;i<101;i++){
            int n = 300 + i;
            int limit = 40;
            int bitSize = 10;
            var (Quantum,Classical) = Testing_with_Toffoli.Run(sim,n,limit,17,bitSize,true).Result;
            Console.WriteLine("{0}",bitSize);
            Console.WriteLine("CF Convergent of {0}/{1} with limit {2}",n,(Math.Pow(2,bitSize)),limit);
            Console.WriteLine("Quantum Result: {0}",Quantum);
            Console.WriteLine("Classical Result: {0}",Classical);
            }
        }
    }
}