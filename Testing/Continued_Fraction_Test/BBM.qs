namespace Quantum.Bell {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Oracles;
    open Microsoft.Quantum.Characterization;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;


/////////////////////////Grovers Algorithm For BBM/////////////////////
    operation OracleConverter1 (markingOracle : ((Qubit[], Qubit) => Unit is Adj), register : Qubit[]) : Unit is Adj {
        using (target = Qubit()) {
            within {
                // Put the target into the |-⟩ state
                X(target);
                H(target);
            } apply {
                // Apply the marking oracle; since the target is in the |-⟩ state,
                // flipping the target if the register satisfies the oracle condition will apply a -1 factor to the state
                // (phase kickback trick)
                markingOracle(register, target);
            }
        }
    }
    function OracleConverter2 (markingOracle : ((Qubit[], Qubit) => Unit is Adj)) : (Qubit[] => Unit is Adj) {
        return OracleConverter1(markingOracle, _);
    }

    operation ConditionalPhaseFlip_Reference (register : Qubit[]) : Unit is Adj {
        // Define a marking oracle which detects an all zero state
        let allZerosOracle = Oracle_ArbitraryPattern_Reference(_, _, new Bool[Length(register)]);
            
        // Convert it into a phase-flip oracle and apply it
        let flipOracle = OracleConverter2(allZerosOracle);
        flipOracle(register);
    }

    operation Oracle_ArbitraryPattern_Reference (queryRegister : Qubit[], target : Qubit, pattern : Bool[]) : Unit is Adj {        
        (ControlledOnBitString(pattern, X))(queryRegister, target);
    }


operation BBMGrover() : Unit{
    using (qs = Qubit[3]){
        //Set up register in superposition
        ApplyToEachA(H,qs);
        DumpMachine();

        //create oracle
        let DetectSmooth = OracleConverter2(OracleIsSmooth);
        for (i in 1..10){
        //Grover iteration
        DetectSmooth(qs);
        ApplyToEachA(H, qs);
        ConditionalPhaseFlip_Reference(qs);
        ApplyToEachA(H, qs);
        }
        DumpMachine();
        ResetAll(qs);
    }

}




/////////////////////////Oracle For Grovers Algorithm to detect Smooth Numbers/////////////
operation OracleIsSmooth(queryregister : Qubit[], target : Qubit) : Unit is Adj {
    Controlled X(queryregister,target);
    // ApplyToEachA(X,queryregister);
    // Controlled X(queryregister,target);
    // ApplyToEachA(X,queryregister);

}
}