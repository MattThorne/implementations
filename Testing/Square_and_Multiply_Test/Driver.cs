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
           
            // // The Toffoli Simulator
            // //for (int i = 0;i<101;i++){
            // BigInteger a = new BigInteger(2223612333);
            // BigInteger j = new BigInteger(1012312341);
            // BigInteger m = new BigInteger(5412312333);
            // TestwithToffoli(a,j,m);
            // //}


            //THE RESOURCE ESTIMATOR
            ResourcesEstimator estimator = new ResourcesEstimator();
            Testing_in_Superposition.Run(estimator,10).Wait();
            Console.WriteLine(estimator.ToTSV());

            // ResourcesEstimator estimator = new ResourcesEstimator();
            // analysis.Run(estimator,8).Wait();
            // Console.WriteLine(estimator.ToTSV());


            
            
        }

public static int Size(BigInteger bits) {
  int size = 0;

  for (; bits != 0; bits >>= 1)
    size++;

  return size;
    }
public static void TestwithToffoli(BigInteger a,BigInteger j, BigInteger m){
    var sim = new ToffoliSimulator();
    int [] requiredBits = {Size(a),Size(j),Size(m)};
    int numBits = requiredBits.Max();
    if (numBits == 0){numBits += 1;}
    Console.WriteLine(numBits);
    var res = Testing_with_Toffoli.Run(sim,a,j,m,numBits).Result;
    Console.WriteLine("Quantum Result: {0}^{1} mod({2})= {3}",a,j,m,res);
    Console.WriteLine("Classical Result: {0}^{1} mod({2})= {3}",a,j,m,(exponentiation(a,j,m)));

}


static BigInteger exponentiation(BigInteger bas, BigInteger exp, BigInteger N) 
    { 
        if (exp == 0) 
            return 1; 
  
        if (exp == 1) 
            return bas % N; 
  
        BigInteger t = exponentiation(bas, exp / 2, N); 
        t = (t * t) % N; 
  
        // if exponent is even value 
        if (exp % 2 == 0) 
            return t; 
  
        // if exponent is odd value 
        else
            return ((bas % N) * t) % N; 
    } 
}
}