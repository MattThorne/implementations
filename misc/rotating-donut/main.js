var canvas = document.querySelector('canvas');
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

var ctx = canvas.getContext('2d');
ctx.fon
ctx.font = "20px Georgia";
ctx.fillStyle = "white";
var radius = 25;
var centerX = 600;
var centerY = 500;
var centerZ = 100;
var zprime = 400;
var lightSource = [1,-1,0]
var magLightSource = Math.sqrt(lightSource[0]**2 + lightSource[1]**2 + lightSource[2]**2);
var autoRotate = false;
var pointStyle = true;

function toggleRotationControl() {
    autoRotate = !autoRotate;
}
function togglePointStyle() {
    pointStyle = !pointStyle;
}

var Cords;
var active = false;
var startX;
var endX;
var startY;
var endY;
var dx;
var dy;
var shiftActive = false;
var a = 0;
var b = 0;
var c = 0;


document,addEventListener("mousedown", function(event) {
    startX = event.clientX;
    startY = event.clientY;
    active = true;
},false);
document.addEventListener("mousemove", function( event ) {
    endX = event.clientX;
    endY = event.clientY;

    dx = endX - startX;
    dy = endY - startY;

    if (active == true && shiftActive == false) {
    centerX += dx;
    centerY += dy;
    }
    if(active == true && shiftActive == true && autoRotate == false){
        b += -dx;
        c += dy;
    }



    startX = endX;
    startY = endY;

}, false);
document.addEventListener("mouseup", function(event){
    active = false
},false);


document.addEventListener('keydown', function (event) {
    // CTRL
    if (event.shiftKey) {
      shiftActive = true;
    }
  });
  document.addEventListener('keyup', function (event) {
    // CTRL
    
    if (event.shiftKey == false) {
      shiftActive = false;
    }
  });








//creating zbuffer
var zbuffer = new Array(canvas.width);
for (i=0;i<zbuffer.length;i++){
    zbuffer[i] = new Array(canvas.height).fill(0);
}



ctx.fillText('@', centerX, centerY);


function circleCoords(radius, theta) {
    var x = (Math.cos(theta)*radius);
    var y = (Math.sin(theta)*radius);
    var z = 0;
    return[x,y,z];     
}
function cylinderCoords(radius,theta,z){
    var x = (Math.cos(theta)*radius);
    var y = (Math.sin(theta)*radius);
    var z = z;
    return[x,y,z,x,y,z];  

}


function rotateCoords(Cords,a,b,c){
    var x = Cords[0];
    var y = Cords[1];
    var z = Cords[2];
    xn = x*(Math.cos(a)*Math.cos(b))+y*(Math.cos(a)*Math.sin(b)*Math.sin(c)-Math.sin(a)*Math.cos(c))+ z*(Math.cos(a)*Math.sin(b)*Math.cos(c)+Math.sin(a)*Math.sin(c));
    yn = x*(Math.sin(a)*Math.cos(b))+y*(Math.sin(a)*Math.sin(b)*Math.sin(c)+Math.cos(a)*Math.cos(c))+ z*(Math.sin(a)*Math.sin(b)*Math.cos(c)- Math.cos(a)*Math.sin(c));
    zn = x*(-Math.sin(b)) + y*(Math.cos(b)*Math.sin(c)) + z*(Math.cos(b)*Math.cos(c));

    var normX = Cords[3];
    var normY = Cords[4];
    var normZ = Cords[5];
    normXn = x*(Math.cos(a)*Math.cos(b))+y*(Math.cos(a)*Math.sin(b)*Math.sin(c)-Math.sin(a)*Math.cos(c))+ z*(Math.cos(a)*Math.sin(b)*Math.cos(c)+Math.sin(a)*Math.sin(c));
    normYn = x*(Math.sin(a)*Math.cos(b))+y*(Math.sin(a)*Math.sin(b)*Math.sin(c)+Math.cos(a)*Math.cos(c))+ z*(Math.sin(a)*Math.sin(b)*Math.cos(c)- Math.cos(a)*Math.sin(c));
    normZn = x*(-Math.sin(b)) + y*(Math.cos(b)*Math.sin(c)) + z*(Math.cos(b)*Math.cos(c));

    return[xn,yn,zn,normXn,normYn,normZn];
}

