﻿using System;

using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace Shor.Testing
{
    class Driver
    {
        static void Main(string[] args)
        {
            
            // using (var qsim = new QuantumSimulator())
            // {

            //     //var res = Test_Operation.Run(qsim, 2, true).Result;
            //     var res = control.Run(qsim).Result;
            //     //var res = BBMGrover.Run(qsim).Result;
            // }

            var sim = new ToffoliSimulator();
            var res = TestingSquareMultiply.Run(sim).Result;
        }
    }
}