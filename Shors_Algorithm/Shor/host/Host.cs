using System;
using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;
using Microsoft.Quantum.Simulation.Simulators;

namespace Shor{
    class Program{
        static void Main(string[] args){
            
            int N,a,b;
            N = 15;
            (a,b) = Shor(N);
            Console.WriteLine(N + " Factors to "+ a + " and "+ b);
        }


        static (int,int) Shor(int N){
            if (N%2 == 0) { return (2,N/2);}
            int a,b;
            a = IsPrimePower(N);
            if (a != 0) {return (a,N/a);}
           
            
            using (var qsim = new QuantumSimulator()){
                (long factor1,long factor2) = FactorInteger.Run(qsim, N).Result;
                a = (int)factor1;
                b = (int)factor2;
            }
            return (a,b);
        }
        static int IsPrimePower(int N){
            ////Getting bitsize of N//////
            int bitsizeN = 0;
            int n = N;
            while (n>0){
                bitsizeN += 1;
                n>>=1;
            }
            /////Setting bs////////
            int[] bs = new int[bitsizeN-1];
            for (int i=0; i<bs.Length; i++){
                bs[i] = i+2;
            }
            Double[] u1 = new Double[bitsizeN-1];
            Double[] u2 = new Double[bitsizeN-1];
            for (int i=0; i<bs.Length; i++){
                u1[i] = (double)bitsizeN/bs[i];
                u1[i] = (int)(Math.Pow(2,u1[i]));
                u2[i] = u1[i] + 1 ;
                if (Math.Pow(u1[i],bs[i])==N){
                    Console.WriteLine(N + " is a prime power of " +(int)u1[i]);
                    return (int)u1[i];
                }
                if (Math.Pow(u2[i],bs[i])==N){
                    Console.WriteLine(N + " is a prime power of " +(int)u2[i]);
                    return (int)u1[i];
                }
            }
            return 0;
        }
    }
}