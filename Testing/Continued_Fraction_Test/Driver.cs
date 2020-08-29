﻿using System;

using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace Quantum.Bell
{
    class Driver
    {
        static void Main(string[] args)
        {
            
            // ResourcesEstimator estimator = new ResourcesEstimator();
            // TestD.Run(estimator).Wait();
            // Console.WriteLine(estimator.ToTSV());

             var sim = new ToffoliSimulator();
             
             
             for (int i=0;i<101;i++){
             int n = 512;
             int lim = 400;
             int bitSize = 11+i;
             var (Quantum,Classical) = CFCControl.Run(sim,n,lim,bitSize).Result;
             Console.WriteLine("{0}",bitSize);
             Console.WriteLine("CF Convergent of {0}/{1} with limit {2}",n,(Math.Pow(2,bitSize)),lim);
             Console.WriteLine("Quantum Result: {0}",Quantum);
             Console.WriteLine("Classical Result: {0}",Classical);
             }
        }
    }
}