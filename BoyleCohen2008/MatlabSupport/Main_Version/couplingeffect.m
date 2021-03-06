function [meandiff,peakdiff] = couplingeffect(freq,lag)

%importing data
data = importdata('data/input.csv'); %Not sure if these are the best paramaters...

% Model paramaters

Cmem = 30e-12;
gKS = data(2)*Cmem;
gKF = data(3)*Cmem;
gCa = data(4)*Cmem;
gL = data(5)*Cmem;
VKS = data(6);
VKF = data(7);
VCa = data(8);
VL = 10e-3;
Vhalf_n = data(10);
Vhalf_p = data(11);
Vhalf_q = data(12);
Vhalf_e = data(13);
Vhalf_f = data(14);
Cahalf_h = data(15)*1e-9;
k_n = data(16);
k_p = data(17);
k_q = data(18);
k_e = data(19);
k_f = data(20);
k_h = data(21)*1e-9;
T_n = data(22);
T_p = data(23);
T_q = data(24);
T_e = data(25);
T_f = data(26);
T_Ca = data(27);
alphaCa = data(28);

thiCa = 6.1e-6/(T_Ca*gCa);
ICa_max = 6.721*Cmem;


%connectivity paramaters
g_ji = [0 370e-12];               %********************       Gj    GJ     GJ    *********************



%Simulation Paramaters
deltat = 0.01e-3;
duration = 2/freq;                %*********************      Duration    Duration   ***************
numpoints = round(duration/deltat);
numcells = 5;   
xaxis = (deltat:deltat:duration)*1e3;

for z = 1:2

%Variable Declaration
I_in = zeros(numcells,numpoints);
I_j = zeros(numcells+1,1);
V = zeros(numcells,numpoints);
Ca = zeros(numcells,numpoints);
n = zeros(numcells,1);
p = zeros(numcells,1);
q = zeros(numcells,1);
e = zeros(numcells,1);
f = zeros(numcells,1);
h = zeros(numcells,1);

%input initialization
A = -250e-12;
omega = 2*pi*freq;
thi = lag;
T_I = 0.25;



for i = 1:numcells
    for j = 2:numpoints
        
        I_in(i,j) = I_in(i,j) + (A/2)*(cos(omega*j*deltat - thi*(i-3) + pi)) + (A/2);  
        
    end
end


%variable initialization
for j = 1:numcells
    V(j,1) = -27.9e-3;
    Ca(j,1) = 0;
    n(j,1) = x_inf(V(j,1),Vhalf_n,k_n);
    p(j,1) = x_inf(V(j,1),Vhalf_p,k_p);
    q(j,1) = x_inf(V(j,1),Vhalf_q,k_q);
    e(j,1) = x_inf(V(j,1),Vhalf_e,k_e);
    f(j,1) = x_inf(V(j,1),Vhalf_f,k_f);
end

%start of simulation
for i = 2:numpoints
    
    for j = 2:numcells
        I_j(j,1) = g_ji(z) * (V(j-1,i-1) - V(j,i-1)) * Gjss(V(j-1,i-1) - V(j,i-1));
    end
    
    for j = 1:numcells
        
        dn = (x_inf(V(j,i-1),Vhalf_n,k_n) - n(j,1))/T_n;
        n(j,1) = n(j,1) + dn*deltat;
        dp = (x_inf(V(j,i-1),Vhalf_p,k_p) - p(j,1))/T_p;
        p(j,1) = p(j,1) + dp*deltat;
        dq = (x_inf(V(j,i-1),Vhalf_q,k_q) - q(j,1))/T_q;
        q(j,1) = q(j,1) + dq*deltat;
        de = (x_inf(V(j,i-1),Vhalf_e,k_e) - e(j,1))/T_e;
        e(j,1) = e(j,1) + de*deltat;
        df = (x_inf(V(j,i-1),Vhalf_f,k_f) - f(j,1))/T_f;
        f(j,1) = f(j,1) + df*deltat;
        h(j,1) = x_inf(Ca(j,i-1),Cahalf_h,k_h);
        
        IKS = gKS*n(j,1)*(V(j,i-1) - VKS);
        IKF = gKF*p(j,1)^4*q(j,1)*(V(j,i-1) - VKF);
        ICa = gCa*e(j,1)^2*f(j,1)*(1 + (h(j,1) - 1)*alphaCa)*(V(j,i-1) - VCa);
        IL = gL*(V(j,i-1) - VL);
        
        dCa = -(Ca(j,i-1)/T_Ca + thiCa*ICa);
        Ca(j,i) = Ca(j,i-1) + dCa*deltat;
        
        dv = -(I_in(j,i) + IKS + IKF + ICa + IL - I_j(j,1) + I_j(j+1,1))/Cmem;
        V(j,i) = V(j,i-1) + dv*deltat;
    end
    
end


if g_ji(z) == 0
    V_uncoupled = V(3,:).*1e3;
    I_uncoupled = I_in(3,:);
else
    V_coupled = V(3,:).*1e3;
    I_coupled = I_in(3,:);
end

end
%subplot(211),plot(xaxis,I_uncoupled,'k',xaxis,I_coupled,'r')
%subplot(212),plot(xaxis,V_uncoupled,'k',xaxis,V_coupled,'r')


%Now calculate mean squared difference

difference = (V_uncoupled - V_coupled);

meandiff = mean(abs(difference));
peakdiff = max(abs(difference));