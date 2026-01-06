using System;
using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;
using Microsoft.Quantum.Simulation.Simulators;

namespace Shor{
    class Program{
        static void Main(string[] args){
            // using (var qsim = new QuantumSimulator()){
            //     FactorInteger.Run(qsim).Wait();

            // }
            var sim = new ToffoliSimulator();
            var res = FactorInteger.Run(sim).Result;
        }  
    }
}