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
    open Microsoft.Quantum.Measurement;
    newtype SignedLittleEndian = LittleEndian;


operation checkSS() : Unit{
    mutable result = 1;
    for (aS in 0..1){
        for (bS in 0..1){
            for (an in 0..15){
                for (bn in 0..15){
                    mutable aSB = false;
                    mutable bSB = false;
                    mutable aRN = an;
                    mutable bRN = bn;
                    mutable ResSig = false;
                    mutable mesR = 0;
                    if (aS == 1){set aSB = true;}
                    if (bS == 1){set bSB = true;}

                    set (mesR,ResSig) = SignedSubtract(an,bn,aSB,bSB);

                    if (ResSig == true){set mesR = mesR * -1;}

                    if (aSB == true){set aRN = aRN * -1;}
                    if (bSB == true){set bRN = bRN * -1;}
                    let RR = (aRN - bRN);

                    if (RR != mesR){set result = 0;}
                    Message($"{aRN},{bRN},{mesR}");
                    Message($"{result}");
                

                }
            }  
        }
    }
}
//test and Check this works properly////////////////
operation SignedSubtract(ai:Int,bi:Int, aS:Bool,bS:Bool):(Int,Bool){
    let aarr = IntAsBoolArray(ai,4);
    let barr = IntAsBoolArray(bi,4);
//|a>|b> =>  |a-b>|b>
using ((a,b,anc,anc2)=(Qubit[6],Qubit[5],Qubit(),Qubit())){
    EqualityFactI(Length(a) , Length(b) + 1, "Signed Subtraction, a must have one more quibt than b");
    
    for (i in 0..(Length(aarr)-1)){
        if (aarr[i] == true){
            X(a[i]);
        }
        if (barr[i] == true){
            X(b[i]);
        }
    }
    if (aS == true){X(a[Length(a)-1]);}
    if (bS == true){X(b[Length(b)-1]);}

   

    CNOT(a[Length(a)-1],anc2);
    CNOT(b[Length(b)-1],anc2);
    X(anc2);
    
    
    Controlled CompareGTI([anc2],(LittleEndian(b[0..(Length(b)-2)]),LittleEndian(a[0..(Length(a)-3)]),anc));
    for (i in 0..(Length(a)-3)){
        Controlled SWAP([anc,anc2],(a[i],b[i]));
    }
    Controlled Adjoint AddI([anc2],(LittleEndian(b[0..(Length(b)-2)]),LittleEndian(a[0..(Length(a)-3)])));
    Controlled X([anc,anc2],a[Length(a)-1]);


    X(anc2);
    Controlled AddI([anc2],(LittleEndian(b[0..(Length(b)-2)]),LittleEndian(a[0..(Length(a)-2)])));
    X(anc2);


    let mes = MeasureInteger(LittleEndian(a[0..(Length(a)-2)]));
    let mesSig = M(a[Length(a)-1]);
    let mesSigRes = ResultAsBool(mesSig);
    ResetAll(a+b + [anc,anc2]);
    return(mes,mesSigRes);
    

}


}









    























    operation AddI (xs: LittleEndian, ys: LittleEndian) : Unit is Adj + Ctl {
        if (Length(xs!) == Length(ys!)) {
            RippleCarryAdderNoCarryTTK(xs, ys);
        }
        elif (Length(ys!) > Length(xs!)) {
            using (qs = Qubit[Length(ys!) - Length(xs!) - 1]){
                RippleCarryAdderTTK(LittleEndian(xs! + qs),
                                    LittleEndian(Most(ys!)), Tail(ys!));
            }
        }
        else {
            fail "xs must not contain more qubits than ys!";
        }
    }

   
    operation CompareGTI (xs: LittleEndian, ys: LittleEndian,
                            result: Qubit) : Unit is Adj + Ctl {
        GreaterThan(xs, ys, result);
    }

    





}