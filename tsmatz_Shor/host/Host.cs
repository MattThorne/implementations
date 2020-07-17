using System;

using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using Microsoft.Quantum.Simulation.Simulators;

namespace Microsoft.Quantum.Samples.IntegerFactorization
{
    /// <summary>
    /// This is a Console program that runs Shor's algorithm 
    /// on a Quantum Simulator.
    /// </summary>
    class Program
    {
            static void Main(string[] args)
            {

            
            int N, a;
            N = 11;
            a = 5;

            ResourcesEstimator estimator = new ResourcesEstimator();
            QuantumPeriodFinding.Run(estimator, N, a).Wait();
            Console.WriteLine(estimator.ToTSV());
            
            /*
            // For Period Finding Only
            using (var qsim = new QuantumSimulator())
            {
                int N, a;

                // answer should be 5
                N = 15;
                a = 7;
                QuantumPeriodFinding.Run(qsim, N, a).Wait();

                // answer should be 4
                N = 15;
                a = 7;
                QuantumPeriodFinding.Run(qsim, N, a).Wait();
            }*/


            }
    }
}