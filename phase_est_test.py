import math

import numpy as np


def SaM(x,e,m):
    X = x
    E = e
    Y = 1
    while E > 0:
        if E % 2 == 0:
            X = (X * X) % m
            E = E/2
        else:
            Y = (X * Y) % m
            E = (E - 1)
        print(Y)
    return Y


def SaM2(x,e,m):
    X = x
    E = e
    Y = 22
    if E % 2 == 0:
        E = E/2
    else:
        E = (E - 1)/2

    
    while E > 0:
        if E % 2 == 0:
            Y = (Y * Y) % m
            E = E/2
        else:
            Y = (X*(Y * Y)) % m
            E = (E - 1)/2
        print(Y)
    return Y


def ContinuedFraction(n,d,m):
    r1 = n
    r2 = d
    s1 = 1
    s2 = 0
    t1 = 0
    t2 = 1
    print('(' + str(r1) + ',' + str(r2) + ')(' + str(s1) + "," + str(s2) + ")(" + str(t1) + "," + str(t2) + ")")
    while (r2!=0) and (abs(s2)<=m) :
        quotient = r1 / r2

        tmp = r2
        r2 = r1 - quotient * r2
        r1 = tmp

        tmp = s2
        s2 = s1- quotient * s2
        s1 = tmp

        tmp = t2
        t2 = t1 - quotient * t2
        t1 = tmp
        
        print('(' + str(r1) + ',' + str(r2) + ')(' + str(s1) + "," + str(s2) + ")(" + str(t1) + "," + str(t2) + ")")       

    if r2 == 0 and abs(s2)<= m:
        print('t2 and s2 returned: ' + str(t2) + "/" + str(s2))
    else:
        print('t1 and s1 returned: ' + str(t1) + "/" + str(s1))
        
def ExtendedGCD(n,m):
    r1 = n
    r2 = m
    s1 = 1
    s2 = 0
    t1 = 0
    t2 = 1
    print('(' + str(r1) + ',' + str(r2) + ')(' + str(s1) + "," + str(s2) + ")(" + str(t1) + "," + str(t2) + ")")
    while (r2!=0):
        quotient = r1 / r2

        tmp = r2
        r2 = r1 - quotient * r2
        r1 = tmp

        tmp = s2
        s2 = s1- quotient * s2
        s1 = tmp

        tmp = t2
        t2 = t1 - quotient * t2
        t1 = tmp
        
        print('(' + str(r1) + ',' + str(r2) + ')(' + str(s1) + "," + str(s2) + ")(" + str(t1) + "," + str(t2) + ")")       

    
    print('t1 and s1 returned: (u,v):(' + str(s1) + "," + str(t1)+")")
    print('GCD is: '+ str(s1*n + t1*m))

def gcd(a, b):
    """Calculate the Greatest Common Divisor of a and b.

    Unless b==0, the result will have the same sign as b (so that when
    b is divided by it, the result comes out positive).
    """
    while b:
        a, b = b, a%b
    return a


def ROG():

    s = 6.0
    i = 4.0
    while i < 1000000:
        s += i
        
        print((-1 + math.sqrt(1+8*i))/2)
        i +=1

        

def pebble(s, n, a):
    
    if (n == 0):
        return
    t = s + 2**(n-1)
    pebble(s,n-1,a)
    #put a free pebble on node t
    #a[t] = t
    calc(t,a,1)
    #print("Pebbling...")
    print(a)
    unpebble(s,n-1,a)
    pebble(t,n-1,a)
    
    
def unpebble(s,n, a):
    
    if (n == 0):
        return
    t = s + 2**(n-1)
    unpebble(t,n-1,a)
    pebble(s,n-1,a)
    #remove the pebble from node t
    #a[t] = 0
    calc(t,a,0)
    #print("Unpebbling...")
    print(a)
    unpebble(s,n-1,a) 

def calc(t,a,d):
    
    new = 0
    curr = 0
    #Find current item
    r = False
    i = 0
    while r == False:
        if a[i] == t-1:
            curr = i
            r = True
        i += 1

    if d == 1:
        
        #Find first empty item
        r = False
        i = 0
        while r == False:
            if a[i] == 0:
                new = i
                r = True
            i += 1
        a[new] = a[new] + (a[curr] + 1)

    if d == 0:
        
        #Find current item + 1
        r = False
        i = 0
        while r == False:
            if a[i] == t:
                new = i
                r = True
            i += 1
        a[new] = a[new] - (a[curr] + 1)
    
        
        
    
    
    
    
                
            
num = 22

numAnc = math.ceil(math.log(17,2))
print(numAnc)

a = np.zeros(int(numAnc + 1))
a[0] = 1
s = 1


pebble(s,numAnc,a)
print("Half Way!")
unpebble(s,numAnc,a)
#unpebble(s,n,a)







