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
           
            //////////////////THE TOFFOLI SIMULATOR/////////////////////////////////
            //Use the following code to iterativly check individual inputs to     //
            //the Square and multiply operator                                    //
            //Vary a, j and m                                                     //
            ////////////////////////////////////////////////////////////////////////
            for (int i = 0;i<101;i++){
            BigInteger a = new BigInteger(1234);
            BigInteger j = new BigInteger(42435);
            BigInteger m = new BigInteger(53245+i);
            TestwithToffoli(a,j,m);
            }
  

            /////////////////////////////////RESOURCE ESTIMATOR//////////////////////////////////////
            //Unomment below code to test the resources used by the Square and multiply operator   //
            //You can vary the bitsize of the inputs                                               //
            /////////////////////////////////////////////////////////////////////////////////////////
            // ResourcesEstimator estimator = new ResourcesEstimator();
            // int bitSize = 5;
            // Testing_in_Superposition.Run(estimator,bitSize).Wait();
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