function projectionCoords(Cords){
    var x = Cords[0];
    var y = Cords[1];
    var z = Cords[2];
    z += centerZ;
    x = x*(zprime/z);
    y = y*(zprime/z);
    x += centerX;
    y += centerY;
    
    return [x,y,z,Cords[3],Cords[4],Cords[5]]

}
//".,-~:;=!*#$@"
function luminenceCalc(NormCords){
    var dotProduct = NormCords[0]*lightSource[0] + NormCords[1]*lightSource[1] + NormCords[2]*lightSource[2];
    var magNorm = Math.sqrt(NormCords[0]**2 + NormCords[1]**2 + NormCords[2]**2);
    var lumination = dotProduct/(magNorm * magLightSource);
    if (lumination > 0.82){return '@'}
    else if(lumination > 0.64 && lumination < 0.82){return '$'}
    else if(lumination > 0.46 && lumination < 0.64){return '#'}
    else if(lumination > 0.28 && lumination < 0.46){return '*'}
    else if(lumination > 0.1 && lumination < 0.28){return '!'}
    else if(lumination > -0.08 && lumination < 0.1){return '='}
    else if(lumination > -0.26 && lumination < -0.08){return ';'}
    else if(lumination > -0.42 && lumination < -0.26){return ':'}
    else if(lumination > -0.6 && lumination < -0.42){return '~'}
    else if(lumination > -0.78 && lumination < -0.6){return '-'}
    else if (lumination >-0.5 && lumination < -0.78){return ','}
    else{return '.'}

    return 

}

function resetZBuffer(){
    for (i=0;i<zbuffer.length;i++){
        for (j=0;j<zbuffer[i].length;j++){
            zbuffer[i][j] = 0;
        }
    }
}



function animate() {

    ///for (i=0;i<1000;i++){
    if (autoRotate == true) {
    a += 0;
    b += 0;
    c += 1;
    }else{
        a += 0;
        b += 0;
        c += 0;
    }
    var aRad = a * Math.PI / 180;
    var bRad = b * Math.PI / 180;
    var cRad = c * Math.PI / 180;
    
    ctx.clearRect(0,0,innerWidth,innerHeight)
    //ctx.fillText('@', centerX, centerY);
    resetZBuffer();
    for (theta=0;theta<360;theta=theta+3){
        for (z=-20;z<30;z+= 5){
        thetaRad = theta * Math.PI / 180;
        //var Cords = circleCoords(radius, thetaRad);
        Cords = cylinderCoords(radius,thetaRad,z);
        Cords = rotateCoords(Cords,aRad,bRad,cRad);
        Cords = projectionCoords(Cords);
        Cords = [Math.round(Cords[0]),Math.round(Cords[1]),Math.round(Cords[2]),Cords[3],Cords[4],Cords[5]]
        try{
        if (1/Cords[2] > zbuffer[Cords[0]][Cords[1]]){
            zbuffer[Cords[0]][Cords[1]] = 1/Cords[2];
            if (pointStyle == true){
                var luminationSymbol = luminenceCalc([Cords[3],Cords[4],Cords[5]]);
                ctx.fillText(luminationSymbol, Cords[0], Cords[1]);
            }else{ctx.fillText('.', Cords[0], Cords[1]);}
            }
        }catch(err){console.log(err.message);}
    }   
    }
    
    //sleep(50);
    //}
    requestAnimationFrame(animate); 
}
animate();




function sleep(milliseconds) {
    var start = new Date().getTime();
    for (var i = 0; i < 1e7; i++) {
      if ((new Date().getTime() - start) > milliseconds){
        break;
      }
    }
  }



